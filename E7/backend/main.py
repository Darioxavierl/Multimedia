from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import subprocess
import signal
import os
import threading
import logging
from typing import Optional

# Configurar logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="DASH Streaming API")

# Configurar CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Variable global para almacenar el proceso de FFmpeg
ffmpeg_process: Optional[subprocess.Popen] = None
ffmpeg_error_log = []

# Configuración
OUTPUT_DIR = "/var/www/html/segmentos"
MPD_FILE = f"{OUTPUT_DIR}/video0.mpd"

def read_ffmpeg_output(process):
    """Lee y almacena la salida de error de FFmpeg"""
    global ffmpeg_error_log
    ffmpeg_error_log = []
    for line in process.stderr:
        line_decoded = line.decode('utf-8', errors='ignore').strip()
        ffmpeg_error_log.append(line_decoded)
        logger.info(f"FFmpeg: {line_decoded}")
        # Mantener solo las últimas 50 líneas
        if len(ffmpeg_error_log) > 50:
            ffmpeg_error_log.pop(0)

@app.get("/")
def read_root():
    return {
        "service": "DASH Streaming API",
        "status": "running",
        "endpoints": {
            "start": "/api/stream/start",
            "stop": "/api/stream/stop",
            "status": "/api/stream/status"
        }
    }

@app.post("/api/stream/start")
def start_stream():
    global ffmpeg_process
    
    # Verificar si ya hay un proceso activo
    if ffmpeg_process and ffmpeg_process.poll() is None:
        return {
            "success": False,
            "message": "La transmisión ya está activa"
        }
    
    try:
        # Crear directorio de salida si no existe
        os.makedirs(OUTPUT_DIR, exist_ok=True)
        
        # Comando FFmpeg optimizado para baja latencia y estabilidad
        command = [
            "ffmpeg",
            "-y",
            "-f", "v4l2",
            "-video_size", "1280x720",
            "-framerate", "25",
            "-i", "/dev/video0",
            "-vcodec", "libx264",
            "-preset", "ultrafast",           # Encoding más rápido
            "-tune", "zerolatency",           # Optimizar para latencia mínima
            "-keyint_min", "1",
            "-g", "10",                       # GOP más corto
            "-sc_threshold", "0",             # Deshabilitar detección de cambio de escena
            "-b:v", "1000k",
            "-maxrate", "1000k",              # Bitrate máximo
            "-bufsize", "2000k",              # Buffer size para consistencia
            "-pix_fmt", "yuv420p",
            "-map", "0:v",
            "-f", "dash",
            "-seg_duration", "1",             # Segmentos de 1 segundo
            "-frag_duration", "1",            # Duración de fragmentos
            "-use_template", "1",
            "-use_timeline", "1",             # Usar timeline para números de segmento correctos
            "-init_seg_name", "init-$RepresentationID$.mp4",
            "-profile:v", "baseline",
            "-media_seg_name", "video-$RepresentationID$-$Number$.mp4",
            "-remove_at_exit", "1",
            "-window_size", "10",             # Aumentado a 10 para acceso desde red local
            "-extra_window_size", "5",        # Ventana extra aumentada para mejor acceso
            "-ldash", "1",                    # Habilitar Low-latency DASH
            "-streaming", "1",                # Modo streaming
            "-target_latency", "2",           # Target latency de 2 segundos
            MPD_FILE
        ]
        
        # Iniciar proceso FFmpeg
        ffmpeg_process = subprocess.Popen(
            command,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            preexec_fn=os.setsid  # Crear nuevo grupo de procesos
        )
        
        # Iniciar hilo para leer la salida de FFmpeg
        output_thread = threading.Thread(target=read_ffmpeg_output, args=(ffmpeg_process,))
        output_thread.daemon = True
        output_thread.start()
        
        logger.info(f"FFmpeg iniciado con PID: {ffmpeg_process.pid}")
        
        return {
            "success": True,
            "message": "Transmisión iniciada correctamente",
            "pid": ffmpeg_process.pid,
            "output": MPD_FILE
        }
        
    except FileNotFoundError:
        return {
            "success": False,
            "message": "FFmpeg no está instalado o no se encuentra en el PATH"
        }
    except Exception as e:
        return {
            "success": False,
            "message": f"Error al iniciar transmisión: {str(e)}"
        }

@app.post("/api/stream/stop")
def stop_stream():
    global ffmpeg_process
    
    if not ffmpeg_process or ffmpeg_process.poll() is not None:
        return {
            "success": False,
            "message": "No hay transmisión activa"
        }
    
    try:
        # Enviar señal SIGTERM al grupo de procesos
        os.killpg(os.getpgid(ffmpeg_process.pid), signal.SIGTERM)
        
        # Esperar a que termine
        ffmpeg_process.wait(timeout=5)
        
        ffmpeg_process = None
        
        return {
            "success": True,
            "message": "Transmisión detenida correctamente"
        }
        
    except subprocess.TimeoutExpired:
        # Si no termina, forzar con SIGKILL
        os.killpg(os.getpgid(ffmpeg_process.pid), signal.SIGKILL)
        ffmpeg_process = None
        
        return {
            "success": True,
            "message": "Transmisión detenida forzosamente"
        }
    except Exception as e:
        return {
            "success": False,
            "message": f"Error al detener transmisión: {str(e)}"
        }

@app.get("/api/stream/status")
def get_status():
    global ffmpeg_process
    
    is_running = ffmpeg_process and ffmpeg_process.poll() is None
    
    status = {
        "running": is_running,
        "pid": ffmpeg_process.pid if is_running else None,
        "mpd_file": MPD_FILE if is_running else None
    }
    
    # Verificar si el archivo MPD existe
    if is_running and os.path.exists(MPD_FILE):
        status["mpd_exists"] = True
        status["mpd_size"] = os.path.getsize(MPD_FILE)
    else:
        status["mpd_exists"] = False
    
    return status

@app.get("/api/stream/logs")
def get_logs():
    """Obtener los logs de FFmpeg"""
    global ffmpeg_error_log
    return {
        "logs": ffmpeg_error_log,
        "count": len(ffmpeg_error_log)
    }

# Manejador para limpieza al cerrar la aplicación
@app.on_event("shutdown")
def shutdown_event():
    global ffmpeg_process
    if ffmpeg_process and ffmpeg_process.poll() is None:
        try:
            os.killpg(os.getpgid(ffmpeg_process.pid), signal.SIGTERM)
            ffmpeg_process.wait(timeout=5)
        except:
            pass

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
