
#!/usr/bin/env python3
"""
VideoConferencia P2P con FFmpeg
Aplicación principal
"""

import sys
from pathlib import Path
from PyQt6.QtWidgets import (QApplication, QMainWindow, QWidget, QVBoxLayout, 
                            QHBoxLayout, QGroupBox, QLabel, QPushButton, 
                            QComboBox, QTabWidget, QMessageBox, QFrame)
from PyQt6.QtCore import Qt, QTimer

# Importar módulos propios
from modules.profile_manager import ProfileManager
from modules.ffmpeg_controller import FFmpegController
from modules.ui_components import create_spin_field, create_text_field


class VideoConferenceApp(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("VideoConferencia P2P - FFmpeg")
        self.setGeometry(100, 100, 800, 800)
        
        # Inicializar managers
        self.profile_manager = ProfileManager()
        self.ffmpeg_controller = FFmpegController(player_type="ffplay")  
        
        # Diccionario para almacenar widgets de parámetros
        self.params = {}
        
        # Timer para monitoreo de procesos
        self.monitor_timer = QTimer(self)
        self.monitor_timer.timeout.connect(self._monitor_processes)
        self.monitor_timer.start(1000)  # Revisar cada 1 segundo
        
        self.init_ui()
        
    def init_ui(self):
        central_widget = QWidget()
        self.setCentralWidget(central_widget)
        main_layout = QHBoxLayout(central_widget)
        main_layout.setContentsMargins(0, 0, 0, 0)  # Sin márgenes
        
        # Panel izquierdo - Controles (ancho fijo)
        left_panel = self.create_control_panel()
        left_panel.setMaximumWidth(450)
        main_layout.addWidget(left_panel, 0)  # Stretch factor = 0 (no expande)
        
        # Panel derecho - Video (expande para llenar espacio)
        #right_panel = self.create_video_panel()
        #main_layout.addWidget(right_panel, 1)  # Stretch factor = 1 (toma todo espacio sobrante)
        
        # Cargar perfil por defecto
        self.load_profile("cercano")
        
    def create_control_panel(self):
        """Crear panel de controles"""
        panel = QWidget()
        layout = QVBoxLayout(panel)
        
        # Selector de perfiles
        profile_group = QGroupBox("Perfiles de Configuración")
        profile_layout = QHBoxLayout()
        self.profile_combo = QComboBox()
        self.profile_combo.addItems(["cercano", "medio", "lejano"])
        self.profile_combo.currentTextChanged.connect(self.load_profile)
        profile_layout.addWidget(QLabel("Perfil:"))
        profile_layout.addWidget(self.profile_combo)
        
        save_btn = QPushButton("Guardar")
        save_btn.clicked.connect(self.save_current_profile)
        save_btn.setStyleSheet("padding: 5px;")
        profile_layout.addWidget(save_btn)
        profile_group.setLayout(profile_layout)
        layout.addWidget(profile_group)
        
        # Selector de reproductor de video - REMOVIDO: Solo FFplay
        # VLC fue removido para simplificar la arquitectura
        
        info_label = QLabel("ℹFFplay abrirá en ventana externa")
        info_label.setStyleSheet("background-color: #f0f0f0; padding: 5px; border-radius: 3px;")
        layout.addWidget(info_label)
        
        layout.addSpacing(10)
        
        # Tabs para configuración
        tabs = self.create_config_tabs()
        layout.addWidget(tabs)
        
        # Botones de control
        control_group = self.create_control_buttons()
        layout.addWidget(control_group)
        
        # Status
        self.status_label = QLabel("Estado: Listo")
        self.status_label.setStyleSheet("padding: 5px; background-color: #e0e0e0;")
        layout.addWidget(self.status_label)
        
        return panel
    
    def create_config_tabs(self):
        """Crear tabs de configuración"""
        tabs = QTabWidget()
        
        # Tab Video
        video_tab = QWidget()
        video_layout = QVBoxLayout(video_tab)
        
        #self.params['fps_entrada'] = create_spin_field(video_layout, "FPS Entrada:", 1, 120, 30)
        #self.params['fps_salida'] = create_spin_field(video_layout, "FPS Salida:", 1, 120, 30)
        #self.params['gop'] = create_spin_field(video_layout, "GOP:", 1, 300, 30)
        self.params['width'] = create_spin_field(video_layout, "Ancho:", 320, 3840, 1920)
        self.params['height'] = create_spin_field(video_layout, "Alto:", 240, 2160, 1080)
        self.params['video_device'] = create_text_field(video_layout, "Dispositivo Video:", "/dev/video0")
        self.params['video_bitrate'] = create_spin_field(video_layout, "Bitrate Video (kbps):", 100, 50000, 8000)
        self.params['controlador'] = create_text_field(video_layout, "Controlador:", "v4l2")
        
        video_layout.addStretch()
        tabs.addTab(video_tab, "Video")
        
        # Tab Audio
        audio_tab = QWidget()
        audio_layout = QVBoxLayout(audio_tab)
        
        self.params['canales_audio_input'] = create_spin_field(audio_layout, "Canales Input:", 1, 8, 2)
        self.params['canales_audio_output'] = create_spin_field(audio_layout, "Canales Output:", 1, 8, 2)
        self.params['audio_codec'] = create_text_field(audio_layout, "Codec Audio:", "mp3")
        self.params['audio_device'] = create_text_field(audio_layout, "Dispositivo Audio:", "hw:1,6")
        self.params['audio_bitrate'] = create_spin_field(audio_layout, "Bitrate Audio (kbps):", 1, 512, 128)
        self.params['muestras'] = create_spin_field(audio_layout, "Sample Rate (Hz):", 8000, 96000, 48000)
        
        audio_layout.addStretch()
        tabs.addTab(audio_tab, "Audio")
        
        # Tab Red
        red_tab = QWidget()
        red_layout = QVBoxLayout(red_tab)
        
        self.params['protocolo'] = create_text_field(red_layout, "Protocolo:", "mpegts")
        self.params['direccion_tx'] = create_text_field(red_layout, "Dirección TX:", "udp://10.42.0.48:39400")
        self.params['direccion_rx'] = create_text_field(red_layout, "Dirección RX:", "udp://@:39400")
        self.params['probesize'] = create_text_field(red_layout, "Probesize:", "32000")
        
        red_layout.addStretch()
        tabs.addTab(red_tab, "Red")
        
        return tabs
    
    def create_control_buttons(self):
        """Crear grupo de botones de control"""
        control_group = QGroupBox("Control")
        control_layout = QVBoxLayout()
        
        self.start_tx_btn = QPushButton("▶ Iniciar Transmisión")
        self.start_tx_btn.clicked.connect(self.start_transmission)
        self.start_tx_btn.setStyleSheet("background-color: #4CAF50; color: white; padding: 10px;")
        
        self.stop_tx_btn = QPushButton("⏹ Detener Transmisión")
        self.stop_tx_btn.clicked.connect(self.stop_transmission)
        self.stop_tx_btn.setEnabled(False)
        self.stop_tx_btn.setStyleSheet("background-color: #f44336; color: white; padding: 10px;")
        
        self.start_rx_btn = QPushButton("▶ Iniciar Recepción")
        self.start_rx_btn.clicked.connect(self.start_reception)
        self.start_rx_btn.setStyleSheet("background-color: #2196F3; color: white; padding: 10px;")
        
        self.stop_rx_btn = QPushButton("⏹ Detener Recepción")
        self.stop_rx_btn.clicked.connect(self.stop_reception)
        self.stop_rx_btn.setEnabled(False)
        self.stop_rx_btn.setStyleSheet("background-color: #f44336; color: white; padding: 10px;")
        
        control_layout.addWidget(self.start_tx_btn)
        control_layout.addWidget(self.stop_tx_btn)
        control_layout.addWidget(self.start_rx_btn)
        control_layout.addWidget(self.stop_rx_btn)
        
        control_group.setLayout(control_layout)
        return control_group
    
    def create_video_panel(self):
        """Crear panel de video"""
        panel = QWidget()
        layout = QVBoxLayout(panel)
        layout.setContentsMargins(0, 0, 0, 0)  # Sin márgenes
        layout.setSpacing(0)                    # Sin espacios
        
        self.video_label = QLabel("Video Recibido (VLC embebido):")
        self.video_label.setStyleSheet("padding: 5px; background-color: #333; color: white; font-weight: bold;")
        layout.addWidget(self.video_label)
        
        
        self.video_widget = VideoWidget()
        layout.addWidget(self.video_widget, 1) 
        
        # Asegurar que el panel también se expande
        panel.setStyleSheet("background-color: black;")
        
        return panel
    
    
    def get_current_params(self):
        """Obtener parámetros actuales de la UI"""
        params = {}
        for key, widget in self.params.items():
            if hasattr(widget, 'value'):  # QSpinBox
                params[key] = widget.value()
            else:  # QLineEdit
                params[key] = widget.text()
        return params
    
    def load_profile(self, profile_name):
        """Cargar un perfil específico"""
        profile = self.profile_manager.load_profile(profile_name)
        if profile:
            # Cargar solo los valores que están en el perfil
            for key, value in profile.items():
                if key in self.params:
                    widget = self.params[key]
                    if hasattr(widget, 'setValue'):  # QSpinBox
                        widget.setValue(value)
                    else:  # QLineEdit
                        widget.setText(str(value))
            
            self.status_label.setText(f"Perfil '{profile_name}' cargado")
    
    def save_current_profile(self):
        """Guardar configuración actual en el perfil seleccionado"""
        profile_name = self.profile_combo.currentText()
        params = self.get_current_params()
        
        # Guardar solo los parámetros relevantes del perfil
        profile_params = {
            #'fps_entrada': params['fps_entrada'],
            #'fps_salida': params['fps_salida'],
            #'gop': params['gop'],
            'width': params['width'],
            'height': params['height'],
            'video_bitrate': params['video_bitrate'],
            'audio_bitrate': params['audio_bitrate'],
            'muestras': params['muestras']
        }
        
        if self.profile_manager.save_profile(profile_name, profile_params):
            QMessageBox.information(self, "Guardado", f"Perfil '{profile_name}' guardado exitosamente")
        else:
            QMessageBox.warning(self, "Error", "No se pudo guardar el perfil")
    
    def start_transmission(self):
        """Iniciar transmisión con FFmpeg"""
        params = self.get_current_params()
        
        if self.ffmpeg_controller.start_transmission(params):
            self.start_tx_btn.setEnabled(False)
            self.stop_tx_btn.setEnabled(True)
            self.status_label.setText("Estado: Transmitiendo...")
            self.status_label.setStyleSheet("padding: 5px; background-color: #4CAF50; color: white;")
        else:
            QMessageBox.critical(self, "Error", "Error al iniciar transmisión. Verifica los dispositivos.")
    
    def stop_transmission(self):
        """Detener transmisión"""
        self.ffmpeg_controller.stop_transmission()
        self.start_tx_btn.setEnabled(True)
        self.stop_tx_btn.setEnabled(False)
        self.status_label.setText("Estado: Transmisión detenida")
        self.status_label.setStyleSheet("padding: 5px; background-color: #e0e0e0;")
    
    def start_reception(self):
        """Iniciar recepción con FFplay"""
        params = self.get_current_params()
        
        print(f"Iniciando recepción con FFplay...")
        
        if self.ffmpeg_controller.start_reception(params, None, None):
            self.start_rx_btn.setEnabled(False)
            self.stop_rx_btn.setEnabled(True)
            self.status_label.setText("Estado: Recibiendo con FFplay...")
            self.status_label.setStyleSheet("padding: 5px; background-color: #2196F3; color: white;")
            
            print("✓ FFplay iniciado - ventana de video abierta")
        else:
            error_msg = (
                "Error al iniciar recepción con FFplay.\n\n"
                "Verifica:\n"
                "- La dirección RX es correcta\n"
                "- El otro dispositivo está transmitiendo\n"
                "- No hay firewall bloqueando el puerto"
            )
            QMessageBox.critical(self, "Error de Recepción", error_msg)
    
    def stop_reception(self):
        """Detener recepción"""
        self.ffmpeg_controller.stop_reception()
        self.start_rx_btn.setEnabled(True)
        self.stop_rx_btn.setEnabled(False)
        self.status_label.setText("Estado: Recepción detenida")
        self.status_label.setStyleSheet("padding: 5px; background-color: #e0e0e0;")
    
    def _monitor_processes(self):
        """Monitorear estado de TX/RX y actualizar UI"""
        tx_active = self.ffmpeg_controller.is_transmitting()
        rx_active = self.ffmpeg_controller.is_receiving()
        
        # Actualizar botones si los procesos se cerraron inesperadamente
        if not tx_active and self.start_tx_btn.isEnabled() == False:
            self.start_tx_btn.setEnabled(True)
            self.stop_tx_btn.setEnabled(False)
            self.status_label.setText("Estado: Transmisión detenida (inesperadamente)")
            self.status_label.setStyleSheet("padding: 5px; background-color: #ff9800; color: white;")
        
        if not rx_active and self.start_rx_btn.isEnabled() == False:
            self.start_rx_btn.setEnabled(True)
            self.stop_rx_btn.setEnabled(False)
            self.status_label.setText("Estado: Recepción detenida (inesperadamente)")
            self.status_label.setStyleSheet("padding: 5px; background-color: #ff9800; color: white;")
    
    def closeEvent(self, event):
        """Limpiar al cerrar"""
        self.monitor_timer.stop()
        self.ffmpeg_controller.cleanup()
        event.accept()


def main():
    app = QApplication(sys.argv)
    window = VideoConferenceApp()
    window.show()
    sys.exit(app.exec())


if __name__ == '__main__':
    main()