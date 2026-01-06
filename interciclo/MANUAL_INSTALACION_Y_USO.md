# 📖 Manual de Instalación y Uso
## VideoConferencia P2P con FFmpeg

---

## 📋 Tabla de Contenidos

1. [Descripción General](#-descripción-general)
2. [Requisitos del Sistema](#-requisitos-del-sistema)
3. [Instalación](#-instalación)
4. [Configuración de Red (Hotspot WiFi)](#-configuración-de-red-hotspot-wifi)
5. [Configuración de la Aplicación](#-configuración-de-la-aplicación)
6. [Uso de la Aplicación](#-uso-de-la-aplicación)
7. [Solución de Problemas](#-solución-de-problemas)
8. [Preguntas Frecuentes](#-preguntas-frecuentes)

---

## 🎯 Descripción General

Esta aplicación permite realizar videollamadas **punto a punto (P2P)** entre dos computadoras Ubuntu utilizando **FFmpeg** para transmisión y **FFplay** para recepción de video/audio.

### Características Principales:

- ✅ **Transmisión de video y audio** en tiempo real vía UDP
- ✅ **Perfiles preconfigurados** según distancia (cercano, medio, lejano)
- ✅ **Sin servidores externos** - comunicación directa entre PCs
- ✅ **Ventanas emergentes** para visualización de video
- ✅ **Arquitectura thread-safe** que evita bloqueos al usar TX+RX simultáneos

### Topología de Red:

```
PC A (Anfitrión)                    PC B (Cliente)
┌─────────────────┐                ┌─────────────────┐
│   192.168.x.1   │◄───── WiFi ────►│  192.168.x.xyz  │
│                 │    Hotspot      │                 │
│ TX: udp://B:... │                │ TX: udp://A:... │
│ RX: udp://@:... │                │ RX: udp://@:... │
└─────────────────┘                └─────────────────┘
```

---

## 💻 Requisitos del Sistema

### Sistema Operativo
- **Ubuntu 20.04+** (o derivados: Linux Mint, Pop!_OS, etc.)
- **Arquitectura**: x86_64 (AMD64)

### Hardware Mínimo
- **CPU**: Procesador dual-core 2.0 GHz o superior
- **RAM**: 2 GB mínimo, 4 GB recomendado
- **Almacenamiento**: 500 MB libres
- **Red**: Adaptador WiFi (wlan0 o similar)
- **Webcam**: Cualquier cámara USB o integrada compatible con V4L2
- **Audio**: Tarjeta de sonido con micrófono

### Software Base
- **Python**: 3.7 o superior
- **FFmpeg**: 4.2 o superior
- **NetworkManager**: Para gestión de hotspot WiFi

---

## 🔧 Instalación

### Paso 1: Clonar el Repositorio

**En ambas computadoras**, abre una terminal y ejecuta:

```bash
# Navegar a la carpeta donde quieres instalar
cd ~/

# Clonar el repositorio (reemplaza <repo-url> con la URL real)
git clone <repo-url>
cd interciclo
```

Si no tienes Git instalado:
```bash
sudo apt install git
```

---

### Paso 2: Instalar Dependencias del Sistema

**En ambas computadoras**, ejecuta:

```bash
sudo apt update
sudo apt install -y python3 python3-pip python3-venv ffmpeg v4l-utils alsa-utils
```

**Verificar instalación de FFmpeg:**
```bash
ffmpeg -version
ffplay -version
```

Deberías ver información de la versión instalada.

---

### Paso 3: Crear Entorno Virtual de Python

**En ambas computadoras**, dentro de la carpeta del proyecto:

```bash
# Crear entorno virtual
python3 -m venv .env

# Activar entorno virtual
source .env/bin/activate

# Verificar que el prompt cambió (debe mostrar ".env" al inicio)
```

Para **desactivar** el entorno más tarde:
```bash
deactivate
```

---

### Paso 4: Instalar Dependencias de Python

Con el entorno virtual activado, instala las librerías necesarias:

```bash
pip install --upgrade pip
pip install -r requierements.txt
```

**Nota**: El archivo `requierements.txt` contiene:
- `PyQt6` - Interfaz gráfica
- `python-vlc` - (Opcional, no usado actualmente)
- Otras dependencias de análisis (matplotlib, scipy, numpy, scapy)

---

### Paso 5: Verificar Dispositivos de Video y Audio

**Verificar cámara web:**
```bash
# Listar dispositivos de video
ls -l /dev/video*

# Probar cámara (debe abrir una ventana)
ffplay -f v4l2 -video_size 640x480 -i /dev/video0
# Presiona 'q' para salir
```

**Verificar micrófono:**
```bash
# Listar dispositivos de audio
arecord -l

# Ejemplo de salida:
# card 1: HD [HD Webcam], device 6: USB Audio [USB Audio]
# Esto significa que debes usar: hw:1,6
```

**Probar captura de audio:**
```bash
# Capturar 5 segundos de audio y reproducir
arecord -D hw:1,6 -f S16_LE -r 48000 -c 2 -d 5 test.wav && aplay test.wav
```

---

### Paso 6: Dar Permisos a Scripts

Los scripts de hotspot necesitan permisos de ejecución:

```bash
chmod +x setup_hotspot.sh
chmod +x restore_hotspot.sh
```

---

## 📡 Configuración de Red (Hotspot WiFi)

Para que las dos computadoras se comuniquen, una debe actuar como **anfitrión (hotspot)** y la otra como **cliente**.

---

### 🖥️ **PC ANFITRIÓN** - Crear Hotspot

El PC anfitrión compartirá su red WiFi para que el otro PC se conecte.

#### Opción A: Usando el Script (Recomendado)

```bash
sudo ./setup_hotspot.sh wlan0 videoconf 12345678
```

**Parámetros:**
- `wlan0` - Interfaz WiFi (puede ser wlan1, wlp3s0, etc. según tu sistema)
- `videoconf` - Nombre de la red (SSID)
- `12345678` - Contraseña (mínimo 8 caracteres)

**Salida esperada:**
```
================================
   Creación de Hotspot WiFi
================================

→ Activando hotspot en wlan0
  SSID: videoconf
  Password: 12345678

→ Deteniendo posibles conexiones previas...
→ Iniciando hotspot...
✓ Hotspot creado correctamente

================================
 Hotspot activo
================================

IP4.ADDRESS[1]: 192.168.x.1/24

✓ Operación completada
```

**Anota la dirección IP mostrada** (por ejemplo: `192.168.127.1`). La necesitarás más adelante.

#### Opción B: Usando NetworkManager (Manual)

```bash
# Crear hotspot
sudo nmcli dev wifi hotspot ifname wlan0 ssid "videoconf" password "12345678"

# Verificar IP asignada al anfitrión
nmcli device show wlan0 | grep IP4.ADDRESS
```

#### Verificar que el Hotspot está Activo

```bash
# Ver estado de la interfaz
ip addr show wlan0

# Deberías ver algo como:
# inet 192.168.x.1/24 brd 192.168.x.255 scope global noprefixroute wlan0
```

---

### 💻 **PC CLIENTE** - Conectarse al Hotspot

El PC cliente debe conectarse a la red WiFi creada por el anfitrión.

#### Opción A: Desde la Interfaz Gráfica de Ubuntu

1. Haz clic en el **icono de WiFi** en la barra superior
2. Busca la red **"videoconf"** en la lista
3. Haz clic y selecciona **"Conectar"**
4. Introduce la contraseña: **`12345678`**
5. Espera a que se conecte (el icono de WiFi mostrará conexión establecida)

#### Opción B: Desde Terminal

```bash
# Conectarse al hotspot
nmcli dev wifi connect "videoconf" password "12345678"

# Verificar conexión
nmcli connection show --active
```

#### Verificar IP Asignada al Cliente

```bash
ip addr show wlan0 | grep "inet "

# Salida esperada (ejemplo):
# inet 192.168.127.48/24 brd 192.168.127.255 scope global dynamic noprefixroute wlan0
```

**Anota tu IP** (por ejemplo: `192.168.127.48`). La necesitarás para configurar la aplicación.

---

### 🔄 Restaurar Red Normal (Cuando Termines)

**En el PC Anfitrión**, ejecuta:

```bash
sudo ./restore_hotspot.sh wlan0
```

O manualmente:
```bash
sudo nmcli device disconnect wlan0
sudo systemctl restart NetworkManager
```

**En el PC Cliente**, simplemente desconecta la red WiFi "videoconf" desde el icono de red.

---

## ⚙️ Configuración de la Aplicación

Antes de iniciar la videollamada, ambos PCs deben configurar correctamente las direcciones de transmisión (TX) y recepción (RX).

---

### 📋 Ejemplo de Configuración Completa

Supongamos que:
- **PC Anfitrión** tiene IP: `192.168.127.1`
- **PC Cliente** tiene IP: `192.168.127.48`
- Ambos usarán el puerto: `39400`

#### En el **PC ANFITRIÓN (192.168.127.1)**:

1. **Dirección TX** (enviar video al cliente):
   ```
   udp://192.168.127.48:39400
   ```

2. **Dirección RX** (recibir video del cliente):
   ```
   udp://@:39400
   ```

#### En el **PC CLIENTE (192.168.127.48)**:

1. **Dirección TX** (enviar video al anfitrión):
   ```
   udp://192.168.127.1:39400
   ```

2. **Dirección RX** (recibir video del anfitrión):
   ```
   udp://@:39400
   ```

---

### 🔍 Detalles Importantes

#### Formato de Dirección TX (Transmisión):
```
udp://<IP_DEL_OTRO_PC>:<PUERTO>
```
- Reemplaza `<IP_DEL_OTRO_PC>` con la IP del PC al que quieres enviar
- El puerto debe ser el mismo en ambos PCs (por defecto: `39400`)

#### Formato de Dirección RX (Recepción):
```
udp://@:<PUERTO>
```
- El símbolo `@` significa "escuchar en todas las interfaces"
- El puerto debe coincidir con el puerto al que el otro PC está enviando

---

### 📝 Configuración de Dispositivos

#### Dispositivo de Video

Valor por defecto: `/dev/video0`

Si tienes múltiples cámaras:
```bash
ls -l /dev/video*
```

Prueba cada dispositivo:
```bash
ffplay -f v4l2 -i /dev/video0  # Prueba video0
ffplay -f v4l2 -i /dev/video2  # Prueba video2
```

Usa el dispositivo que muestra tu cámara correctamente.

#### Dispositivo de Audio

Valor por defecto: `hw:1,6`

Para encontrar tu dispositivo:
```bash
arecord -l

# Ejemplo de salida:
# card 1: HD [HD Webcam], device 6: USB Audio [USB Audio]
# Formato: hw:<CARD>,<DEVICE> → hw:1,6
```

#### Perfiles de Calidad

La aplicación incluye 3 perfiles preconfigurados:

| Perfil   | Resolución | Bitrate Video | Bitrate Audio | Uso Recomendado                    |
|----------|------------|---------------|---------------|------------------------------------|
| Cercano  | 854x480    | 500 kbps      | 64 kbps       | Misma habitación, señal excelente  |
| Medio    | 704x576    | 200 kbps      | 32 kbps       | Distancia media, señal buena       |
| Lejano   | 352x288    | 150 kbps      | 32 kbps       | Larga distancia, señal débil       |

**Puedes modificar y guardar** estos perfiles desde la aplicación usando el botón "Guardar".

---

## 🚀 Uso de la Aplicación

### Paso 1: Iniciar la Aplicación

**En ambas computadoras**, con el entorno virtual activado:

```bash
# Activar entorno (si no está activo)
source .env/bin/activate

# Ejecutar aplicación
python main.py
```

Se abrirá la ventana principal de la aplicación.

---

### Paso 2: Configurar Parámetros

#### 2.1. Seleccionar Perfil de Calidad

En la parte superior, selecciona un perfil según tu situación:
- **Cercano**: Para PCs muy cerca (misma habitación)
- **Medio**: Para distancia moderada
- **Lejano**: Para máxima distancia o señal débil

El perfil cargará automáticamente los valores de resolución y bitrate.

#### 2.2. Configurar Red (Tab "Red")

Haz clic en el tab **"Red"** y configura:

1. **Dirección TX**: 
   - Ingresa `udp://<IP_DEL_OTRO_PC>:39400`
   - Ejemplo: `udp://192.168.127.48:39400`

2. **Dirección RX**:
   - Deja `udp://@:39400` (valor por defecto)

#### 2.3. Verificar Dispositivos (Opcional)

- **Tab "Video"**: Verifica que "Dispositivo Video" sea correcto (ej: `/dev/video0`)
- **Tab "Audio"**: Verifica que "Dispositivo Audio" sea correcto (ej: `hw:1,6`)

---

### Paso 3: Iniciar Transmisión y Recepción

#### ▶️ Iniciar Transmisión (TX)

1. Haz clic en el botón **"▶ Iniciar Transmisión"** (verde)
2. El botón se deshabilitará y aparecerá habilitado **"⏹ Detener Transmisión"**
3. El estado mostrará: **"Estado: Transmitiendo..."** (fondo verde)

**Esto iniciará FFmpeg** capturando video de tu cámara y audio de tu micrófono, enviándolo al otro PC.

#### ▶️ Iniciar Recepción (RX)

1. Haz clic en el botón **"▶ Iniciar Recepción"** (azul)
2. Se abrirá una **ventana emergente de FFplay** mostrando el video recibido
3. El estado mostrará: **"Estado: Recibiendo con FFplay..."** (fondo azul)

**La ventana de FFplay** mostrará el video que está enviando el otro PC.

---

### Paso 4: Durante la Videollamada

#### Controles de FFplay (Ventana de Video)

- **Pantalla completa**: Presiona `F`
- **Silenciar audio**: Presiona `M`
- **Cerrar ventana**: Presiona `Q` o haz clic en **"⏹ Detener Recepción"**

#### Monitoreo de Estado

La aplicación monitorea automáticamente los procesos cada segundo:
- Si un proceso se detiene inesperadamente, la UI se actualizará
- El estado mostrará mensajes en color naranja si algo falla

#### Uso Simultáneo de TX y RX

✅ **Puedes tener TX y RX activos al mismo tiempo** sin problemas de bloqueo.

La aplicación usa **threading** para manejar ambos procesos de forma independiente.

---

### Paso 5: Detener Transmisión/Recepción

#### ⏹ Detener Transmisión

1. Haz clic en **"⏹ Detener Transmisión"** (rojo)
2. El proceso de FFmpeg se detendrá
3. El estado volverá a: **"Estado: Transmisión detenida"**

#### ⏹ Detener Recepción

1. Haz clic en **"⏹ Detener Recepción"** (rojo)
2. La ventana de FFplay se cerrará
3. El estado volverá a: **"Estado: Recepción detenida"**

---

### Paso 6: Cerrar la Aplicación

Simplemente cierra la ventana principal o presiona `Ctrl+C` en la terminal.

La aplicación **limpiará automáticamente** todos los procesos al cerrarse.

---

## 🔧 Solución de Problemas

### Problema: No se ve video en FFplay

#### Causa Posible 1: El otro PC no está transmitiendo
**Solución:**
- Verifica que el otro PC haya iniciado transmisión
- Revisa que el botón "Iniciar Transmisión" esté deshabilitado (significa que está activo)

#### Causa Posible 2: Direcciones incorrectas
**Solución:**
- **PC A** debe enviar a la IP de **PC B**
- **PC B** debe enviar a la IP de **PC A**
- Ambos deben recibir en `udp://@:39400`

Verifica las IPs con:
```bash
ip addr show wlan0 | grep "inet "
```

#### Causa Posible 3: Firewall bloqueando puerto
**Solución:**
```bash
# Permitir puerto 39400 (UDP)
sudo ufw allow 39400/udp

# O desactivar firewall temporalmente (no recomendado)
sudo ufw disable
```

#### Causa Posible 4: No hay conectividad
**Solución:**
```bash
# Desde PC Cliente, hacer ping al Anfitrión
ping 192.168.127.1

# Desde PC Anfitrión, hacer ping al Cliente
ping 192.168.127.48
```

Si no hay respuesta, revisa la conexión al hotspot.

---

### Problema: No se captura video de la cámara

#### Causa: Dispositivo de video incorrecto
**Solución:**
```bash
# Listar cámaras disponibles
ls -l /dev/video*

# Probar cada una
ffplay -f v4l2 -i /dev/video0
ffplay -f v4l2 -i /dev/video2
```

Usa el dispositivo que funcione en el campo "Dispositivo Video".

#### Causa: Cámara en uso por otra aplicación
**Solución:**
```bash
# Cerrar aplicaciones que puedan usar la cámara (Zoom, Skype, Cheese, etc.)
killall cheese
killall ffmpeg
```

---

### Problema: No se captura audio

#### Causa: Dispositivo de audio incorrecto
**Solución:**
```bash
# Listar dispositivos de audio
arecord -l

# Ejemplo:
# card 1: HD [HD Webcam], device 6: USB Audio [USB Audio]
# Formato: hw:<CARD>,<DEVICE> → hw:1,6
```

Actualiza el campo "Dispositivo Audio" con el valor correcto.

#### Causa: Micrófono silenciado
**Solución:**
```bash
# Abrir control de volumen
alsamixer

# Presiona F4 (Capture)
# Usa flechas para seleccionar el micrófono
# Presiona 'M' para desmutear
# Usa flechas arriba/abajo para ajustar volumen
```

---

### Problema: La aplicación se congela al usar TX+RX

**Solución:**
Este problema fue resuelto en la última versión. Asegúrate de tener el código actualizado:

```bash
git pull origin main
```

El código actual usa **threading** para evitar bloqueos. Ejecuta los tests:
```bash
python test_no_bloqueos.py
```

Deberías ver:
```
✅ PASS: TX+RX Simultáneos
✅ PASS: Cambios Rápidos
✅ TODOS LOS TESTS PASARON
```

---

### Problema: Error "FFmpeg no encontrado"

**Solución:**
```bash
# Instalar FFmpeg
sudo apt install ffmpeg

# Verificar instalación
which ffmpeg
ffmpeg -version
```

---

### Problema: Error "PyQt6 no encontrado"

**Solución:**
```bash
# Activar entorno virtual
source .env/bin/activate

# Reinstalar dependencias
pip install -r requierements.txt
```

---

### Problema: Hotspot no se crea

#### Causa: Interfaz incorrecta
**Solución:**
```bash
# Listar interfaces de red
ip link show

# Busca la interfaz WiFi (wlan0, wlp3s0, wlp2s0, etc.)
# Ejemplo de salida:
# 3: wlan0: <BROADCAST,MULTICAST,UP,LOWER_UP>
```

Usa la interfaz correcta en el script:
```bash
sudo ./setup_hotspot.sh <TU_INTERFAZ> videoconf 12345678
```

#### Causa: NetworkManager no está corriendo
**Solución:**
```bash
# Iniciar NetworkManager
sudo systemctl start NetworkManager

# Habilitar para que inicie automáticamente
sudo systemctl enable NetworkManager
```

---

## ❓ Preguntas Frecuentes

### ¿Puedo usar esta aplicación en redes normales (no hotspot)?

**Sí**, siempre que ambos PCs estén en la misma red local (LAN) y tengan IPs accesibles entre sí.

Ejemplo:
- PC A: `192.168.1.10`
- PC B: `192.168.1.20`

Configura las direcciones TX/RX de la misma forma que con hotspot.

---

### ¿Puedo cambiar el puerto 39400?

**Sí**, pero debes cambiar ambas direcciones consistentemente:

- Si cambias a puerto `5000`:
  - TX: `udp://192.168.127.48:5000`
  - RX: `udp://@:5000`

---

### ¿Por qué FFplay abre en ventana externa?

La arquitectura fue simplificada para evitar problemas de embebido de video en PyQt6. FFplay en ventana externa es más estable y con menor latencia.

---

### ¿Puedo grabar las videollamadas?

Sí, puedes modificar el comando de FFmpeg para guardar a archivo en lugar de transmitir. Consulta la documentación de FFmpeg.

---

### ¿Funciona en otras distribuciones Linux?

Debería funcionar en cualquier distribución basada en Debian/Ubuntu con NetworkManager. Prueba en:
- Linux Mint
- Pop!_OS
- Elementary OS
- Debian

Para otras distribuciones (Fedora, Arch), el script de hotspot puede requerir ajustes.

---

### ¿Cuánto ancho de banda consume?

Depende del perfil seleccionado:

| Perfil   | Video Bitrate | Audio Bitrate | Total Aprox. |
|----------|---------------|---------------|--------------|
| Cercano  | 500 kbps      | 64 kbps       | **~564 kbps** |
| Medio    | 200 kbps      | 32 kbps       | **~232 kbps** |
| Lejano   | 150 kbps      | 32 kbps       | **~182 kbps** |

Para videollamada bidireccional (TX+RX en ambos PCs), multiplica por 2.

---

### ¿Hay latencia en la transmisión?

La latencia típica es de **200-500 ms** dependiendo de:
- Calidad de la señal WiFi
- Distancia entre PCs
- Carga de CPU
- Perfil seleccionado

Para minimizar latencia:
- Usa el perfil "Lejano" (menor resolución = menor latencia)
- Mantén los PCs cerca del punto de acceso hotspot
- Cierra aplicaciones que consuman ancho de banda

---

### ¿Puedo conectar más de 2 PCs?

La aplicación está diseñada para comunicación punto a punto (P2P). Para conectar 3+ PCs necesitarías implementar multicast o múltiples conexiones.

---

## 📚 Recursos Adicionales

### Archivos de Documentación

- `SOLUCION_BLOQUEOS.md` - Explicación técnica de la arquitectura de threading
- `README_BLOQUEOS.md` - Guía rápida sobre el sistema sin bloqueos
- `test_no_bloqueos.py` - Suite de tests para validar funcionamiento

### Comandos Útiles

**Monitorear tráfico UDP:**
```bash
sudo tcpdump -i wlan0 udp port 39400
```

**Ver procesos FFmpeg activos:**
```bash
ps aux | grep ffmpeg
ps aux | grep ffplay
```

**Matar procesos FFmpeg manualmente:**
```bash
killall ffmpeg
killall ffplay
```

**Ver log de NetworkManager:**
```bash
journalctl -u NetworkManager -f
```

---

## 📞 Soporte

Si encuentras problemas no cubiertos en este manual:

1. Verifica los logs en la terminal donde ejecutaste `python main.py`
2. Ejecuta los tests: `python test_no_bloqueos.py`
3. Revisa la documentación técnica en `SOLUCION_BLOQUEOS.md`

---

## 📝 Notas Finales

- ⚠️ **Seguridad**: Este sistema no usa encriptación. No transmitas información sensible.
- ⚠️ **Red Pública**: No uses en redes WiFi públicas sin VPN.
- ✅ **Pruebas**: Siempre prueba la configuración antes de una llamada importante.
- ✅ **Backup**: Guarda una copia de tus perfiles personalizados.

---

**¡Disfruta de tus videollamadas P2P con baja latencia! 🎥📞**
