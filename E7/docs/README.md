# Sistema de Streaming Adaptativo DASH

**Evaluación Capítulo 7 - Comunicaciones Multimedia**

## Información del Proyecto

**Autor:** Dario Portilla  
**Carrera:** Ingeniería en Telecomunicaciones  
**Institución:** Universidad de Cuenca  
**Asignatura:** Comunicaciones Multimedia  
**Capítulo:** 7 - Streaming de Video Adaptativo

## Descripción

Este proyecto implementa un sistema completo de streaming de video adaptativo utilizando el protocolo DASH (Dynamic Adaptive Streaming over HTTP). El sistema captura video en tiempo real desde una cámara USB, lo codifica mediante FFmpeg, y lo transmite a través de un servidor NGINX, permitiendo su visualización mediante Shaka Player con latencia reducida.

### Características Principales

- Streaming de video en vivo con protocolo DASH
- Latencia optimizada (2-3 segundos)
- Codificación H.264 con configuración de baja latencia
- Interfaz web responsive con controles de transmisión
- API REST para control de FFmpeg
- Arquitectura basada en contenedores Docker
- Sistema de temas CSS personalizable

## Arquitectura del Sistema

### Componentes

1. **Backend (Python/FastAPI)**
   - Control del proceso FFmpeg
   - API REST para inicio/detención de transmisión
   - Gestión de logs y estado del sistema

2. **NGINX (Servidor Web)**
   - Servir archivos estáticos (HTML, CSS, JS)
   - Servir segmentos DASH y manifiestos MPD
   - Proxy reverso para API backend
   - Configuración CORS para streaming

3. **Frontend (JavaScript/Shaka Player)**
   - Interfaz de usuario para control de transmisión
   - Reproductor de video adaptativo
   - Visualización de métricas de streaming

4. **FFmpeg (Codificador)**
   - Captura desde dispositivo v4l2 (/dev/video0)
   - Codificación H.264 con preset ultrafast
   - Generación de segmentos DASH
   - Optimización para baja latencia

### Flujo de Datos

```
[Cámara USB] → [FFmpeg] → [Segmentos DASH] → [NGINX] → [Shaka Player] → [Usuario]
     ↑                          ↓
     └────────[API FastAPI]─────┘
```

## Estructura del Proyecto

```
E7/
├── docker-compose.yml          # Orquestación de contenedores
├── backend/
│   ├── Dockerfile             # Imagen Docker del backend
│   ├── main.py               # API REST con FastAPI
│   └── requirements.txt      # Dependencias Python
├── nginx/
│   ├── nginx.conf            # Configuración principal NGINX
│   └── default.conf          # Configuración del sitio
├── www/
│   └── html/
│       ├── index.html        # Aplicación web principal
│       ├── css/
│       │   ├── variables.css  # Variables CSS (colores, espaciado)
│       │   └── styles.css     # Estilos de la aplicación
│       ├── js/
│       │   ├── main.js                # Punto de entrada
│       │   ├── video-player.js        # Controlador Shaka Player
│       │   ├── stream-controller.js   # API cliente
│       │   └── ui-controller.js       # Controlador UI
│       └── segmentos/         # Directorio para archivos DASH
├── configs/                   # Configuraciones predefinidas
│   ├── video-player-ultra-estable.js
│   ├── video-player-ultra-rapido.js
│   ├── ffmpeg-ultra-estable.txt
│   └── ffmpeg-ultra-rapido.txt
├── rebuild.sh                 # Script para reconstruir backend
├── change-theme.sh           # Script para cambiar temas CSS
├── test-config.sh            # Script para probar configuraciones
└── docs/                     # Documentación del proyecto
    ├── GUIA_AJUSTE.md        # Guía de optimización
    ├── CONFIGURACION.md      # Referencia de configuración
    └── TEMAS.md              # Sistema de temas visuales
```

## Requisitos del Sistema

### Software Necesario

- Docker Engine 20.10 o superior
- Docker Compose 2.0 o superior
- Navegador web moderno (Chrome, Firefox, Edge)
- Cámara USB compatible con v4l2

### Hardware Recomendado

- CPU: 2 núcleos o más
- RAM: 4 GB mínimo
- Cámara USB con soporte v4l2
- Conexión de red: 10 Mbps o superior

## Instalación y Configuración

### 1. Clonar el Repositorio

```bash
git clone <repository-url>
cd E7
```

### 2. Verificar Dispositivo de Video

Comprobar que la cámara está conectada:

```bash
ls -la /dev/video*
```

Salida esperada:
```
crw-rw----+ 1 root video 81, 0 Jan 10 08:06 /dev/video0
```

### 3. Construir e Iniciar Contenedores

```bash
sudo docker compose up -d --build
```

Este comando:
- Construye la imagen del backend
- Descarga la imagen de NGINX
- Crea la red Docker
- Monta los volúmenes necesarios
- Inicia ambos contenedores

### 4. Verificar Estado de Contenedores

```bash
sudo docker compose ps
```

Salida esperada:
```
NAME                IMAGE          STATUS         PORTS
dash-backend        e7-backend     Up             0.0.0.0:8000->8000/tcp
nginx-dash-server   nginx:alpine   Up             0.0.0.0:8081->80/tcp
```

### 5. Acceder a la Aplicación

Abrir navegador y acceder a:
```
http://localhost:8081
```

## Uso del Sistema

### Iniciar Transmisión

1. Acceder a `http://localhost:8081`
2. Presionar botón "Iniciar Transmisión"
3. El sistema automáticamente:
   - Inicia FFmpeg en el backend
   - Espera a que se generen segmentos DASH
   - Carga el manifiesto MPD en Shaka Player
   - Comienza la reproducción

### Detener Transmisión

1. Presionar botón "Detener Transmisión"
2. El sistema:
   - Detiene el proceso FFmpeg
   - Limpia los segmentos temporales
   - Resetea el reproductor

### Monitoreo

La interfaz muestra en tiempo real:
- **Estado**: Estado actual de la transmisión
- **Calidad**: Resolución y bitrate activo
- **Buffer**: Cantidad de video almacenado en buffer

## Configuración Avanzada

### Parámetros de FFmpeg

Los parámetros principales de codificación se encuentran en `backend/main.py`:

```python
# Parámetros de codificación
-preset ultrafast          # Velocidad de codificación
-tune zerolatency         # Optimización para latencia
-g 10                     # Tamaño del GOP (Group of Pictures)
-b:v 1000k                # Bitrate objetivo
-seg_duration 1           # Duración de segmentos (segundos)
-window_size 5            # Ventana de segmentos disponibles
```

### Parámetros de Shaka Player

La configuración del reproductor está en `www/html/js/video-player.js`:

```javascript
bufferingGoal: 4          // Buffer objetivo (segundos)
rebufferingGoal: 2        // Buffer mínimo antes de rebuffering
lowLatencyMode: true      // Modo baja latencia
```

Ver documentación completa en `docs/GUIA_AJUSTE.md`.

## Scripts de Utilidad

### rebuild.sh

Reconstruye el contenedor backend después de cambios en el código:

```bash
./rebuild.sh
```

### change-theme.sh

Cambia el tema visual de la interfaz:

```bash
./change-theme.sh [default|green|red|dark]
```

### test-config.sh

Muestra información sobre configuraciones predefinidas:

```bash
./test-config.sh [ultra-estable|balanceado|ultra-rapido]
```

## Optimización de Latencia

El sistema está configurado para latencia de aproximadamente 2-3 segundos. Para ajustar:

### Reducir Latencia (Mayor riesgo de cortes)

- Reducir `seg_duration` a 0.75 segundos
- Reducir `bufferingGoal` a 3 segundos
- Reducir `window_size` a 3-4

### Aumentar Estabilidad (Mayor latencia)

- Aumentar `seg_duration` a 1.5 segundos
- Aumentar `bufferingGoal` a 5-6 segundos
- Aumentar `window_size` a 6-7

Consultar `docs/GUIA_AJUSTE.md` para información detallada.

## Solución de Problemas

### El video no se reproduce

1. Verificar logs del backend:
```bash
sudo docker compose logs -f backend
```

2. Verificar que se generan segmentos:
```bash
ls -lht www/html/segmentos/
```

3. Revisar consola del navegador (F12)

### Latencia muy alta

1. Ajustar parámetros de FFmpeg (reducir window_size)
2. Ajustar configuración de Shaka Player (reducir bufferingGoal)
3. Verificar capacidad de red

### Cortes frecuentes

1. Aumentar `bufferingGoal` en video-player.js
2. Aumentar `window_size` en backend/main.py
3. Verificar estabilidad de la cámara
4. Revisar uso de CPU/memoria

### Puerto en uso

Si el puerto 8081 está ocupado, editar `docker-compose.yml`:

```yaml
ports:
  - "8082:80"  # Cambiar 8081 por otro puerto
```

## Comandos Útiles

### Ver logs en tiempo real

```bash
# Backend
sudo docker compose logs -f backend

# NGINX
sudo docker compose logs -f nginx

# Ambos
sudo docker compose logs -f
```

### Detener servicios

```bash
sudo docker compose stop
```

### Eliminar contenedores y volúmenes

```bash
sudo docker compose down -v
```

### Reiniciar servicios

```bash
sudo docker compose restart
```

### Verificar uso de recursos

```bash
sudo docker stats
```

## Tecnologías Utilizadas

### Backend
- Python 3.11
- FastAPI 0.109.0
- Uvicorn 0.27.0
- FFmpeg 7.1

### Frontend
- HTML5
- CSS3 (Custom Properties)
- JavaScript (ES6 Modules)
- Shaka Player 4.7.9

### Infraestructura
- Docker
- Docker Compose
- NGINX Alpine

### Protocolos y Estándares
- DASH (ISO/IEC 23009-1)
- H.264/AVC (ISO/IEC 14496-10)
- HTTP/1.1
- WebSockets (control)

## Referencias Técnicas

### Especificaciones

- **DASH**: ISO/IEC 23009-1:2014
- **H.264**: ISO/IEC 14496-10:2014
- **MP4**: ISO/IEC 14496-12:2015

### Documentación

- FFmpeg DASH Documentation: https://ffmpeg.org/ffmpeg-formats.html#dash-2
- Shaka Player API: https://shaka-player-demo.appspot.com/docs/api/index.html
- NGINX Documentation: https://nginx.org/en/docs/

### Herramientas de Desarrollo

- Docker Documentation: https://docs.docker.com/
- FastAPI Documentation: https://fastapi.tiangolo.com/

## Consideraciones de Desempeño

### Latencia vs Estabilidad

El sistema ofrece tres modos de operación:

1. **Ultra Rápido**: Latencia ~1.5-2s, posibles cortes
2. **Balanceado**: Latencia ~2-2.5s, estabilidad media (configuración actual)
3. **Ultra Estable**: Latencia ~3-3.5s, sin cortes

### Uso de Recursos

Consumo aproximado por contenedor:

- **Backend**: 100-200 MB RAM, 30-50% CPU
- **NGINX**: 20-50 MB RAM, 5-10% CPU
- **FFmpeg**: 150-300 MB RAM, 50-100% CPU

## Limitaciones Conocidas

1. Requiere dispositivo v4l2 compatible
2. Latencia mínima de ~1.5 segundos (limitación de DASH)
3. Sin soporte para múltiples calidades simultáneas (ABR limitado)
4. Captura de una sola cámara
5. Sin autenticación en la API

## Trabajo Futuro

- Implementación de múltiples bitrates (ABR completo)
- Soporte para múltiples cámaras
- Grabación de sesiones
- Autenticación y autorización
- Métricas y analytics
- Soporte para códec AV1
- Implementación de WebRTC para ultra-baja latencia

## Licencia

Este proyecto es parte de material académico de la Universidad de Cuenca.

## Contacto

**Dario Portilla**  
Ingeniería en Telecomunicaciones  
Universidad de Cuenca

---

**Última actualización**: Enero 2026  
**Versión del documento**: 1.0
