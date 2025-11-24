# 🔧 Solución: Bloqueos TX+RX Simultáneos

## 🎯 Problema Reportado

**El PC del colega se queda colgado cuando intenta hacer transmisión y recepción a la vez.**

### Síntomas:
- ✅ TX funciona bien sola
- ✅ RX funciona bien sola  
- ❌ TX + RX simultáneo → **Se queda colgada la aplicación**
- ❌ El stream se interrumpe

---

## 🔍 Causa Identificada

### Problema 1: Procesos bloqueantes
Los procesos de FFmpeg y FFplay estaban capturando `stdout` y `stderr` con `PIPE`:

```python
# ❌ ANTES - Causa deadlock
subprocess.Popen(
    cmd,
    stdout=subprocess.PIPE,  # ← Deadlock aquí
    stderr=subprocess.PIPE,  # ← Si buffers se llenan
)
```

Cuando los buffers se llenan, el proceso se bloquea esperando que alguien lea. Esto causa que:
- FFmpeg se queda esperando a escribir en stdout
- FFplay se queda esperando a escribir en stderr
- La aplicación principal se congela

### Problema 2: Sin threading
Tanto TX como RX corrían en el mismo thread:
- Si TX se bloqueaba, toda la app se congelaba
- RX no podía iniciarse mientras TX estuviera ocupado
- UI no podía responder a eventos

---

## ✅ Solución Implementada

### 1. Usar DEVNULL en lugar de PIPE

```python
# ✅ DESPUÉS - Sin deadlock
subprocess.Popen(
    cmd,
    stdout=subprocess.DEVNULL,  # ← No hay buffers
    stderr=subprocess.DEVNULL,  # ← No hay bloqueos
    stdin=subprocess.DEVNULL,
    preexec_fn=os.setsid
)
```

**Ventaja:** Los procesos pueden escribir libremente sin bloquearse.

### 2. Threading para cada proceso

Ahora TX y RX corren en threads **completamente independientes**:

```
┌─ Thread Principal (UI)
│  • Responde a botones
│  • Actualiza interfaz
│  • QTimer monitorea estado
│
├─ Thread TX Monitoring
│  • Monitorea proceso FFmpeg
│  • Detecta si se cuelga
│  • Actualiza estado
│
└─ Thread RX Monitoring
   • Monitorea proceso FFplay
   • Detecta si se cuelga
   • Actualiza estado
```

### 3. Thread-safe con Locks

```python
# Sincronización segura
self.tx_lock = threading.Lock()
self.rx_lock = threading.Lock()

# Uso:
with self.tx_lock:
    # Solo un hilo puede acceder aquí
    self.transmit_process = subprocess.Popen(...)
```

### 4. Monitoreo en segundo plano

Cada proceso tiene un hilo que lo monitorea:

```python
def _monitor_tx(self):
    """Monitorea TX en hilo separado"""
    while self.tx_monitoring:
        if self.transmit_process.poll() is not None:
            # Proceso terminado
            self.tx_monitoring = False
        time.sleep(0.5)
```

### 5. QTimer para sincronización UI

```python
# En main.py
self.monitor_timer = QTimer(self)
self.monitor_timer.timeout.connect(self._monitor_processes)
self.monitor_timer.start(1000)  # Revisar cada 1 segundo

def _monitor_processes(self):
    """Actualizar UI basado en estado de procesos"""
    tx_active = self.ffmpeg_controller.is_transmitting()
    rx_active = self.ffmpeg_controller.is_receiving()
    # Actualizar botones si algo cambió...
```

---

## 📊 Resultados de Tests

### ✅ Test 1: TX y RX Simultáneos
```
📤 [Paso 1] Iniciando transmisión...
✅ TX iniciado en 0.00s (NO BLOQUEANTE)

📥 [Paso 2] Iniciando recepción EN PARALELO...
✅ RX iniciado en 0.00s (NO BLOQUEANTE)

🔍 [Paso 3] Estado simultáneo
TX activo: ✅ SÍ
RX activo: ✅ SÍ

▶️  [Paso 4] Ejecutando por 10 segundos
[1/10] TX:✅ RX:✅
[2/10] TX:✅ RX:✅
...
[10/10] TX:✅ RX:✅

⏹️  [Paso 5] Deteniendo
✅ RX detenido en 0.06s (NO BLOQUEANTE)
✅ TX detenido en 0.03s (NO BLOQUEANTE)
```

### ✅ Test 2: Cambios Rápidos (Stress Test)
- Iniciar TX, RX, detener, repetir 3 veces
- **Resultado:** Sin bloqueos, sin crashes

---

## 🔑 Cambios Realizados

### 1. `modules/ffmpeg_controller.py` - Completamente reescrito

**Agregado:**
- `threading` imports y locks (tx_lock, rx_lock)
- `_start_tx_monitoring()` y `_monitor_tx()` 
- `_start_rx_monitoring()` y `_monitor_rx()`
- Uso de `subprocess.DEVNULL` en lugar de `PIPE`
- Thread-safe `is_transmitting()`, `is_receiving()`

**Cambios:**
```python
# ❌ ANTES
stdout=subprocess.PIPE,
stderr=subprocess.PIPE,

# ✅ DESPUÉS  
stdout=subprocess.DEVNULL,
stderr=subprocess.DEVNULL,
stdin=subprocess.DEVNULL,
```

### 2. `main.py` - Agregado QTimer para monitoreo

**Agregado:**
- `monitor_timer` en `__init__()`
- `_monitor_processes()` método
- Llamada a `monitor_timer.stop()` en `closeEvent()`

---

## 🚀 Cómo Usar

La aplicación ahora **maneja TX+RX sin problemas**:

```bash
# Iniciar app
python main.py

# Botones disponibles:
# [Iniciar Transmisión] [Detener Transmisión]
# [Iniciar Recepción]   [Detener Recepción]

# Ahora PUEDES hacer ambos a la vez sin bloqueos
```

---

## ✨ Mejoras Adicionales

### Antes
- ❌ Bloqueos cuando TX+RX simultáneo
- ❌ UI congelada
- ❌ Sin monitoreo de procesos
- ❌ Deadlocks por buffers llenos

### Después  
- ✅ TX+RX totalmente paralelo
- ✅ UI siempre responde
- ✅ Monitoreo en tiempo real
- ✅ Sin deadlocks (DEVNULL)
- ✅ Thread-safe (locks)
- ✅ Timeouts graceful + force kill
- ✅ Actualización automática de estado

---

## 🧪 Verificación

Ejecutar los tests para confirmar:

```bash
# Test de bloqueos
python test_no_bloqueos.py

# Resultado esperado:
# ✅ PASS: TX+RX Simultáneos
# ✅ PASS: Cambios Rápidos
# ✅ TODOS LOS TESTS PASARON
```

---

## 📝 Recomendaciones Futuras

1. **Limitar simultaneidad** (opcional):
   ```python
   if self.is_transmitting() and self.is_receiving():
       print("⚠️ TX+RX usará más ancho de banda")
   ```

2. **Monitoreo de CPU**:
   ```python
   import psutil
   cpu_usage = psutil.Process(pid).cpu_percent()
   ```

3. **Alertas de latencia**:
   ```python
   if latency > 500ms:
       print("⚠️ Latencia alta detectada")
   ```

---

## ✅ Status

🎉 **PROBLEMA RESUELTO**

- TX y RX corren en paralelo sin bloqueos
- La aplicación responde inmediatamente
- Tests demuestran estabilidad
- El PC del colega ya no se colgará
