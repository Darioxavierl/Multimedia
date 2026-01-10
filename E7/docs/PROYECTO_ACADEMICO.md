# Información Académica del Proyecto

## Datos del Estudiante

**Nombre**: Dario Portilla  
**Institución**: Universidad de Cuenca  
**Facultad**: Ingeniería  
**Carrera**: Ingeniería en Telecomunicaciones

## Datos del Curso

**Asignatura**: Comunicaciones Multimedia  
**Capítulo**: 7 - Streaming de Video Adaptativo  
**Periodo Académico**: 2026

## Descripción del Proyecto

### Título
Sistema de Streaming Adaptativo de Video en Tiempo Real con DASH

### Objetivo General
Implementar un sistema completo de streaming de video adaptativo de baja latencia utilizando tecnologías modernas y estándares abiertos (DASH), demostrando los conceptos aprendidos en el Capítulo 7 del curso de Comunicaciones Multimedia.

### Objetivos Específicos

1. **Captura y Codificación**
   - Capturar video en tiempo real desde dispositivo de entrada
   - Codificar video usando estándar H.264 optimizado para streaming
   - Generar segmentos DASH con duración configurable

2. **Servidor de Streaming**
   - Configurar servidor NGINX para servir contenido DASH
   - Implementar CORS para acceso cross-origin
   - Optimizar configuración para baja latencia

3. **Control y API**
   - Desarrollar API REST para control de transmisión
   - Gestionar proceso de codificación (inicio, detención, estado)
   - Proporcionar logs y métricas en tiempo real

4. **Reproducción Adaptativa**
   - Integrar reproductor Shaka Player
   - Configurar buffer y latencia óptimos
   - Implementar recuperación automática ante errores

5. **Interfaz de Usuario**
   - Diseñar interfaz responsiva y profesional
   - Implementar sistema de temas personalizables
   - Mostrar métricas de transmisión en tiempo real

6. **Optimización y Documentación**
   - Balancear latencia vs estabilidad
   - Crear configuraciones predefinidas
   - Documentar sistema de forma integral y profesional

## Tecnologías Aplicadas

### Streaming y Multimedia
- **DASH (Dynamic Adaptive Streaming over HTTP)**: Protocolo de streaming adaptativo
- **H.264**: Códec de video para compresión
- **FFmpeg**: Suite multimedia para captura y codificación
- **MPD (Media Presentation Description)**: Manifiesto DASH

### Backend y APIs
- **Python 3.11**: Lenguaje de programación
- **FastAPI**: Framework web moderno para APIs REST
- **Subprocess Management**: Control de procesos FFmpeg

### Frontend
- **HTML5**: Estructura de la aplicación web
- **CSS3**: Estilos y sistema de temas con Custom Properties
- **JavaScript ES6**: Lógica de aplicación modular
- **Shaka Player**: Reproductor de video adaptativo

### Infraestructura
- **Docker**: Contenedorización de servicios
- **Docker Compose**: Orquestación multi-contenedor
- **NGINX**: Servidor web y proxy reverso

### Control de Versiones y Desarrollo
- **Bash**: Scripts de automatización
- **Git**: Control de versiones (implícito)

## Conceptos del Capítulo 7 Implementados

### 1. Streaming Adaptativo
- Implementación de DASH como protocolo de streaming adaptativo
- Generación de múltiples segmentos con duración configurable
- Manifiesto MPD con información de representaciones

### 2. Compresión de Video
- Uso de H.264 con configuración optimizada
- GOP (Group of Pictures) configurable
- Control de bitrate (CBR) para streaming consistente

### 3. Latencia en Streaming
- Configuración de latencia objetivo (target_latency)
- Balance entre latencia y estabilidad
- Preset ultrafast y tune zerolatency en FFmpeg

### 4. Buffering
- Buffer de cliente (bufferingGoal) configurable
- Buffer de servidor (window_size) para disponibilidad
- Recuperación automática ante rebuffering

### 5. Calidad de Servicio (QoS)
- Bitrate adaptativo según condiciones
- Reintentos automáticos ante fallos
- Monitoreo de métricas en tiempo real

### 6. Arquitectura Cliente-Servidor
- Separación clara de responsabilidades
- API REST para comunicación
- Proxy reverso para enrutamiento

## Resultados Obtenidos

### Métricas de Rendimiento

| Métrica | Valor Obtenido | Objetivo | Estado |
|---------|----------------|----------|--------|
| Latencia | 2-2.5 segundos | < 3 segundos | Cumplido |
| Estabilidad | < 1 corte/30min | Reproducción estable | Cumplido |
| CPU (Backend) | 40-50% | < 80% | Cumplido |
| RAM (Backend) | ~180MB | < 512MB | Cumplido |
| Tiempo de inicio | ~4 segundos | < 10 segundos | Cumplido |

### Funcionalidades Implementadas

- [x] Captura de video desde cámara web
- [x] Codificación H.264 en tiempo real
- [x] Generación de segmentos DASH
- [x] Servidor NGINX con CORS
- [x] API REST para control
- [x] Reproducción adaptativa con Shaka Player
- [x] Sistema de temas (4 temas incluidos)
- [x] Configuraciones predefinidas (3 perfiles)
- [x] Scripts de automatización
- [x] Documentación integral

### Configuraciones Desarrolladas

1. **Ultra Rápida**: Latencia 1.5-2s, para demostraciones de baja latencia
2. **Balanceada**: Latencia 2-2.5s, uso general y producción
3. **Ultra Estable**: Latencia 3-3.5s, para redes inestables

## Desafíos y Soluciones

### Desafío 1: Alta Latencia Inicial (7 segundos)
**Problema**: La latencia inicial era de 7 segundos, muy alta para streaming en vivo.

**Análisis**:
- `seg_duration` de 2s era demasiado largo
- `window_size` de 10 generaba mucho overhead
- `bufferingGoal` de 6s añadía latencia innecesaria

**Solución**:
- Reducir `seg_duration` a 1s
- Ajustar `window_size` a 5
- Configurar `bufferingGoal` en 4s
- Resultado: Latencia reducida a 2-2.5s

### Desafío 2: Cortes Frecuentes
**Problema**: El video se cortaba frecuentemente durante la reproducción.

**Análisis**:
- Buffer insuficiente en cliente y servidor
- Race condition entre escritura y lectura de segmentos
- `window_size` muy pequeño

**Solución**:
- Aumentar `window_size` de 3 a 5
- Añadir `extra_window_size` de 2
- Aumentar `bufferingGoal` de 3s a 4s
- Implementar `write_prft` para mejor sincronización
- Resultado: Estabilidad mejorada significativamente

### Desafío 3: Manifiesto MPD No Disponible
**Problema**: Shaka Player intentaba cargar el MPD antes de que FFmpeg lo generara.

**Análisis**:
- FFmpeg tarda ~3-4 segundos en generar primer segmento
- Reproductor fallaba inmediatamente

**Solución**:
- Implementar función `waitForMPD` con polling cada 500ms
- Timeout de 15 segundos antes de error
- Espera adicional de 4s después de detectar MPD
- Resultado: Carga confiable del manifiesto

### Desafío 4: Proceso FFmpeg Zombie
**Problema**: Los logs de FFmpeg no se capturaban, proceso quedaba zombie.

**Análisis**:
- stderr de FFmpeg no se procesaba
- No había thread dedicado para logs

**Solución**:
- Implementar thread para captura de stderr
- Almacenar logs en lista circular (últimos 50)
- Endpoint `/api/stream/logs` para consulta
- Resultado: Debugging mejorado, proceso limpio

## Aprendizajes Clave

### Técnicos

1. **Balance Latencia-Estabilidad**: No se puede optimizar ambos simultáneamente; se debe encontrar el punto óptimo según el caso de uso.

2. **Importancia del Buffer**: El buffer es crítico en ambos lados (servidor con `window_size`, cliente con `bufferingGoal`).

3. **CBR vs VBR**: Para streaming, CBR produce segmentos más predecibles y estables que VBR/CQP.

4. **Configuración de FFmpeg**: Los parámetros `preset` y `tune` tienen impacto directo en latencia y CPU.

5. **Shaka Player**: La configuración de buffer y reintentos es tan importante como los parámetros de FFmpeg.

### Arquitectura

1. **Separación de Responsabilidades**: Dividir en microservicios (backend, nginx) facilita mantenimiento y escalabilidad.

2. **Volúmenes Compartidos**: Docker volumes permiten compartir segmentos entre contenedores eficientemente.

3. **API REST**: Provee interfaz clara y estándar para control de servicios.

4. **CSS Variables**: Sistema de temas centralizado facilita personalización sin tocar lógica.

### Desarrollo

1. **Documentación Progresiva**: Documentar mientras se desarrolla evita olvidos y mejora claridad.

2. **Configuraciones Predefinidas**: Facilitan uso y permiten demostrar diferentes escenarios.

3. **Scripts de Automatización**: Reducen errores y aceleran desarrollo.

4. **Testing Iterativo**: Ajustar parámetros gradualmente con validación en cada paso.

## Estructura de Documentación

El proyecto incluye documentación integral distribuida en:

| Documento | Propósito | Líneas | Tamaño |
|-----------|-----------|--------|--------|
| `README.md` | Documento principal y guía rápida | 535 | 13KB |
| `docs/README.md` | Documentación técnica completa | 439 | 11KB |
| `docs/CONFIGURACION.md` | Guía de configuración y ajuste | 883 | 17KB |
| `docs/TEMAS.md` | Sistema de temas CSS | 889 | 20KB |
| `docs/INDEX.md` | Índice y navegación | 236 | 9KB |
| **Total** | | **2,982** | **70KB** |

### Características de la Documentación

- **Sin emojis**: Formato profesional para contexto académico
- **Integral**: Cubre todos los aspectos del sistema
- **Navegable**: Índice y enlaces internos
- **Práctica**: Ejemplos de código y comandos reales
- **Técnica**: Referencias a estándares y documentación oficial

## Archivos del Proyecto

```
Total de archivos: ~50
Líneas de código: ~2,500
Líneas de documentación: ~3,000
Tamaño total: ~150KB (sin node_modules ni builds)
```

### Distribución por Tipo

| Tipo | Cantidad | Propósito |
|------|----------|-----------|
| Python | 1 | Backend API |
| JavaScript | 4 | Frontend modular |
| HTML | 1 | Interfaz de usuario |
| CSS | 2 | Estilos y temas |
| Docker | 2 | Dockerfiles |
| YAML | 1 | Docker Compose |
| NGINX Conf | 2 | Configuración servidor |
| Markdown | 5 | Documentación |
| Bash | 3 | Scripts de utilidad |
| Config | 4 | Configuraciones predefinidas |

## Posibles Extensiones Futuras

### Funcionalidades

1. **Multi-bitrate**: Generar múltiples calidades para ABR real
2. **Autenticación**: Sistema de usuarios y control de acceso
3. **Grabación**: Guardar transmisiones en disco
4. **Estadísticas**: Dashboard con métricas históricas
5. **WebRTC**: Comparación con streaming P2P

### Optimizaciones

1. **Hardware Encoding**: Usar GPU para codificación (NVENC, VAAPI)
2. **CDN Integration**: Distribución mediante CDN
3. **Load Balancing**: Múltiples instancias de FFmpeg
4. **Adaptive Chunking**: Segmentos de duración variable
5. **H.265/AV1**: Códecs más eficientes

### Mejoras de UX

1. **Selector de Cámara**: Elegir dispositivo de entrada
2. **Controles Avanzados**: Ajustar parámetros desde UI
3. **Visualizaciones**: Gráficos de bitrate, buffer, fps
4. **Chat**: Integración de chat en vivo
5. **Mobile**: Aplicación móvil nativa

## Conclusiones

Este proyecto ha permitido aplicar de manera práctica los conceptos del Capítulo 7 de Comunicaciones Multimedia, específicamente:

1. **Streaming Adaptativo**: Implementación completa de DASH con todas sus componentes
2. **Optimización de Latencia**: Balance exitoso entre latencia y estabilidad
3. **Arquitectura de Sistemas**: Diseño modular y escalable
4. **Tecnologías Modernas**: Uso de herramientas actuales de la industria
5. **Documentación Profesional**: Creación de documentación integral

El sistema cumple con los objetivos propuestos y demuestra competencia en:
- Configuración de codificadores de video
- Implementación de protocolos de streaming
- Desarrollo de APIs REST
- Containerización con Docker
- Optimización de rendimiento multimedia

## Referencias del Proyecto

### Estándares y Especificaciones
- DASH: ISO/IEC 23009-1
- H.264: ISO/IEC 14496-10
- HTTP/1.1: RFC 2616

### Documentación Técnica Consultada
- FFmpeg Documentation: https://ffmpeg.org/documentation.html
- Shaka Player Documentation: https://shaka-player-demo.appspot.com/docs/
- DASH Industry Forum: https://dashif.org/
- FastAPI Documentation: https://fastapi.tiangolo.com/

### Recursos de Aprendizaje
- Video Encoding Best Practices
- Low-Latency Streaming Techniques
- Docker Multi-Container Applications
- RESTful API Design Principles

---

**Proyecto**: Sistema de Streaming Adaptativo DASH  
**Curso**: Comunicaciones Multimedia - Capítulo 7  
**Estudiante**: Dario Portilla  
**Institución**: Universidad de Cuenca  
**Carrera**: Ingeniería en Telecomunicaciones  
**Año**: 2026

---

## Declaración de Autoría

Este proyecto ha sido desarrollado completamente por el estudiante Dario Portilla como parte de las actividades del curso de Comunicaciones Multimedia, Capítulo 7, de la carrera de Ingeniería en Telecomunicaciones de la Universidad de Cuenca.

Todos los componentes, desde la arquitectura hasta la implementación y documentación, son producto del trabajo del estudiante, aplicando los conocimientos adquiridos en el curso y mediante investigación adicional de las tecnologías utilizadas.

---

**Fecha de finalización**: Enero 2026  
**Versión**: 1.0
