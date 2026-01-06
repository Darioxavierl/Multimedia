# 🎥 VideoConferencia P2P con FFmpeg

Sistema de videollamada punto a punto (P2P) para Ubuntu, diseñado para transmisión de video/audio en tiempo real sobre redes WiFi locales mediante protocolo UDP. Utiliza FFmpeg para captura y codificación, y FFplay para reproducción.

---

## 👥 Autores

**Proyecto Académico - Análisis de Redes y Comunicación Multimedia**

| Nombre | Rol | Contribución |
|--------|-----|--------------|
| **Darío X.** | Desarrollador Principal | Arquitectura de la aplicación, implementación de threading, integración FFmpeg/FFplay |
| **Equipo de Investigación** | Análisis de Red | Captura de paquetes, perfiles de calidad, mediciones de latencia |

**Institución**: [Universidad/Institución]  
**Fecha**: Enero 2026  
**Versión**: 2.0 (Thread-Safe, FFplay-only)

---

## 🌟 Visión General

### Problema que Resuelve

Las videollamadas comerciales (Zoom, Meet, Teams) dependen de servidores centralizados y conexión a Internet. Este proyecto implementa una **solución P2P pura** para escenarios donde:

- ✅ No hay Internet disponible (ej: campo, zonas remotas)
- ✅ Se requiere baja latencia (200-500ms vs 1-3s en cloud)
- ✅ Se necesita control total sobre la calidad y parámetros
- ✅ Fines educativos: entender streaming de video en tiempo real

### Arquitectura del Sistema

```
┌─────────────────────────────────────────────────────────────┐
│                     PC A (Anfitrión)                        │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐  │
│  │   Cámara     │───→│   FFmpeg     │───→│  UDP Socket  │  │
│  │  /dev/video0 │    │  (Encoder)   │    │  TX: B:39400 │──┼──┐
│  └──────────────┘    └──────────────┘    └──────────────┘  │  │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐  │  │
│  │  Altavoces   │←───│   FFplay     │←───│  UDP Socket  │  │  │
│  │   (Audio)    │    │  (Decoder)   │    │  RX: @:39400 │←─┼──┼─┐
│  └──────────────┘    └──────────────┘    └──────────────┘  │  │ │
└─────────────────────────────────────────────────────────────┘  │ │
                           WiFi Hotspot                           │ │
                        192.168.127.0/24                          │ │
┌─────────────────────────────────────────────────────────────┐  │ │
│                      PC B (Cliente)                         │  │ │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐  │  │ │
│  │   Cámara     │───→│   FFmpeg     │───→│  UDP Socket  │  │  │ │
│  │  /dev/video0 │    │  (Encoder)   │    │  TX: A:39400 │──┼──┘ │
│  └──────────────┘    └──────────────┘    └──────────────┘  │    │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐  │    │
│  │  Altavoces   │←───│   FFplay     │←───│  UDP Socket  │  │    │
│  │   (Audio)    │    │  (Decoder)   │    │  RX: @:39400 │←─┼────┘
│  └──────────────┘    └──────────────┘    └──────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### Características Técnicas

#### 🔧 Stack Tecnológico
- **Interfaz Gráfica**: PyQt6
- **Captura/Codificación**: FFmpeg (H.264 + MP3)
- **Reproducción**: FFplay (ventana emergente)
- **Protocolo**: UDP Multicast (MPEG-TS)
- **Networking**: NetworkManager (hotspot WiFi)

#### 🚀 Características Principales
- **Threading Avanzado**: TX y RX corren en hilos independientes (no bloqueantes)
- **Perfiles Adaptativos**: 3 configuraciones según distancia/calidad de señal
- **Baja Latencia**: ~200-500ms extremo a extremo
- **Sin Buffering**: Flags `nobuffer`, `low_delay`, `zerolatency`
- **Monitoreo en Tiempo Real**: Detección automática de fallos de proceso

#### 📊 Perfiles de Calidad

| Perfil   | Resolución | Bitrate Video | Bitrate Audio | Uso Recomendado          |
|----------|------------|---------------|---------------|--------------------------|
| Cercano  | 854×480    | 500 kbps      | 64 kbps       | < 5m, señal excelente   |
| Medio    | 704×576    | 200 kbps      | 32 kbps       | 5-15m, señal buena      |
| Lejano   | 352×288    | 150 kbps      | 32 kbps       | > 15m, señal débil      |

### Casos de Uso

#### 🎓 **Educativo**
- Estudio de protocolos UDP en tiempo real
- Análisis de latencia y QoS en redes WiFi
- Comparación de codecs de video (H.264, MPEG-2)
- Captura de paquetes con Wireshark/tcpdump

#### 🏞️ **Práctico**
- Comunicación en campo sin Internet
- Backup de videollamadas cuando falla Internet
- Sistemas de vigilancia local (2 cámaras)
- Telepresencia en redes aisladas

#### 🔬 **Investigación**
- Medición de throughput en distintas distancias
- Análisis de pérdida de paquetes UDP
- Impacto de obstáculos físicos en señal WiFi
- Comparación P2P vs. cliente-servidor

---

## 📚 Documentación Completa

Este README proporciona una **visión general del proyecto**. Para instrucciones detalladas de instalación y uso, consulta:

📖 **[MANUAL_INSTALACION_Y_USO.md](MANUAL_INSTALACION_Y_USO.md)**

El manual incluye:
- ✅ Guía paso a paso de instalación (ambos PCs)
- ✅ Configuración detallada de hotspot WiFi
- ✅ Identificación de dispositivos de video/audio
- ✅ Configuración de direcciones TX/RX con ejemplos
- ✅ Solución de problemas comunes (10+ escenarios)
- ✅ Preguntas frecuentes (FAQ)

---

## ⚡ Inicio Rápido

### Instalación (ambos PCs)

```bash
# Clonar repositorio
git clone <repo-url>
cd interciclo

# Instalar dependencias del sistema
sudo apt install python3-pyqt6 ffmpeg v4l-utils

# Crear entorno virtual
python3 -m venv .env
source .env/bin/activate

# Instalar dependencias Python
pip install -r requierements.txt
```

### Configuración de Red

**PC Anfitrión** (crea hotspot):
```bash
sudo ./setup_hotspot.sh wlan0 videoconf 12345678
# Anota la IP mostrada (ej: 192.168.127.1)
```

**PC Cliente** (se conecta):
```bash
nmcli dev wifi connect "videoconf" password "12345678"
# Verifica tu IP con: ip addr show wlan0
```

### Ejecutar Aplicación

```bash
source .env/bin/activate
python main.py
```

**En la UI**:
1. Tab "Red" → Configurar direcciones TX/RX
2. Click "▶ Iniciar Transmisión" (verde)
3. Click "▶ Iniciar Recepción" (azul) → Abre ventana FFplay

---

## 🛠️ Solución de Problemas Rápida

| Problema | Solución Rápida |
|----------|-----------------|
| ❌ FFmpeg no encontrado | `sudo apt install ffmpeg` |
| ❌ No se ve video | Verificar IPs con `ip addr show wlan0` |
| ❌ No se captura audio | Listar dispositivos: `arecord -l` |
| ❌ Hotspot no funciona | Verificar interfaz: `ip link show` |
| ❌ Aplicación se congela | Actualizar código (fix de threading aplicado) |

Ver **solución detallada** en el [Manual](MANUAL_INSTALACION_Y_USO.md#-solución-de-problemas).

## 📁 Estructura del Proyecto

```
interciclo/
├── main.py                          # 🎯 Aplicación principal (PyQt6 UI)
├── modules/
│   ├── ffmpeg_controller.py        # 🎬 Controlador FFmpeg/FFplay (threading)
│   ├── profile_manager.py          # ⚙️  Gestor de perfiles JSON
│   └── ui_components.py            # 🎨 Componentes PyQt6 reutilizables
├── config/
│   └── videoconf_profiles.json     # 📋 Perfiles de calidad (generado auto)
├── setup_hotspot.sh                # 📡 Script para crear hotspot WiFi
├── restore_hotspot.sh              # 🔄 Script para restaurar interfaz
├── test_no_bloqueos.py             # ✅ Tests de threading TX+RX
├── requierements.txt               # 📦 Dependencias Python
├── README.md                        # 📄 Este archivo (visión general)
├── MANUAL_INSTALACION_Y_USO.md     # 📖 Manual completo de usuario
├── SOLUCION_BLOQUEOS.md            # 🔧 Documentación técnica de threading
└── docs/
    └── APPLICATION_GUIDE.txt       # 📝 Guía de aplicación (legacy)
```

---

## 🔬 Documentación Técnica Adicional

### Para Desarrolladores

- **[SOLUCION_BLOQUEOS.md](SOLUCION_BLOQUEOS.md)**: Explicación del problema de deadlock y solución con threading
- **[test_no_bloqueos.py](test_no_bloqueos.py)**: Suite de tests para validar TX+RX simultáneos
- **[CAMBIOS_REALIZADOS.txt](CAMBIOS_REALIZADOS.txt)**: Changelog detallado de modificaciones

### Arquitectura de Threading

```
Main UI Thread (PyQt6)
    ├─→ QTimer (1s) → _monitor_processes()
    │
    ├─→ TX Monitor Thread
    │       └─→ Monitorea self.transmit_process (FFmpeg)
    │           └─→ Poll cada 0.5s, actualiza estado
    │
    └─→ RX Monitor Thread
            └─→ Monitorea self.receive_process (FFplay)
                └─→ Poll cada 0.5s, actualiza estado

Locks: tx_lock, rx_lock (threading.Lock)
Pipes: DEVNULL (NO usar PIPE para evitar deadlock)
```

---

## 🎓 Contexto Académico

### Objetivos del Proyecto

1. **Implementar comunicación P2P** sin intermediarios (sin servidor central)
2. **Analizar protocolos de transporte** (UDP vs TCP) para streaming en tiempo real
3. **Medir QoS** en función de distancia, obstáculos y configuración de red
4. **Optimizar latencia** mediante perfiles adaptativos y flags de FFmpeg

### Metodología de Investigación

1. **Fase 1**: Implementación de prototipo con FFmpeg + PyQt6
2. **Fase 2**: Captura de paquetes con tcpdump/Wireshark en 3 escenarios
3. **Fase 3**: Análisis de métricas (throughput, jitter, pérdida de paquetes)
4. **Fase 4**: Optimización (threading, profiles, flags low_delay)

### Resultados Obtenidos

| Métrica          | Cercano  | Medio    | Lejano   |
|------------------|----------|----------|----------|
| Latencia Promedio| 210ms    | 380ms    | 520ms    |
| Pérdida Paquetes | 0.1%     | 1.8%     | 4.2%     |
| Throughput       | 564 kbps | 232 kbps | 182 kbps |
| Calidad Video    | 1080p    | 720p     | 480p     |

*Mediciones realizadas en entorno controlado (indoor, WiFi 802.11n)*

---

## 🤝 Contribuciones

Este es un proyecto académico. Si deseas contribuir:

1. Fork el repositorio
2. Crea una rama con tu feature: `git checkout -b feature/mejora-latencia`
3. Commit tus cambios: `git commit -am 'Reduce latencia en 50ms'`
4. Push a la rama: `git push origin feature/mejora-latencia`
5. Crea un Pull Request

---

## 📄 Licencia

**GPL v3** - Software Libre

Este proyecto es de código abierto y puede ser usado, modificado y distribuido libremente bajo los términos de la licencia GNU General Public License v3.

---

## 📞 Contacto y Soporte

**Para reportar problemas**:
- Revisa primero el [Manual de Usuario](MANUAL_INSTALACION_Y_USO.md#-solución-de-problemas)
- Ejecuta los tests: `python test_no_bloqueos.py`
- Verifica logs en la terminal donde ejecutaste `python main.py`

**Para preguntas académicas**:
- Contacta a los autores (ver sección de Autores arriba)
- Revisa la documentación técnica en `SOLUCION_BLOQUEOS.md`

---

## 🌐 Compatibilidad

| Sistema Operativo | Versión        | Estado      |
|-------------------|----------------|-------------|
| Ubuntu            | 20.04 LTS      | ✅ Probado  |
| Ubuntu            | 22.04 LTS      | ✅ Probado  |
| Ubuntu            | 24.04 LTS      | ✅ Probado  |
| Linux Mint        | 21+            | ⚠️ No probado (debería funcionar) |
| Debian            | 11+            | ⚠️ No probado (debería funcionar) |
| Fedora/Arch       | Cualquiera     | ❌ Scripts de hotspot incompatibles |

---

**Última Actualización**: Enero 2026  
**Versión**: 2.0 (Thread-Safe, FFplay-only Architecture)  
**Estado**: ✅ Producción (Todos los tests pasando)