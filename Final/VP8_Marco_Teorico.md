# Codec VP8: Marco Teórico

## 1. Introducción

VP8 es un codec de compresión de video de código abierto desarrollado por On2 Technologies y adquirido por Google en 2010. Fue liberado bajo una licencia libre de regalías BSD, convirtiéndose en una alternativa abierta a codecs propietarios como H.264. VP8 es parte del proyecto WebM junto con el codec de audio Vorbis y el contenedor Matroska.

## 2. Características Principales

### 2.1 Características Técnicas

- **Tipo de compresión**: Lossy (con pérdida)
- **Algoritmo**: Basado en DCT (Discrete Cosine Transform)
- **Predicción**: Intra-frame e inter-frame
- **Formato de color**: Principalmente YUV 4:2:0
- **Profundidad de bits**: 8 bits por canal
- **Resoluciones soportadas**: Hasta 16384×16384 píxeles
- **Frame rate**: Sin límite teórico

### 2.2 Ventajas

1. **Código abierto**: Sin costos de licencia ni regalías
2. **Buena calidad**: Comparable a H.264 baseline/main profile
3. **Soporte amplio**: Navegadores modernos y plataformas web
4. **Optimización web**: Diseñado para streaming en internet
5. **Formato contenedor**: WebM (.webm) optimizado para web

### 2.3 Limitaciones

1. **Eficiencia**: Menor que H.264 High Profile o codecs modernos (H.265, VP9, AV1)
2. **Hardware**: Menos soporte de aceleración por hardware que H.264
3. **Complejidad**: Mayor costo computacional de codificación que H.264 en algunos casos
4. **Adopción**: Menor que H.264 en dispositivos móviles y sistemas legacy

## 3. Principios de Operación

### 3.1 Estructura de Bloques

VP8 utiliza una estructura jerárquica de bloques:

- **Macrobloques**: Unidad básica de 16×16 píxeles
- **Sub-bloques**: Divisiones de 4×4 píxeles dentro de macroblocks
- **Particiones**: Macrobloques pueden dividirse en particiones más pequeñas para mejor predicción

### 3.2 Tipos de Frames

1. **Key frames (I-frames)**: Frames de referencia independientes, codificados completamente
2. **Inter frames (P-frames)**: Frames predictivos que referencian frames anteriores
3. **Golden frames**: Frames de referencia especiales para predicción a largo plazo
4. **AltRef frames**: Frames alternativos de referencia

### 3.3 Predicción Intra-frame

VP8 soporta varios modos de predicción intra:

- **DC Prediction**: Promedio de píxeles vecinos
- **Vertical Prediction**: Extrapolación vertical
- **Horizontal Prediction**: Extrapolación horizontal
- **TrueMotion**: Predicción basada en gradientes
- 9 modos adicionales para bloques 4×4

### 3.4 Predicción Inter-frame

- **Motion Estimation**: Búsqueda de bloques similares en frames de referencia
- **Motion Vectors**: Vectores de 1/4 de píxel de precisión
- **Multi-reference**: Puede usar hasta 3 frames de referencia (last, golden, altref)
- **Motion Compensation**: Aplicación de vectores de movimiento para predicción

### 3.5 Transformación y Cuantización

1. **DCT 4×4**: Discrete Cosine Transform aplicada a bloques 4×4
2. **WHT**: Walsh-Hadamard Transform para coeficientes DC en modos específicos
3. **Cuantización**: Proceso controlado por parámetro QP (Quantization Parameter)
4. **Rango QP**: 0-63 (menor valor = mayor calidad)

### 3.6 Codificación Entrópica

- **Boolean Arithmetic Coding**: Sistema de codificación aritmética binaria
- **Context-based**: Usa contexto de bloques vecinos para mejorar compresión
- **Particiones de datos**: Coeficientes, modos de predicción y motion vectors se codifican separadamente

### 3.7 Loop Filtering

- **Deblocking Filter**: Filtro adaptativo para reducir artefactos de bloque
- **Aplicación**: En los bordes de macroblocks y sub-bloques
- **Control**: Ajustable mediante parámetros de fuerza y umbral

## 4. Control de Tasa (Rate Control)

VP8 ofrece varios modos de control de tasa:

### 4.1 Constant Bitrate (CBR)
- Mantiene bitrate constante objetivo
- Ideal para streaming en tiempo real
- Calidad variable según complejidad de escena

### 4.2 Variable Bitrate (VBR)
- Bitrate varía según complejidad del contenido
- Mejor calidad general para mismo tamaño de archivo
- Modo por defecto en muchas implementaciones

### 4.3 Constrained Quality (CQ)
- Calidad objetivo constante con límite de bitrate
- Balance entre calidad y tamaño de archivo
- Usa parámetro CRF (Constant Rate Factor)

### 4.4 Constant Quality (CQ)
- Calidad constante sin restricción de bitrate
- Máxima calidad para almacenamiento
- Tamaño de archivo variable

## 5. VP8 en FFmpeg

### 5.1 Codec Library

FFmpeg utiliza la biblioteca **libvpx** para codificación y decodificación VP8. Esta es la implementación de referencia oficial de Google.

### 5.2 Comando Básico

```bash
ffmpeg -i input.mp4 -c:v libvpx -b:v 1M output.webm
```

### 5.3 Sintaxis General

```bash
ffmpeg [opciones_entrada] -i input_file [opciones_video] [opciones_audio] output_file
```

## 6. Parámetros Principales de libvpx en FFmpeg

### 6.1 Control de Calidad y Bitrate

| Parámetro | Descripción | Valores | Ejemplo |
|-----------|-------------|---------|---------|
| `-b:v` | Bitrate objetivo del video | Número + unidad (k, M) | `-b:v 1M` |
| `-minrate` | Bitrate mínimo | Número + unidad | `-minrate 500k` |
| `-maxrate` | Bitrate máximo | Número + unidad | `-maxrate 2M` |
| `-bufsize` | Tamaño del buffer VBV | Número + unidad | `-bufsize 2M` |
| `-crf` | Constant Rate Factor (calidad) | 4-63 (menor=mejor) | `-crf 10` |
| `-qmin` | Quantizer mínimo | 0-63 | `-qmin 4` |
| `-qmax` | Quantizer máximo | 0-63 | `-qmax 63` |

### 6.2 Velocidad y Calidad de Codificación

| Parámetro | Descripción | Valores | Ejemplo |
|-----------|-------------|---------|---------|
| `-cpu-used` | Velocidad de codificación | -16 a 16 (mayor=rápido) | `-cpu-used 0` |
| `-deadline` | Modo de deadline | good, best, realtime | `-deadline good` |
| `-quality` | Alias de deadline | good, best, realtime | `-quality best` |

**Valores de cpu-used:**
- `-16` a `-5`: Mejor calidad, muy lento
- `-4` a `0`: Balance calidad/velocidad
- `1` a `4`: Codificación rápida
- `5` a `16`: Tiempo real, menor calidad

### 6.3 Control de GOP (Group of Pictures)

| Parámetro | Descripción | Valores | Ejemplo |
|-----------|-------------|---------|---------|
| `-g` | Tamaño del GOP (keyframe interval) | Número de frames | `-g 250` |
| `-keyint_min` | Intervalo mínimo de keyframes | Número de frames | `-keyint_min 25` |
| `-sc_threshold` | Umbral de detección de cambio de escena | 0-100 (0=desactivado) | `-sc_threshold 40` |

### 6.4 Configuración de Threads

| Parámetro | Descripción | Valores | Ejemplo |
|-----------|-------------|---------|---------|
| `-threads` | Número de threads de codificación | Número o auto | `-threads 4` |
| `-tile-columns` | Número de columnas de tiles | 0-6 (log2) | `-tile-columns 2` |
| `-tile-rows` | Número de filas de tiles | 0-2 (log2) | `-tile-rows 1` |

### 6.5 Configuración de Motion Estimation

| Parámetro | Descripción | Valores | Ejemplo |
|-----------|-------------|---------|---------|
| `-auto-alt-ref` | Habilitar altref frames | 0-2 | `-auto-alt-ref 1` |
| `-lag-in-frames` | Lookahead frames | 0-25 | `-lag-in-frames 25` |
| `-arnr-maxframes` | Frames para filtrado temporal | 0-15 | `-arnr-maxframes 7` |
| `-arnr-strength` | Fuerza del filtrado altref | 0-6 | `-arnr-strength 5` |

### 6.6 Modo de Codificación

| Parámetro | Descripción | Valores | Ejemplo |
|-----------|-------------|---------|---------|
| `-pass` | Pase de codificación multipaso | 1 o 2 | `-pass 1` |
| `-passlogfile` | Archivo de log multipaso | Ruta del archivo | `-passlogfile pass.log` |

### 6.7 Configuración Avanzada

| Parámetro | Descripción | Valores | Ejemplo |
|-----------|-------------|---------|---------|
| `-slices` | Número de slices | 1-4 | `-slices 4` |
| `-static-thresh` | Umbral de movimiento estático | 0-INT_MAX | `-static-thresh 0` |
| `-drop-threshold` | Umbral para descartar frames | 0-100 | `-drop-threshold 0` |
| `-noise-sensitivity` | Sensibilidad al ruido | 0-6 | `-noise-sensitivity 0` |
| `-undershoot-pct` | Porcentaje de undershoot permitido | 0-100 | `-undershoot-pct 95` |
| `-overshoot-pct` | Porcentaje de overshoot permitido | 0-100 | `-overshoot-pct 95` |

### 6.8 Configuración de Frame

| Parámetro | Descripción | Valores | Ejemplo |
|-----------|-------------|---------|---------|
| `-r` | Frame rate de salida | Número o fracción | `-r 30` |
| `-s` | Resolución de salida | WIDTHxHEIGHT | `-s 1920x1080` |
| `-aspect` | Aspect ratio | Ratio o fracción | `-aspect 16:9` |
| `-pix_fmt` | Formato de píxel | yuv420p, etc. | `-pix_fmt yuv420p` |

### 6.9 Audio para WebM

VP8 generalmente se combina con audio Vorbis o Opus en contenedor WebM:

| Parámetro | Descripción | Ejemplo |
|-----------|-------------|---------|
| `-c:a libvorbis` | Codec de audio Vorbis | `-c:a libvorbis -b:a 128k` |
| `-c:a libopus` | Codec de audio Opus | `-c:a libopus -b:a 96k` |
| `-an` | Sin audio | `-an` |

## 7. Ejemplos de Uso Práctico

### 7.1 Codificación con Bitrate Fijo

```bash
ffmpeg -i input.mp4 -c:v libvpx -b:v 1M -c:a libvorbis -b:a 128k output.webm
```

### 7.2 Codificación con Calidad Constante (CRF)

```bash
ffmpeg -i input.mp4 -c:v libvpx -crf 10 -b:v 0 -c:a libvorbis output.webm
```

### 7.3 Codificación con QP Constante

```bash
ffmpeg -i input.mp4 -c:v libvpx -qmin 28 -qmax 28 -c:a libvorbis output.webm
```

### 7.4 Codificación de Alta Calidad (2-pass)

**Primer pase:**
```bash
ffmpeg -i input.mp4 -c:v libvpx -b:v 2M -pass 1 -cpu-used 0 \
       -deadline best -auto-alt-ref 1 -lag-in-frames 25 \
       -f webm -y /dev/null
```

**Segundo pase:**
```bash
ffmpeg -i input.mp4 -c:v libvpx -b:v 2M -pass 2 -cpu-used 0 \
       -deadline best -auto-alt-ref 1 -lag-in-frames 25 \
       -c:a libvorbis -b:a 128k output.webm
```

### 7.5 Codificación Rápida (Realtime)

```bash
ffmpeg -i input.mp4 -c:v libvpx -b:v 1M -cpu-used 4 \
       -deadline realtime -c:a libvorbis output.webm
```

### 7.6 Conversión desde YUV Raw

```bash
ffmpeg -f rawvideo -pix_fmt yuv420p -s 1920x1080 -r 30 -i input.yuv \
       -c:v libvpx -b:v 2M output.webm
```

### 7.7 Control Estricto de Bitrate para Streaming

```bash
ffmpeg -i input.mp4 -c:v libvpx -b:v 1M -minrate 1M -maxrate 1M \
       -bufsize 2M -c:a libvorbis -b:a 128k output.webm
```

### 7.8 Optimización para Velocidad sin Sacrificar Demasiada Calidad

```bash
ffmpeg -i input.mp4 -c:v libvpx -crf 23 -cpu-used 2 \
       -deadline good -threads 4 -c:a libvorbis output.webm
```

## 8. Comparación de Modos de Control de Calidad

| Modo | Comando | Uso Recomendado | Características |
|------|---------|-----------------|-----------------|
| **Bitrate fijo** | `-b:v 1M` | Streaming, broadcast | Tamaño predecible, calidad variable |
| **CRF** | `-crf 10 -b:v 0` | Archivo, VOD | Calidad constante, tamaño variable |
| **QP constante** | `-qmin 28 -qmax 28` | Testing, comparaciones | QP fijo, control preciso |
| **2-pass VBR** | `-pass 1/2 -b:v 2M` | Alta calidad, archivo | Óptima distribución de bits |

## 9. Relación entre Parámetros de Calidad

### 9.1 CRF vs QP vs Bitrate

- **CRF (4-63)**: Control de calidad perceptual, ajusta QP dinámicamente
  - CRF 4-10: Calidad casi sin pérdida
  - CRF 10-20: Calidad muy alta
  - CRF 20-30: Calidad alta
  - CRF 30-40: Calidad media
  - CRF 40-63: Calidad baja

- **QP (0-63)**: Control directo del quantizer
  - QP 0-10: Máxima calidad
  - QP 10-28: Alta calidad
  - QP 28-40: Calidad media
  - QP 40-63: Baja calidad

- **Bitrate**: Control indirecto, depende de la complejidad del contenido

### 9.2 Velocidad vs Calidad (cpu-used)

| cpu-used | Velocidad | Calidad | Uso recomendado |
|----------|-----------|---------|-----------------|
| -16 a -5 | Muy lento | Máxima | Archivo maestro |
| -4 a 0 | Lento | Alta | Producción |
| 1 a 2 | Medio | Buena | General |
| 3 a 4 | Rápido | Aceptable | Draft, preview |
| 5 a 16 | Muy rápido | Baja | Tiempo real |

## 10. Recomendaciones y Mejores Prácticas

### 10.1 Para Máxima Calidad

```bash
ffmpeg -i input.mp4 -c:v libvpx -crf 4 -b:v 0 -cpu-used -5 \
       -deadline best -auto-alt-ref 1 -lag-in-frames 25 \
       -arnr-maxframes 15 -arnr-strength 6 \
       -c:a libopus -b:a 192k output.webm
```

### 10.2 Para Balance Calidad/Tamaño

```bash
ffmpeg -i input.mp4 -c:v libvpx -crf 23 -cpu-used 0 \
       -deadline good -auto-alt-ref 1 -lag-in-frames 16 \
       -c:a libvorbis -b:a 128k output.webm
```

### 10.3 Para Streaming en Vivo

```bash
ffmpeg -i input.mp4 -c:v libvpx -b:v 1M -cpu-used 8 \
       -deadline realtime -lag-in-frames 0 \
       -c:a libopus -b:a 96k -f webm output.webm
```

### 10.4 Para Archivos de Distribución Web

```bash
ffmpeg -i input.mp4 -c:v libvpx -crf 30 -cpu-used 1 \
       -deadline good -threads 4 \
       -c:a libvorbis -b:a 128k output.webm
```

## 11. Limitaciones y Consideraciones

### 11.1 Limitaciones Técnicas

1. **8-bit solamente**: VP8 no soporta 10-bit o HDR
2. **YUV 4:2:0**: No soporta muestreo 4:4:4 o 4:2:2
3. **Perfil único**: No tiene perfiles como H.264
4. **Escalabilidad**: Sin soporte nativo de SVC (Scalable Video Coding)

### 11.2 Consideraciones de Rendimiento

1. **CPU intensivo**: Especialmente en modos de alta calidad
2. **Memoria**: Requiere buffer significativo para altref frames
3. **Multithreading**: Limitado comparado con codecs más modernos
4. **Hardware**: Soporte limitado de aceleración GPU

### 11.3 Comparación con H.264

**Ventajas de VP8:**
- Libre de regalías
- Código abierto
- Integración nativa en navegadores

**Ventajas de H.264:**
- Mejor eficiencia de compresión (High Profile)
- Mayor soporte de hardware
- Más maduro y optimizado
- Mayor adopción en dispositivos

## 12. Sucesor: VP9

VP9 es el sucesor de VP8, ofreciendo:
- 50% mejor compresión que VP8
- Soporte para 10-bit y 12-bit
- Resoluciones hasta 8K
- Mejor eficiencia de codificación
- Tiles para paralelización

Para nuevos proyectos, considerar VP9 (libvpx-vp9) o AV1 en lugar de VP8.

## 13. Referencias

- [WebM Project](https://www.webmproject.org/)
- [VP8 Data Format and Decoding Guide (RFC 6386)](https://datatracker.ietf.org/doc/html/rfc6386)
- [FFmpeg libvpx Documentation](https://ffmpeg.org/ffmpeg-codecs.html#libvpx)
- [Google VP8 Codec SDK](https://chromium.googlesource.com/webm/libvpx/)
- [WebM Container Guidelines](https://www.webmproject.org/docs/container/)

---

**Nota**: Este documento cubre VP8 específicamente. Para aplicaciones modernas, se recomienda evaluar codecs más recientes como VP9, H.265/HEVC, o AV1, que ofrecen mejor eficiencia de compresión a costa de mayor complejidad computacional.
