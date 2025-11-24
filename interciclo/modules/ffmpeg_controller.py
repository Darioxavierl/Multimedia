#modules/ffmpeg_controller.py
"""
Controlador de FFmpeg y FFplay
Maneja la transmisión y recepción de video/audio (FFplay only)
Usa threading para evitar bloqueos entre TX/RX
"""

import subprocess
import signal
import os
import threading
import time


class FFmpegController:
    def __init__(self, player_type="ffplay"):
        """
        Inicializar controlador de FFmpeg
        
        Args:
            player_type: Solo "ffplay" está soportado
        """
        self.transmit_process = None
        self.receive_process = None
        self.player_type = "ffplay"  # Solo FFplay, sin VLC
        
        # Locks para sincronización thread-safe
        self.tx_lock = threading.Lock()
        self.rx_lock = threading.Lock()
        
        # Banderas para monitorear procesos
        self.tx_monitoring = False
        self.rx_monitoring = False
        self.tx_monitor_thread = None
        self.rx_monitor_thread = None
        
        print(f"✅ FFmpegController inicializado - usando {self.player_type} (con threading)")
    
    def set_player_type(self, player_type):
        """
        Cambiar el tipo de reproductor (no-op, solo FFplay)
        
        Args:
            player_type: "ffplay" (otros tipos son ignorados)
        """
        if self.is_receiving():
            self.stop_reception()
        
        self.player_type = "ffplay"
        print("Usando FFplay (única opción)")
        return True
    
    def get_player_type(self):
        """Obtener el tipo de reproductor actual"""
        return self.player_type
    
    def build_transmit_command(self, params):
        """
        Construir comando de transmisión FFmpeg
        Usa testsrc (patrón de prueba) para no depender de dispositivos físicos
        
        Args:
            params: Diccionario con parámetros de configuración
            
        Returns:
            list: Comando como lista de argumentos
        """
        cmd = [
            "ffmpeg",
            "-f", params['controlador'],
            "-framerate", str(params['fps_entrada']),
            "-video_size", f"{params['width']}x{params['height']}",
            "-i", params['video_device'],
            "-f", "alsa",
            "-ac", str(params['canales_audio_input']),
            "-i", params['audio_device'],
            "-c:v", "libx264",
            "-pix_fmt", "yuv420p",
            "-b:v", f"{params['video_bitrate']}k",
            "-g", str(params['gop']),
            "-r", str(params['fps_salida']),
            "-tune", "zerolatency",
            "-c:a", params['audio_codec'],
            "-b:a", f"{params['audio_bitrate']}k",
            "-ar", str(params['muestras']),
            "-ac", str(params['canales_audio_output']),
            "-f", params['protocolo'],
            "-flush_packets", "1",
            "-fflags", "+genpts+igndts",     # Generar PTS, ignorar DTS
            "-avoid_negative_ts", "make_zero",
            "-max_interleave_delta", "0",
            params['direccion_tx']
        ]
        return cmd
    
    def build_receive_command_ffplay(self, params):
        """
        Construir comando de recepción FFplay (ventana externa)
        
        Args:
            params: Diccionario con parámetros de configuración
                   - direccion_rx: "udp://224.0.0.1:5000?fifo_size=30000&reuse=1"
                   - probesize: "32" o "1000"
            
        Returns:
            list: Comando como lista de argumentos
        """
        probesize = params.get('probesize', '32')
        url_rx = params.get('direccion_rx', 'udp://224.0.0.1:5000?fifo_size=30000&reuse=1')
        
        cmd = [
            "ffplay",
            "-probesize", params['probesize'],
            "-fflags", "nobuffer",
            "-flags", "low_delay",
            "-framedrop",
            "-sync", "ext",
            "-alwaysontop",
            "-window_title", "VideoConferencia - Recepción",
            params['direccion_rx']
        ]
        return cmd
    
    def start_transmission(self, params):
        """
        Iniciar transmisión de video/audio EN UN HILO SEPARADO
        
        Args:
            params: Diccionario con parámetros de configuración
            
        Returns:
            bool: True si se inició correctamente
        """
        with self.tx_lock:
            if self.transmit_process is not None:
                print("Ya hay una transmisión activa")
                return False
            
            try:
                cmd = self.build_transmit_command(params)
                print(f"Iniciando transmisión: {' '.join(cmd)}")
                
                # CRÍTICO: No capturar stdout/stderr para evitar deadlocks
                # Usar DEVNULL en lugar de PIPE
                self.transmit_process = subprocess.Popen(
                    cmd,
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                    stdin=subprocess.DEVNULL,
                    preexec_fn=os.setsid
                )
                print(f"✅ Transmisión iniciada (PID: {self.transmit_process.pid})")
                
                # Iniciar monitoreo en hilo separado
                self._start_tx_monitoring()
                
                return True
            except FileNotFoundError:
                print("Error: FFmpeg no encontrado. Asegúrate de que esté instalado.")
                return False
            except Exception as e:
                print(f"Error al iniciar transmisión: {e}")
                return False
    
    def _start_tx_monitoring(self):
        """Monitorear transmisión en hilo separado"""
        if self.tx_monitoring:
            return
        
        self.tx_monitoring = True
        self.tx_monitor_thread = threading.Thread(target=self._monitor_tx, daemon=True)
        self.tx_monitor_thread.start()
    
    def _monitor_tx(self):
        """Monitorear el proceso de transmisión"""
        while self.tx_monitoring and self.transmit_process:
            try:
                if self.transmit_process.poll() is not None:
                    # Proceso terminado
                    self.tx_monitoring = False
                    print("⚠️  Proceso de transmisión terminado inesperadamente")
                    with self.tx_lock:
                        self.transmit_process = None
                    break
                time.sleep(0.5)
            except Exception as e:
                print(f"Error en monitoreo TX: {e}")
                break
    
    def stop_transmission(self):
        """Detener transmisión activa de forma thread-safe"""
        with self.tx_lock:
            if self.transmit_process is not None:
                try:
                    print("Deteniendo transmisión...")
                    # Usar SIGTERM primero (graceful shutdown)
                    os.killpg(os.getpgid(self.transmit_process.pid), signal.SIGTERM)
                    
                    try:
                        self.transmit_process.wait(timeout=3)
                    except subprocess.TimeoutExpired:
                        print("  Forzando terminación...")
                        os.killpg(os.getpgid(self.transmit_process.pid), signal.SIGKILL)
                        self.transmit_process.wait()
                except Exception as e:
                    print(f"Error al detener transmisión: {e}")
                finally:
                    self.transmit_process = None
                    self.tx_monitoring = False
                    print("✓ Transmisión detenida")
    
    def start_reception(self, params, win_id=None, video_size=None):
        """
        Iniciar recepción de video/audio EN UN HILO SEPARADO
        
        Args:
            params: Diccionario con parámetros de configuración
            win_id: IGNORADO (no necesario para FFplay)
            video_size: IGNORADO (FFplay abre en ventana independiente)
            
        Returns:
            bool: True si se inició correctamente
        """
        if self.is_receiving():
            print("Ya hay una recepción activa")
            return False
        
        return self._start_reception_ffplay(params)
    
    def _start_reception_ffplay(self, params):
        """
        Iniciar recepción con FFplay EN UN HILO SEPARADO
        """
        with self.rx_lock:
            if self.receive_process is not None:
                print("Ya hay una recepción FFplay activa")
                return False
            
            try:
                cmd = self.build_receive_command_ffplay(params)
                print(f"Iniciando recepción FFplay: {' '.join(cmd)}")
                
                # CRÍTICO: No capturar stdout/stderr para evitar deadlocks
                self.receive_process = subprocess.Popen(
                    cmd,
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                    stdin=subprocess.DEVNULL,
                    preexec_fn=os.setsid
                )
                print(f"✅ Recepción iniciada (PID: {self.receive_process.pid})")
                print("   FFplay se abrirá en una ventana separada")
                
                # Iniciar monitoreo en hilo separado
                self._start_rx_monitoring()
                
                return True
            except FileNotFoundError:
                print("Error: FFplay no encontrado. Asegúrate de que FFmpeg esté instalado.")
                return False
            except Exception as e:
                print(f"Error al iniciar recepción FFplay: {e}")
                return False
    
    def _start_rx_monitoring(self):
        """Monitorear recepción en hilo separado"""
        if self.rx_monitoring:
            return
        
        self.rx_monitoring = True
        self.rx_monitor_thread = threading.Thread(target=self._monitor_rx, daemon=True)
        self.rx_monitor_thread.start()
    
    def _monitor_rx(self):
        """Monitorear el proceso de recepción"""
        while self.rx_monitoring and self.receive_process:
            try:
                if self.receive_process.poll() is not None:
                    # Proceso terminado
                    self.rx_monitoring = False
                    print("⚠️  Proceso de recepción terminado")
                    with self.rx_lock:
                        self.receive_process = None
                    break
                time.sleep(0.5)
            except Exception as e:
                print(f"Error en monitoreo RX: {e}")
                break
    
    def stop_reception(self):
        """Detener recepción activa de forma thread-safe"""
        with self.rx_lock:
            if self.receive_process is not None:
                try:
                    print("Deteniendo recepción...")
                    # Usar SIGTERM primero (graceful shutdown)
                    os.killpg(os.getpgid(self.receive_process.pid), signal.SIGTERM)
                    
                    try:
                        self.receive_process.wait(timeout=3)
                    except subprocess.TimeoutExpired:
                        print("  Forzando terminación...")
                        os.killpg(os.getpgid(self.receive_process.pid), signal.SIGKILL)
                        self.receive_process.wait()
                except Exception as e:
                    print(f"Error al detener recepción: {e}")
                finally:
                    self.receive_process = None
                    self.rx_monitoring = False
                    print("✓ Recepción detenida")
    
    def is_transmitting(self):
        """Verificar si hay transmisión activa (thread-safe)"""
        with self.tx_lock:
            return self.transmit_process is not None and self.transmit_process.poll() is None
    
    def is_receiving(self):
        """Verificar si hay recepción activa (thread-safe)"""
        with self.rx_lock:
            return self.receive_process is not None and self.receive_process.poll() is None
    
    def cleanup(self):
        """Limpiar todos los procesos activos de forma thread-safe"""
        print("Limpiando procesos...")
        self.stop_transmission()
        self.stop_reception()
        
        # Esperar a que se terminen los hilos de monitoreo
        if self.tx_monitor_thread and self.tx_monitor_thread.is_alive():
            self.tx_monitor_thread.join(timeout=2)
        if self.rx_monitor_thread and self.rx_monitor_thread.is_alive():
            self.rx_monitor_thread.join(timeout=2)
        
        print("Limpieza completada")
