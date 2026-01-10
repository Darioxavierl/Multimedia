# Guía de Configuración y Ajuste

**Sistema de Streaming Adaptativo DASH**

## Índice

1. [Introducción](#introducción)
2. [Parámetros de FFmpeg](#parámetros-de-ffmpeg)
3. [Parámetros de Shaka Player](#parámetros-de-shaka-player)
4. [Optimización de Latencia](#optimización-de-latencia)
5. [Solución de Cortes](#solución-de-cortes)
6. [Configuraciones Predefinidas](#configuraciones-predefinidas)
7. [Procedimiento de Ajuste](#procedimiento-de-ajuste)

## Introducción

Este documento describe los parámetros configurables del sistema y proporciona guías para optimizar el balance entre latencia y estabilidad del streaming.

### Relación Latencia-Estabilidad

Existe una relación inversa fundamental:
- **Menor latencia**: Requiere buffers más pequeños → Mayor riesgo de cortes
- **Mayor estabilidad**: Requiere buffers más grandes → Mayor latencia

El objetivo es encontrar el punto óptimo para cada caso de uso.

## Parámetros de FFmpeg

### Ubicación

Archivo: `backend/main.py`  
Función: `start_stream()`  
Líneas: 72-105

### Parámetros de Codificación

#### preset
```bash
-preset ultrafast
```

**Descripción**: Velocidad de codificación vs calidad

**Valores posibles**:
- `ultrafast`: Codificación más rápida, menor calidad
- `veryfast`: Balance rápido
- `faster`: Codificación rápida
- `fast`: Codificación normal
- `medium`: Balance (por defecto FFmpeg)

**Recomendación**: `ultrafast` para streaming en vivo

**Impacto**:
- Velocidad: Crítico para latencia
- CPU: Mayor preset = Mayor uso CPU
- Calidad: Menor calidad con ultrafast

#### tune
```bash
-tune zerolatency
```

**Descripción**: Optimización específica

**Valores posibles**:
- `zerolatency`: Mínima latencia (streaming en vivo)
- `film`: Optimizado para películas
- `animation`: Optimizado para animación

**Recomendación**: `zerolatency` siempre para streaming

#### g (GOP Size)
```bash
-g 10
```

**Descripción**: Tamaño del Group of Pictures (distancia entre keyframes)

**Valores recomendados**:
- Ultra rápido: 8
- Balanceado: 10
- Ultra estable: 15

**Impacto**:
- Latencia: Mayor GOP = Menor overhead = Menor latencia
- Seeking: Menor GOP = Mejor seeking
- Bitrate: Menor GOP = Mayor bitrate necesario

**Cálculo**: `GOP = framerate * seg_duration * factor`
- Para 10fps, seg_duration=1s: GOP=10

#### keyint_min
```bash
-keyint_min 1
```

**Descripción**: Mínimo intervalo entre keyframes

**Valor**: Mantener en 1 para streaming adaptativo

#### sc_threshold
```bash
-sc_threshold 0
```

**Descripción**: Umbral de detección de cambio de escena

**Valor**: 0 para deshabilitar (segmentos más predecibles)

**Impacto**:
- Consistencia: 0 = Segmentos más uniformes
- Calidad: Puede afectar transiciones de escena

### Parámetros de Bitrate

#### b:v (Bitrate)
```bash
-b:v 1000k
```

**Descripción**: Bitrate objetivo

**Valores recomendados**:
- 480p: 500-800 kbps
- 720p: 1000-1500 kbps
- 1080p: 2500-4000 kbps

**Ajuste**: Según resolución y movimiento en escena

#### maxrate
```bash
-maxrate 1000k
```

**Descripción**: Bitrate máximo permitido

**Recomendación**: Igual a `b:v` para streaming constante

#### minrate
```bash
-minrate 800k
```

**Descripción**: Bitrate mínimo (opcional)

**Uso**: Evita caídas bruscas que pueden causar cortes

#### bufsize
```bash
-bufsize 2000k
```

**Descripción**: Tamaño del buffer VBV

**Cálculo**: Típicamente `2 * bitrate`

**Impacto**: Mayor = Más suave, pero más latencia

### Parámetros DASH

#### seg_duration
```bash
-seg_duration 1
```

**Descripción**: Duración de cada segmento en segundos

**Valores recomendados**:
- Ultra rápido: 0.75
- Balanceado: 1.0
- Ultra estable: 1.5

**Impacto directo**:
- Latencia mínima teórica: `seg_duration * 2`
- Overhead: Menor duración = Mayor overhead
- Cortes: Menor duración = Mayor riesgo

**Nota importante**: Este es el parámetro con mayor impacto en latencia

#### frag_duration
```bash
-frag_duration 1
```

**Descripción**: Duración de fragmentos dentro del segmento

**Recomendación**: Igual a `seg_duration` para streaming

#### window_size
```bash
-window_size 5
```

**Descripción**: Número de segmentos disponibles en el manifiesto MPD

**Valores recomendados**:
- Ultra rápido: 3
- Balanceado: 5
- Ultra estable: 7

**Impacto**:
- Disponibilidad: Mayor = Más segmentos disponibles
- Memoria: Mayor = Mayor uso de disco
- Cortes: Mayor = Menor riesgo de cortes

**Cálculo de latencia**: `window_size * seg_duration` = segundos disponibles

#### extra_window_size
```bash
-extra_window_size 2
```

**Descripción**: Segmentos adicionales como respaldo

**Valores recomendados**:
- Ultra rápido: 1
- Balanceado: 2
- Ultra estable: 3

**Uso**: Margen de seguridad contra cortes

#### target_latency
```bash
-target_latency 2
```

**Descripción**: Latencia objetivo en segundos (sugerencia para el reproductor)

**Valores**:
- Ultra rápido: 1.5
- Balanceado: 2.0
- Ultra estable: 3.0

**Nota**: Es una sugerencia, no una garantía

#### streaming
```bash
-streaming 1
```

**Descripción**: Habilita modo streaming

**Valor**: Siempre 1 para streaming en vivo

#### ldash
```bash
-ldash 1
```

**Descripción**: Habilita Low-latency DASH

**Valor**: Siempre 1 para baja latencia

#### write_prft
```bash
-write_prft 1
```

**Descripción**: Escribe Producer Reference Time en segmentos

**Uso**: Mejora sincronización de timestamps

**Recomendación**: 1 para mejor sincronización

### Aplicar Cambios en FFmpeg

```bash
# 1. Editar backend/main.py
nano backend/main.py

# 2. Reconstruir contenedor
./rebuild.sh

# 3. Verificar logs
sudo docker compose logs -f backend
```

## Parámetros de Shaka Player

### Ubicación

Archivo: `www/html/js/video-player.js`  
Función: `configurePlayer()`  
Líneas: 31-60

### Parámetros de Streaming

#### bufferingGoal
```javascript
bufferingGoal: 4
```

**Descripción**: Cantidad de video a mantener en buffer (segundos)

**Valores recomendados**:
- Ultra rápido: 2.5
- Balanceado: 4
- Ultra estable: 6

**Impacto**:
- Latencia: Afecta directamente la latencia percibida
- Cortes: Mayor valor = Menos cortes
- Memoria: Mayor valor = Mayor uso de memoria

**Nota**: Este es el segundo parámetro más importante

#### rebufferingGoal
```javascript
rebufferingGoal: 2
```

**Descripción**: Buffer mínimo antes de rebuffering

**Valores recomendados**:
- Ultra rápido: 1
- Balanceado: 2
- Ultra estable: 3

**Impacto**:
- Cortes: Mayor = Más tolerancia antes de pausar
- UX: Afecta frecuencia de pausas

#### bufferBehind
```javascript
bufferBehind: 5
```

**Descripción**: Cantidad de buffer a mantener detrás del punto de reproducción

**Valores**: 5-10 segundos

**Impacto**: Solo afecta memoria, no latencia

#### lowLatencyMode
```javascript
lowLatencyMode: true
```

**Descripción**: Activa optimizaciones para baja latencia

**Valor**: Siempre `true` para streaming en vivo

#### inaccurateManifestTolerance
```javascript
inaccurateManifestTolerance: 0
```

**Descripción**: Tolerancia a manifiestos imprecisos

**Valor**: 0 para streaming en vivo

### Parámetros de Reintentos

#### timeout
```javascript
timeout: 5000
```

**Descripción**: Timeout para peticiones HTTP (milisegundos)

**Valores recomendados**:
- Ultra rápido: 3000
- Balanceado: 5000
- Ultra estable: 8000

#### maxAttempts
```javascript
maxAttempts: 4
```

**Descripción**: Número máximo de reintentos

**Valores**: 3-5

#### baseDelay
```javascript
baseDelay: 500
```

**Descripción**: Delay base entre reintentos (milisegundos)

**Valores**: 300-1000

#### backoffFactor
```javascript
backoffFactor: 1.5
```

**Descripción**: Factor de incremento del delay

**Uso**: delay_n = baseDelay * (backoffFactor ^ n)

### Parámetros de Detección de Paradas

#### stallEnabled
```javascript
stallEnabled: true
```

**Descripción**: Habilita detección de paradas

**Valor**: `true` para recuperación automática

#### stallThreshold
```javascript
stallThreshold: 1
```

**Descripción**: Tiempo antes de detectar parada (segundos)

**Valores recomendados**:
- Ultra rápido: 0.5
- Balanceado: 1
- Ultra estable: 2

#### stallSkip
```javascript
stallSkip: 0.1
```

**Descripción**: Tiempo a saltar si se detecta parada (segundos)

**Valor**: 0.1 - 0.5 segundos

### Parámetros ABR (Adaptive Bitrate)

#### switchInterval
```javascript
switchInterval: 4
```

**Descripción**: Frecuencia de evaluación de calidad (segundos)

**Valores**: 3-6 segundos

#### bandwidthUpgradeTarget
```javascript
bandwidthUpgradeTarget: 0.85
```

**Descripción**: Porcentaje de ancho de banda para upgrade

**Valor**: 0.80 - 0.90 (más conservador = menor)

#### bandwidthDowngradeTarget
```javascript
bandwidthDowngradeTarget: 0.95
```

**Descripción**: Porcentaje para downgrade

**Valor**: 0.90 - 0.95

### Aplicar Cambios en Shaka Player

```bash
# 1. Editar www/html/js/video-player.js
nano www/html/js/video-player.js

# 2. Guardar archivo

# 3. Recargar página en navegador
# Presionar Ctrl+F5 (forzar recarga)
```

**Nota**: No requiere reconstruir contenedores

## Optimización de Latencia

### Latencia Objetivo: < 2 segundos

#### Parámetros FFmpeg
```bash
-seg_duration 0.75
-window_size 3
-extra_window_size 1
-g 8
-target_latency 1.5
```

#### Parámetros Shaka
```javascript
bufferingGoal: 2.5
rebufferingGoal: 1
stallThreshold: 0.5
```

### Latencia Objetivo: 2-3 segundos (Balanceado)

#### Parámetros FFmpeg
```bash
-seg_duration 1
-window_size 5
-extra_window_size 2
-g 10
-target_latency 2
```

#### Parámetros Shaka
```javascript
bufferingGoal: 4
rebufferingGoal: 2
stallThreshold: 1
```

### Latencia Objetivo: > 3 segundos (Estable)

#### Parámetros FFmpeg
```bash
-seg_duration 1.5
-window_size 7
-extra_window_size 3
-g 15
-target_latency 3
```

#### Parámetros Shaka
```javascript
bufferingGoal: 6
rebufferingGoal: 3
stallThreshold: 2
```

## Solución de Cortes

### Diagnóstico

1. **Identificar patrón de cortes**
   - ¿Cortes regulares o aleatorios?
   - ¿Al inicio o durante reproducción?
   - ¿Con buffering o sin avisoparate?

2. **Verificar métricas**
   - Buffer mostrado en UI
   - Logs de FFmpeg
   - Consola del navegador

### Orden de Ajustes (Prioridad)

#### 1. Aumentar window_size (Mayor impacto)

```bash
# backend/main.py
-window_size 6  # o 7, 8
```

**Rationale**: Más segmentos disponibles = Menor probabilidad de falta

#### 2. Aumentar bufferingGoal

```javascript
// video-player.js
bufferingGoal: 5  // o 6
```

**Rationale**: Más buffer en cliente = Más margen contra variaciones

#### 3. Aumentar extra_window_size

```bash
# backend/main.py
-extra_window_size 3
```

**Rationale**: Margen de seguridad adicional

#### 4. Aumentar rebufferingGoal

```javascript
// video-player.js
rebufferingGoal: 3
```

**Rationale**: Más tolerancia antes de pausar

#### 5. Aumentar seg_duration (Último recurso)

```bash
# backend/main.py
-seg_duration 1.5  # o 2
```

**Rationale**: Segmentos más largos = Menor frecuencia de cambio

**Nota**: Aumenta latencia significativamente

### Casos Específicos

#### Cortes al inicio de transmisión

**Causa**: Reproductor intenta cargar antes de tener segmentos suficientes

**Solución**:
```javascript
// main.js - waitForMPD
timeout: 20000  // Aumentar timeout
await new Promise(resolve => setTimeout(resolve, 4000)); // Más espera
```

#### Cortes al regenerar segmentos

**Causa**: Race condition entre escritura y lectura

**Solución**:
```bash
# backend/main.py
-write_prft 1              # Mejorar timestamps
-frag_duration 1           # Fragmentación consistente
-window_size 6             # Más ventana
```

#### Cortes aleatorios

**Causa**: Variaciones de red o CPU

**Solución**:
```javascript
// video-player.js
maxAttempts: 5             // Más reintentos
timeout: 8000              // Mayor timeout
bufferingGoal: 5           // Más buffer
```

```bash
# backend/main.py
-bufsize 3000k             # Mayor buffer VBV
-maxrate 1200k             # Permitir picos pequeños
```

## Configuraciones Predefinidas

### Uso de Configuraciones

```bash
# Ver información de una configuración
./test-config.sh ultra-estable

# Aplicar manualmente copiando desde configs/
```

### Ultra Rápida

**Archivo**: `configs/video-player-ultra-rapido.js` y `configs/ffmpeg-ultra-rapido.txt`

**Características**:
- Latencia: 1.5-2 segundos
- Estabilidad: Baja (cortes posibles)
- Uso: Red muy estable, prioridad absoluta en latencia

**FFmpeg**:
```bash
-seg_duration 0.75
-window_size 3
-extra_window_size 1
-g 8
-bufsize 1500k
-target_latency 1.5
```

**Shaka**:
```javascript
bufferingGoal: 2.5
rebufferingGoal: 1
timeout: 3000
maxAttempts: 3
stallThreshold: 0.5
```

### Balanceada (Actual)

**Características**:
- Latencia: 2-2.5 segundos
- Estabilidad: Media
- Uso: General, balance óptimo

**FFmpeg**:
```bash
-seg_duration 1
-window_size 5
-extra_window_size 2
-g 10
-bufsize 2000k
-target_latency 2
```

**Shaka**:
```javascript
bufferingGoal: 4
rebufferingGoal: 2
timeout: 5000
maxAttempts: 4
stallThreshold: 1
```

### Ultra Estable

**Archivo**: `configs/video-player-ultra-estable.js` y `configs/ffmpeg-ultra-estable.txt`

**Características**:
- Latencia: 3-3.5 segundos
- Estabilidad: Alta (sin cortes)
- Uso: Red inestable, prioridad en estabilidad

**FFmpeg**:
```bash
-seg_duration 1.5
-window_size 7
-extra_window_size 3
-g 15
-bufsize 3000k
-target_latency 3
```

**Shaka**:
```javascript
bufferingGoal: 6
rebufferingGoal: 3
timeout: 8000
maxAttempts: 5
stallThreshold: 2
```

## Procedimiento de Ajuste

### Metodología

1. **Establecer objetivo**
   - Definir latencia objetivo
   - Definir tolerancia a cortes

2. **Comenzar con configuración estable**
   - Usar ultra-estable como baseline
   - Verificar que no hay cortes

3. **Reducir latencia gradualmente**
   - Ajustar un parámetro a la vez
   - Probar cada cambio 5-10 minutos
   - Registrar resultados

4. **Encontrar punto óptimo**
   - Balance entre latencia y estabilidad
   - Documentar configuración final

### Pasos Detallados

#### Paso 1: Prueba Inicial (Ultra Estable)

```bash
# 1. Copiar configuración ultra estable
cp configs/ffmpeg-ultra-estable.txt backend/main.py  # Copiar manualmente
cp configs/video-player-ultra-estable.js www/html/js/video-player.js  # Adaptar

# 2. Reconstruir
./rebuild.sh

# 3. Recargar página
# Ctrl+F5 en navegador

# 4. Probar 10 minutos
# Verificar que NO hay cortes
```

#### Paso 2: Reducir Latencia Gradualmente

```bash
# Reducir window_size de 7 a 6
# backend/main.py: -window_size 6

./rebuild.sh
# Probar 5 minutos

# Si no hay cortes, reducir a 5
# Repetir hasta encontrar punto de cortes
```

#### Paso 3: Ajustar Buffer Cliente

```javascript
// Reducir bufferingGoal de 6 a 5
// video-player.js
bufferingGoal: 5

// Recargar página (Ctrl+F5)
// Probar 5 minutos
```

#### Paso 4: Afinar Parámetros Menores

```bash
# Ajustar extra_window_size si es necesario
# Ajustar GOP si es necesario
# Ajustar timeouts si es necesario
```

#### Paso 5: Validación Final

```bash
# Probar configuración final por 30 minutos
# Monitorear:
# - Número de cortes
# - Latencia promedio
# - Uso de CPU/RAM
# - Calidad de video
```

### Registro de Pruebas

Mantener registro de ajustes:

```
Fecha: 2026-01-10
Configuración: Balanceada
seg_duration: 1
window_size: 5
bufferingGoal: 4

Resultados:
- Latencia: 2.3s promedio
- Cortes: 2 en 30 minutos
- CPU: 45% promedio
- RAM: 180MB

Conclusión: Aumentar window_size a 6
```

## Monitoreo y Métricas

### Métricas del Sistema

```bash
# CPU y RAM de contenedores
sudo docker stats

# Logs en tiempo real
sudo docker compose logs -f backend

# Verificar segmentos
watch -n 1 'ls -lht www/html/segmentos/ | head -20'
```

### Métricas del Reproductor

Abrir consola del navegador (F12):

```javascript
// Métricas disponibles en la UI:
// - Estado: transmitiendo/detenido
// - Calidad: resolución y bitrate
// - Buffer: segundos disponibles

// En consola:
// - "Parada detectada..." → Stall event
// - "Video en espera..." → Waiting event
```

### Indicadores de Problemas

| Síntoma | Causa Probable | Solución |
|---------|----------------|----------|
| Buffer < 1s frecuentemente | bufferingGoal muy bajo | Aumentar bufferingGoal |
| Cortes regulares cada N segundos | window_size insuficiente | Aumentar window_size |
| Latencia > objetivo + 2s | Buffers muy grandes | Reducir buffers gradualmente |
| CPU > 90% | Preset muy lento | Usar ultrafast o veryfast |
| Segmentos no se generan | Error FFmpeg | Revisar logs backend |

## Referencias

### Documentación Oficial

- FFmpeg DASH: https://ffmpeg.org/ffmpeg-formats.html#dash-2
- Shaka Player: https://shaka-player-demo.appspot.com/docs/api/
- DASH Spec: https://dashif.org/

### Herramientas Útiles

- DASH Validator: https://conformance.dashif.org/
- Bitrate Calculator: https://toolstud.io/video/bitrate.php

---

**Autor**: Dario Portilla  
**Universidad de Cuenca**  
**Última actualización**: Enero 2026
