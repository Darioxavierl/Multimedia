# VideoConferencia P2P con FFmpeg

Aplicación de videollamada P2P basada en FFmpeg y FFplay para Ubuntu. Transmite y recibe audio/video mediante UDP, con soporte para múltiples perfiles de calidad según distancia y condiciones de red.

## Requisitos del Sistema

- **OS**: Ubuntu (probado en Ubuntu 20.04+)
- **Python**: 3.7+
- **Dependencias del sistema**:
  ```bash
  sudo apt update
  sudo apt install python3-pyqt6 ffmpeg
  ```

## Instalación Rápida

1. **Clonar repositorio** (en ambos PCs):
   ```bash
   git clone <repo-url>
   cd interciclo
   ```

2. **Crear entorno virtual**:
   ```bash
   python3 -m venv .env
   source .env/bin/activate
   ```

3. **Instalar dependencias Python**:
   ```bash
   pip install -r requierements.txt
   ```

4. **Ejecutar aplicación**:
   ```bash
   python main.py
   ```

## Configuración de Red (Hotspot)

La aplicación utiliza **hotspot WiFi** para comunicación P2P entre dos Ubuntu.

### Opción 1: Configuración Manual

**En el PC Anfitrión (que comparte conexión):**
```bash
# 1. Crear hotspot
sudo nmcli dev wifi hotspot ifname wlan0 ssid "videoconf" password "12345678"

# 2. Verificar IP asignada
nmcli device show wlan0 | grep IP4.ADDRESS
# Ejemplo: 192.168.127.1
```

**En el PC Cliente (que se conecta):**
```bash
# Conectarse al hotspot desde la UI de Ubuntu o:
nmcli dev wifi connect "videoconf" password "12345678"

# Verificar IP asignada
ip addr show wlan0 | grep "inet "
# Ejemplo: 192.168.127.xyz
```

### Opción 2: Configuración Automática (Script)

En el PC Anfitrión:
```bash
sudo ./setup_hotspot.sh wlan0
```

Restaurar después:
```bash
sudo ./restore_hotspot.sh
```

### Configurar Direcciones UDP en la Aplicación

Una vez conectados, actualizar las direcciones en la UI:

**PC Anfitrión (192.168.127.1) - ejemplo:**
- **TX Address**: `udp://192.168.127.xyz:39400` (IP del cliente)
- **RX Address**: `udp://@:39400` (escucha en su puerto)

**PC Cliente (192.168.127.xyz) - ejemplo:**
- **TX Address**: `udp://192.168.127.1:39400` (IP del anfitrión)
- **RX Address**: `udp://@:39400` (escucha en su puerto)

## Uso de la Aplicación

### Interfaz Principal

- **Selector de Perfil**: Elige "cercano", "medio" o "lejano" para cambiar calidad automáticamente
- **Tabs de Configuración**:
  - **Video**: FPS, resolución, dispositivo de entrada, bitrate
  - **Audio**: Canales, dispositivo, codec
  - **Red**: Direcciones TX/RX
- **Botones de Control**:
  - **Start TX**: Inicia transmisión de video/audio
  - **Stop TX**: Detiene transmisión
  - **Start RX**: Abre ventana FFplay para recibir
  - **Stop RX**: Cierra receptor

### Flujo Típico de Prueba

1. **PC Anfitrión**: Conectar hotspot y ejecutar `python main.py`
2. **PC Cliente**: Conectarse al hotspot y ejecutar `python main.py`
3. Verificar IPs con `ip addr show` en ambos
4. En ambas UIs: actualizar **TX Address** con IP del otro PC
5. **PC A**: Click "Start TX" → inicia transmisión
6. **PC B**: Click "Start RX" → abre ventana FFplay con video
7. Probar a distintas distancias usando perfiles diferentes

## Perfiles de Calidad

### Cercano (Alta Calidad - Distancia Corta)
- **Resolución**: 1920×1080
- **FPS**: 30
- **Bitrate Video**: 8000 kbps
- **Bitrate Audio**: 128 kbps
- **Uso**: Mismo cuarto, conexión WiFi fuerte

### Medio (Balanceado - Distancia Moderada)
- **Resolución**: 1280×720
- **FPS**: 25
- **Bitrate Video**: 4000 kbps
- **Bitrate Audio**: 96 kbps
- **Uso**: Cuartos adyacentes, WiFi normal

### Lejano (Baja Latencia - Señal Débil)
- **Resolución**: 854×480
- **FPS**: 15
- **Bitrate Video**: 1500 kbps
- **Bitrate Audio**: 64 kbps
- **Uso**: Distancia mayor, WiFi débil

## Identificar Dispositivos

### Dispositivos de Video (entrada de cámara)
```bash
v4l2-ctl --list-devices
# o
ls -l /dev/video*
```

Usar el primero disponible (ej: `/dev/video0`) en la UI.

### Dispositivos de Audio

**Entrada (micrófono)**:
```bash
arecord -l
# Salida ejemplo:
# **** List of CAPTURE Hardware Devices ****
# card 1: Device [USB Audio Device], device 0
#   Subdevices: 1/1
# Usar como: hw:1,0
```

**Salida (altavoces)**:
```bash
aplay -l
# Similar a arecord
```

## Solución de Problemas

### "FFplay no encontrado"
```bash
sudo apt install ffmpeg
```

### Video no se muestra en RX
1. Verificar que FFplay esté en PATH: `which ffplay`
2. Probar manualmente: `ffplay udp://@:39400`
3. Comprobar firewall: `sudo ufw disable` (temporal)
4. Verificar IPs con `ping` desde ambos PCs

### Audio no funciona
1. Listar dispositivos: `arecord -l` y `aplay -l`
2. Verificar permisos: `groups` (debe incluir `audio`)
   ```bash
   sudo usermod -aG audio $USER
   newgrp audio
   ```
3. Probar dispositivo: `arecord -D hw:1,0 -d 5 test.wav`

### Conexión hotspot inestable
1. Verificar SSID: `nmcli dev wifi list`
2. Reconectar: `nmcli dev disconnect wlan0` → reconectar
3. Ver IPs: `nmcli device show wlan0`

### TX process se detiene sin motivo
1. Verificar disponibilidad de dispositivo: `/dev/video0` accesible
2. Revisar logs de FFmpeg en consola
3. Reducir bitrate o FPS si hay sobrecarga CPU

## Estructura del Proyecto

```
.
├── main.py                          # Aplicación principal (PyQt6 UI)
├── modules/
│   ├── ffmpeg_controller.py        # Controlador FFmpeg/FFplay
│   ├── profile_manager.py          # Gestor de perfiles JSON
│   └── ui_components.py            # Componentes PyQt6 reutilizables
├── config/
│   └── videoconf_profiles.json     # Perfiles de calidad (generado automáticamente)
├── setup_hotspot.sh                # Script para crear hotspot
├── restore_hotspot.sh              # Script para restaurar interfaz
├── requierements.txt               # Dependencias Python
└── docs/
    └── APPLICATION_GUIDE.txt       # Este documento (versión expandida)
```

## Guardando Configuración Personalizada

La aplicación guarda automáticamente perfiles en:
```
~/.videoconf_profiles.json
```

Puedes:
1. **Modificar valores en la UI** → se actualizan en el perfil activo
2. **Seleccionar un perfil** → carga valores automáticamente
3. **Crear nuevos perfiles** manualmente editando `~/.videoconf_profiles.json`

Formato JSON:
```json
{
  "cercano": {
    "fps_entrada": 30,
    "fps_salida": 30,
    "width": 1920,
    "height": 1080,
    "video_bitrate": 8000,
    "audio_bitrate": 128,
    ...
  }
}
```

## Notas de Implementación

- **TX**: FFmpeg captura de `/dev/videoX` + `hw:X,Y` → transmite UDP MPEG-1
- **RX**: FFplay escucha `udp://@:39400` en ventana independiente
- **Threading**: Procesos monitoreados en hilos separados para no bloquear UI
- **Locks**: Sincronización thread-safe para iniciar/detener TX/RX simultáneamente
- **Perfiles**: Almacenados en JSON, cargados al iniciar, guardados al cambiar

## Ejecución

```bash
source .env/bin/activate
python main.py
```

## Licencia

GPL v3

---

**Última actualización**: 2025 - Versión Hotspot
**Compatibilidad**: Ubuntu 20.04 LTS, 22.04 LTS, 24.04 LTS