#modules/ffmpeg_controller.py
"""
Controlador de FFmpeg y FFplay
Maneja la transmisión y recepción de video/audio (FFplay only)
"""

import subprocess
import signal
import os


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
        
        print(f"✅ FFmpegController inicializado - usando {self.player_type}")
    
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
            
        Returns:
            list: Comando como lista de argumentos
        """
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
        Iniciar transmisión de video/audio
        
        Args:
            params: Diccionario con parámetros de configuración
            
        Returns:
            bool: True si se inició correctamente
        """
        if self.transmit_process is not None:
            print("Ya hay una transmisión activa")
            return False
        
        try:
            cmd = self.build_transmit_command(params)
            print(f"Iniciando transmisión: {' '.join(cmd)}")
            
            self.transmit_process = subprocess.Popen(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                preexec_fn=os.setsid
            )
            return True
        except FileNotFoundError:
            print("Error: FFmpeg no encontrado. Asegúrate de que esté instalado.")
            return False
        except Exception as e:
            print(f"Error al iniciar transmisión: {e}")
            return False
    
    def stop_transmission(self):
        """Detener transmisión activa"""
        if self.transmit_process is not None:
            try:
                os.killpg(os.getpgid(self.transmit_process.pid), signal.SIGTERM)
                self.transmit_process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                os.killpg(os.getpgid(self.transmit_process.pid), signal.SIGKILL)
                self.transmit_process.wait()
            except Exception as e:
                print(f"Error al detener transmisión: {e}")
            finally:
                self.transmit_process = None
                print("Transmisión detenida")
    
    def start_reception(self, params, win_id=None, video_size=None):
        """
        Iniciar recepción de video/audio
        
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
        """Iniciar recepción con FFplay (ventana externa)"""
        if self.receive_process is not None:
            print("Ya hay una recepción FFplay activa")
            return False
        
        try:
            cmd = self.build_receive_command_ffplay(params)
            print(f"Iniciando recepción FFplay: {' '.join(cmd)}")
            
            self.receive_process = subprocess.Popen(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                preexec_fn=os.setsid
            )
            return True
        except FileNotFoundError:
            print("Error: FFplay no encontrado. Asegúrate de que FFmpeg esté instalado.")
            return False
        except Exception as e:
            print(f"Error al iniciar recepción FFplay: {e}")
            return False
    
    def stop_reception(self):
        """Detener recepción activa"""
        if self.receive_process is not None:
            try:
                os.killpg(os.getpgid(self.receive_process.pid), signal.SIGTERM)
                self.receive_process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                os.killpg(os.getpgid(self.receive_process.pid), signal.SIGKILL)
                self.receive_process.wait()
            except Exception as e:
                print(f"Error al detener recepción FFplay: {e}")
            finally:
                self.receive_process = None
                print("Recepción detenida")
    
    def is_transmitting(self):
        """Verificar si hay transmisión activa"""
        return self.transmit_process is not None and self.transmit_process.poll() is None
    
    def is_receiving(self):
        """Verificar si hay recepción activa (FFplay)"""
        return self.receive_process is not None and self.receive_process.poll() is None
    
    def cleanup(self):
        """Limpiar todos los procesos activos"""
        print("Limpiando procesos...")
        self.stop_transmission()
        self.stop_reception()
        print("Limpieza completada")