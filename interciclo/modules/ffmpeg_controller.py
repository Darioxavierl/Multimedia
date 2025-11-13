"""
Controlador de FFmpeg y FFplay
Maneja la transmisión y recepción de video/audio
"""

import subprocess
import signal
import os


class FFmpegController:
    def __init__(self):
        """Inicializar controlador de FFmpeg"""
        self.transmit_process = None
        self.receive_process = None
    
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
            "-c:a", params['audio_codec'],
            "-b:a", f"{params['audio_bitrate']}k",
            "-ar", str(params['muestras']),
            "-ac", str(params['canales_audio_output']),
            "-f", params['protocolo'],
            params['direccion_tx']
        ]
        return cmd
    
    def build_receive_command(self, params, win_id, video_size):
        """
        Construir comando de recepción FFplay
        
        Args:
            params: Diccionario con parámetros de configuración
            win_id: ID de la ventana para embeber el video
            video_size: Tupla (width, height) del widget
            
        Returns:
            list: Comando como lista de argumentos
        """
        cmd = [
            "ffplay",
            "-probesize", params['probesize'],
            "-x", str(video_size[0]),
            "-y", str(video_size[1]),
            "-window_id", str(win_id),
            "-fflags", "nobuffer",
            "-flags", "low_delay",
            "-framedrop",
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
                preexec_fn=os.setsid  # Crear nuevo grupo de procesos
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
                # Enviar SIGTERM al grupo de procesos
                os.killpg(os.getpgid(self.transmit_process.pid), signal.SIGTERM)
                self.transmit_process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                # Si no termina, forzar con SIGKILL
                os.killpg(os.getpgid(self.transmit_process.pid), signal.SIGKILL)
                self.transmit_process.wait()
            except Exception as e:
                print(f"Error al detener transmisión: {e}")
            finally:
                self.transmit_process = None
                print("Transmisión detenida")
    
    def start_reception(self, params, win_id, video_size):
        """
        Iniciar recepción de video/audio
        
        Args:
            params: Diccionario con parámetros de configuración
            win_id: ID de la ventana para embeber el video
            video_size: Tupla (width, height) del widget
            
        Returns:
            bool: True si se inició correctamente
        """
        if self.receive_process is not None:
            print("Ya hay una recepción activa")
            return False
        
        try:
            cmd = self.build_receive_command(params, win_id, video_size)
            print(f"Iniciando recepción: {' '.join(cmd)}")
            
            self.receive_process = subprocess.Popen(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                preexec_fn=os.setsid  # Crear nuevo grupo de procesos
            )
            return True
        except FileNotFoundError:
            print("Error: FFplay no encontrado. Asegúrate de que FFmpeg esté instalado.")
            return False
        except Exception as e:
            print(f"Error al iniciar recepción: {e}")
            return False
    
    def stop_reception(self):
        """Detener recepción activa"""
        if self.receive_process is not None:
            try:
                # Enviar SIGTERM al grupo de procesos
                os.killpg(os.getpgid(self.receive_process.pid), signal.SIGTERM)
                self.receive_process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                # Si no termina, forzar con SIGKILL
                os.killpg(os.getpgid(self.receive_process.pid), signal.SIGKILL)
                self.receive_process.wait()
            except Exception as e:
                print(f"Error al detener recepción: {e}")
            finally:
                self.receive_process = None
                print("Recepción detenida")
    
    def is_transmitting(self):
        """Verificar si hay transmisión activa"""
        return self.transmit_process is not None and self.transmit_process.poll() is None
    
    def is_receiving(self):
        """Verificar si hay recepción activa"""
        return self.receive_process is not None and self.receive_process.poll() is None
    
    def get_transmit_stats(self):
        """
        Obtener estadísticas de transmisión (si están disponibles)
        
        Returns:
            dict: Estadísticas o None si no hay transmisión activa
        """
        if not self.is_transmitting():
            return None
        
        # Aquí podrías parsear stderr de FFmpeg para obtener estadísticas
        # Por ahora solo retornamos el estado
        return {
            "active": True,
            "pid": self.transmit_process.pid
        }
    
    def get_receive_stats(self):
        """
        Obtener estadísticas de recepción (si están disponibles)
        
        Returns:
            dict: Estadísticas o None si no hay recepción activa
        """
        if not self.is_receiving():
            return None
        
        return {
            "active": True,
            "pid": self.receive_process.pid
        }
    
    def cleanup(self):
        """Limpiar todos los procesos activos"""
        print("Limpiando procesos...")
        self.stop_transmission()
        self.stop_reception()
        print("Limpieza completada")