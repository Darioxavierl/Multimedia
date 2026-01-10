# Sistema de Streaming Adaptativo DASH

**Capítulo 7: Comunicaciones Multimedia**  
**Ingeniería en Telecomunicaciones**  
**Universidad de Cuenca**

**Autor**: Dario Portilla

## Descripción

Este proyecto implementa un sistema de streaming de video adaptativo de baja latencia usando DASH (Dynamic Adaptive Streaming over HTTP). El sistema captura video en tiempo real desde una cámara web, lo codifica con FFmpeg, lo sirve mediante NGINX, y lo reproduce con Shaka Player en el navegador.

### Características Principales

- Streaming en vivo con latencia de 2-3 segundos
- Arquitectura basada en Docker con múltiples contenedores
- Backend API REST para control de transmisión
- Sistema de temas personalizables mediante CSS Variables
- Configuraciones predefinidas para diferentes escenarios
- Documentación integral y profesional


## Estructura del Proyecto

```
E7/
├── docker-compose.yml                # Orquestación de contenedores
├── backend/
│   ├── Dockerfile                   # Imagen Docker para API
│   ├── main.py                      # API REST con FastAPI
│   └── requirements.txt             # Dependencias Python
├── nginx/
│   ├── nginx.conf                   # Configuración principal NGINX
│   └── default.conf                 # Virtual host y CORS
├── www/
│   └── html/
│       ├── index.html               # Interfaz de usuario
│       ├── css/
│       │   ├── variables.css        # Variables CSS y temas
│       │   └── styles.css           # Estilos de la aplicación
│       ├── js/
│       │   ├── main.js              # Punto de entrada
│       │   ├── video-player.js      # Control Shaka Player
│       │   ├── stream-controller.js # API cliente para backend
│       │   └── ui-controller.js     # Gestión de UI
│       └── segmentos/               # Segmentos DASH (volumen compartido)
├── configs/                          # Configuraciones predefinidas
│   ├── ffmpeg-ultra-estable.txt
│   ├── ffmpeg-ultra-rapido.txt
│   ├── video-player-ultra-estable.js
│   └── video-player-ultra-rapido.js
├── docs/                             # Documentación integral
│   ├── README.md                    # Documentación técnica completa
│   ├── CONFIGURACION.md             # Guía de configuración y ajuste
│   └── TEMAS.md                     # Sistema de temas CSS
├── rebuild.sh                        # Script para reconstruir backend
├── change-theme.sh                   # Script para cambiar tema
└── test-config.sh                    # Script para probar configuraciones
```


## Tecnologías Utilizadas

| Componente | Tecnología | Versión | Propósito |
|------------|-----------|---------|-----------|
| Contenedores | Docker Compose | - | Orquestación de servicios |
| Backend | Python | 3.11 | API REST |
| Framework | FastAPI | 0.109.0 | Endpoints de control |
| Codificador | FFmpeg | 7.1 | Captura y codificación |
| Servidor Web | NGINX | Alpine | Servir contenido y proxy |
| Reproductor | Shaka Player | 4.7.9 | Reproducción adaptativa |
| Frontend | JavaScript | ES6 | Lógica de interfaz |
| Estilos | CSS3 | - | Variables y temas |

## Inicio Rápido

### Requisitos Previos

- Docker y Docker Compose instalados
- Cámara web conectada en `/dev/video0`
- Puerto 8081 disponible

### Instalación y Ejecución

1. **Clonar o ubicarse en el directorio del proyecto**
   ```bash
   cd /home/dariox/multimedia/E7
   ```

2. **Construir e iniciar contenedores**
   ```bash
   sudo docker compose up -d --build
   ```

3. **Verificar que los servicios están activos**
   ```bash
   sudo docker compose ps
   ```
   
   Servicios esperados:
   - `dash-backend`: API en puerto 8000
   - `nginx-dash-server`: Servidor web en puerto 8081

4. **Acceder a la aplicación**
   
   Abrir navegador en: `http://localhost:8081`

5. **Iniciar transmisión**
   
   Presionar el botón "Iniciar Transmisión" en la interfaz

### Detener el Sistema

```bash
sudo docker compose down
```

### Ver Logs

```bash
# Backend
sudo docker compose logs -f backend

# NGINX
sudo docker compose logs -f nginx

# Todos los servicios
sudo docker compose logs -f
```


## Arquitectura del Sistema

### Componentes

1. **Frontend (HTML/CSS/JavaScript)**
   - Interfaz de usuario responsiva
   - Reproductor Shaka Player integrado
   - Sistema de temas personalizables
   - Control de transmisión

2. **NGINX (Servidor Web)**
   - Sirve archivos estáticos
   - Proxy reverso para API backend
   - Configuración CORS para DASH
   - Servir segmentos de video

3. **Backend (Python/FastAPI)**
   - API REST para control de transmisión
   - Gestión de proceso FFmpeg
   - Endpoints de estado y logs
   - Captura de stderr de FFmpeg

4. **FFmpeg (Codificador)**
   - Captura desde `/dev/video0`
   - Codificación H.264 con preset ultrafast
   - Generación de segmentos DASH
   - Optimizado para baja latencia

### Flujo de Datos

```
[Cámara] → [FFmpeg] → [Segmentos DASH] → [NGINX] → [Navegador/Shaka]
              ↑                                         ↓
         [Backend API] ←──────────── [Control UI] ←────┘
```

1. Usuario presiona "Iniciar Transmisión"
2. Frontend envía POST a `/api/stream/start`
3. Backend inicia proceso FFmpeg
4. FFmpeg captura video y genera segmentos DASH en `/segmentos/`
5. NGINX sirve manifiesto MPD y segmentos
6. Shaka Player solicita y reproduce segmentos adaptativamente

## API Backend

### Endpoints Disponibles

#### `POST /api/stream/start`
Inicia el proceso de streaming FFmpeg.

**Response**:
```json
{
  "status": "started",
  "message": "Transmisión iniciada correctamente"
}
```

#### `POST /api/stream/stop`
Detiene el proceso de streaming.

**Response**:
```json
{
  "status": "stopped",
  "message": "Transmisión detenida correctamente"
}
```

#### `GET /api/stream/status`
Obtiene el estado actual de la transmisión.

**Response**:
```json
{
  "status": "running",
  "pid": 12345
}
```

#### `GET /api/stream/logs`
Obtiene los últimos 50 logs de FFmpeg (stderr).

**Response**:
```json
{
  "logs": ["frame=  123 fps= 25 ...", "..."]
}
```

## Configuración y Ajuste

### Configuraciones Predefinidas

El sistema incluye tres configuraciones predefinidas en el directorio `configs/`:

1. **Ultra Rápida**: Latencia 1.5-2s, estabilidad baja
2. **Balanceada** (actual): Latencia 2-2.5s, estabilidad media
3. **Ultra Estable**: Latencia 3-3.5s, estabilidad alta

### Uso de Configuraciones

```bash
# Ver información de una configuración
./test-config.sh ultra-estable

# Aplicar configuración manualmente copiando parámetros desde configs/
```

### Parámetros Clave

#### FFmpeg (backend/main.py)

- `seg_duration`: Duración de segmentos (1s balanceado)
- `window_size`: Segmentos disponibles en MPD (5 balanceado)
- `extra_window_size`: Segmentos extra de respaldo (2 balanceado)
- `target_latency`: Latencia objetivo (2s balanceado)
- `preset`: Velocidad de codificación (ultrafast)
- `tune`: Optimización (zerolatency)

#### Shaka Player (www/html/js/video-player.js)

- `bufferingGoal`: Buffer objetivo en segundos (4s balanceado)
- `rebufferingGoal`: Buffer mínimo antes de rebuffering (2s)
- `lowLatencyMode`: Modo de baja latencia (true)
- `stallThreshold`: Umbral de detección de paradas (1s)

### Documentación Detallada

Consultar `docs/CONFIGURACION.md` para información completa sobre:
- Todos los parámetros disponibles
- Impacto de cada parámetro
- Procedimiento de ajuste
- Solución de problemas de cortes
- Optimización de latencia

## Sistema de Temas

### Temas Disponibles

1. **Default** (Púrpura): Tema por defecto con gradiente púrpura
2. **Green** (Verde): Gradiente verde esmeralda
3. **Red** (Rojo): Gradiente rojo intenso
4. **Dark** (Oscuro): Esquema muy oscuro para uso nocturno

### Cambiar Tema

```bash
# Usar script
./change-theme.sh green
./change-theme.sh red
./change-theme.sh dark
./change-theme.sh default

# Manual: editar www/html/index.html
<html lang="es" data-theme="green">
```

Recargar página con `Ctrl+F5` para ver cambios.

### Personalización

El sistema usa CSS Variables definidas en `www/html/css/variables.css`.

Variables principales:
- `--color-primary`: Color principal
- `--background-primary`: Fondo principal
- `--text-primary`: Texto principal
- `--gradient-background`: Gradiente de encabezado

Consultar `docs/TEMAS.md` para:
- Lista completa de variables
- Guía de creación de temas personalizados
- Mejores prácticas de diseño

## Scripts Útiles

### rebuild.sh
Reconstruye el contenedor del backend después de cambios en código.

```bash
./rebuild.sh
```

### change-theme.sh
Cambia el tema de la interfaz.

```bash
./change-theme.sh [default|green|red|dark]
```

### test-config.sh
Muestra información sobre configuraciones predefinidas.

```bash
./test-config.sh [ultra-estable|balanceado|ultra-rapido]
```

## Resolución de Problemas

### El video no se reproduce

1. Verificar que la cámara está conectada en `/dev/video0`
2. Revisar logs del backend: `sudo docker compose logs -f backend`
3. Verificar que FFmpeg inició correctamente
4. Comprobar que NGINX puede acceder a `/segmentos/`

### Error: "No se encontró el manifiesto MPD"

**Causa**: El reproductor intenta cargar antes de que FFmpeg genere el primer segmento.

**Solución**: El sistema espera automáticamente 15 segundos. Si persiste:
- Aumentar timeout en `www/html/js/main.js` (waitForMPD function)
- Verificar permisos en directorio `/segmentos/`

### Cortes frecuentes durante reproducción

**Causas posibles**:
- Buffer insuficiente
- Ventana de segmentos muy pequeña
- Red o CPU sobrecargados

**Soluciones**:
1. Aumentar `window_size` en `backend/main.py`
2. Aumentar `bufferingGoal` en `video-player.js`
3. Usar configuración "ultra-estable"

Consultar `docs/CONFIGURACION.md` sección "Solución de Cortes".

### Latencia demasiado alta

**Solución**:
1. Reducir `seg_duration` en `backend/main.py`
2. Reducir `bufferingGoal` en `video-player.js`
3. Usar configuración "ultra-rapida"

**Nota**: Menor latencia = Mayor riesgo de cortes. Encontrar balance óptimo.

### Puerto 8081 en uso

**Solución**: Cambiar puerto en `docker-compose.yml`:

```yaml
ports:
  - "8082:80"  # Cambiar 8081 a otro puerto
```

Luego: `sudo docker compose up -d --build`

## Monitoreo del Sistema

### Métricas de Contenedores

```bash
# CPU, RAM, red de todos los contenedores
sudo docker stats

# Estadísticas de un contenedor específico
sudo docker stats dash-backend
```

### Verificar Generación de Segmentos

```bash
# Ver segmentos en tiempo real
watch -n 1 'ls -lht www/html/segmentos/ | head -20'

# Contar segmentos disponibles
ls www/html/segmentos/*.m4s | wc -l
```

### Métricas del Reproductor

Disponibles en la interfaz:
- **Estado**: transmitiendo/detenido
- **Calidad**: Resolución y bitrate actual
- **Buffer**: Segundos de video en buffer

## Documentación Adicional

### Documentos Disponibles

- `docs/README.md`: Documentación técnica completa y detallada
- `docs/CONFIGURACION.md`: Guía integral de configuración y ajuste
- `docs/TEMAS.md`: Sistema de temas y personalización CSS

### Referencias Técnicas

- **FFmpeg DASH**: https://ffmpeg.org/ffmpeg-formats.html#dash-2
- **Shaka Player**: https://shaka-player-demo.appspot.com/docs/api/
- **DASH Spec**: https://dashif.org/
- **FastAPI**: https://fastapi.tiangolo.com/

## Contribuciones y Desarrollo

### Modificar Backend

1. Editar `backend/main.py`
2. Reconstruir contenedor: `./rebuild.sh`
3. Verificar logs: `sudo docker compose logs -f backend`

### Modificar Frontend

1. Editar archivos en `www/html/`
2. Recargar página con `Ctrl+F5` (no requiere rebuild)

### Agregar Nuevo Tema

1. Editar `www/html/css/variables.css`
2. Agregar selector `[data-theme="mi-tema"]`
3. Definir variables de color
4. Actualizar `change-theme.sh`

Consultar `docs/TEMAS.md` para guía completa.

### Crear Nueva Configuración

1. Crear archivos en `configs/`:
   - `ffmpeg-mi-config.txt`
   - `video-player-mi-config.js`
2. Documentar parámetros y casos de uso
3. Actualizar `test-config.sh`

## Información del Proyecto

**Curso**: Comunicaciones Multimedia - Capítulo 7  
**Programa**: Ingeniería en Telecomunicaciones  
**Institución**: Universidad de Cuenca  
**Autor**: Dario Portilla  
**Año**: 2026

## Licencia

Este proyecto es material académico desarrollado para fines educativos en el marco del curso de Comunicaciones Multimedia de la Universidad de Cuenca.

---

Para consultas, soporte o información adicional, referirse a la documentación en el directorio `docs/`.

3. Backend ejecuta FFmpeg con el comando:
   ```bash
   ffmpeg -y -f v4l2 -video_size 1280x720 -framerate 25 -i /dev/video0 \
     -vcodec libx264 -keyint_min 1 -g 12 -b:v 1000k -pix_fmt yuv420p -map 0:v \
     -f dash -seg_duration 2 -use_template 1 -use_timeline 0 \
     -init_seg_name init-\$RepresentationID\$.mp4 \
     -profile:v baseline \
     -media_seg_name video-\$RepresentationID\$-\$Number\$.mp4 \
     -remove_at_exit 1 -window_size 10 \
     /var/www/html/segmentos/video0.mpd
   ```
4. FFmpeg genera segmentos en `/var/www/html/segmentos/` (volumen compartido)
5. Frontend carga el archivo MPD en Shaka Player
6. Shaka Player reproduce el video adaptativo

### Volúmenes compartidos

El directorio `www/html/segmentos/` es compartido entre:
- **Backend**: Escribe los segmentos de video (FFmpeg)
- **NGINX**: Sirve los segmentos al reproductor

## Endpoints de la API

- `GET /` - Información del servicio
- `POST /api/stream/start` - Iniciar transmisión FFmpeg
- `POST /api/stream/stop` - Detener transmisión FFmpeg
- `GET /api/stream/status` - Estado de la transmisión

## Requisitos

- Docker y Docker Compose
- Cámara web en `/dev/video0` (o modificar en `docker-compose.yml`)
- Puertos 8000 y 8081 disponibles

## Troubleshooting

### Error: "Cannot access /dev/video0"

Verifica que tu usuario tenga permisos:
```bash
ls -l /dev/video0
sudo usermod -aG video $USER
```

### Error: "Port already allocated"

Cambia los puertos en `docker-compose.yml` si están ocupados.

### Los segmentos no se generan

Verifica los logs del backend:
```bash
sudo docker compose logs backend
```

##  Características

-  Streaming adaptativo DASH
-  Reproductor Shaka Player integrado
-  Control de transmisión desde interfaz web
-  Backend REST API en Python
-  Arquitectura modular (CSS, JS separados)
-  Volúmenes compartidos entre contenedores
-  Proxy reverso con NGINX
-  Solo 2 botones: Iniciar/Detener
