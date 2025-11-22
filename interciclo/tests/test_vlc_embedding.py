#!/usr/bin/env python3
"""
Script de prueba para verificar embedding de VLC en PyQt6
Basado en tu código de prueba exitoso
"""

import sys
import vlc
from PyQt6.QtWidgets import (QApplication, QMainWindow, QWidget, QVBoxLayout, 
                             QPushButton, QLabel, QFrame, QLineEdit, QHBoxLayout)
from PyQt6.QtCore import Qt


class VideoWidget(QFrame):
    """Widget para contener el video de VLC embebido"""
    def __init__(self):
        super().__init__()
        self.setMinimumSize(640, 480)
        self.setStyleSheet("background-color: black; border: 2px solid #555;")
        
        # Necesario para embebido real
        self.setAttribute(Qt.WidgetAttribute.WA_NativeWindow, True)
        self.setAttribute(Qt.WidgetAttribute.WA_DontCreateNativeAncestors, True)


class TestWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Test VLC Embedding - UDP Stream")
        self.setGeometry(100, 100, 900, 700)
        
        # Inicializar VLC con parámetros optimizados
        self.vlc_instance = vlc.Instance(
            "--no-video-title-show",
            "--network-caching=0",
            "--live-caching=10",
            "--drop-late-frames",
            "--skip-frames",
            "--clock-jitter=0",
            "--clock-synchro=0",
            "--codec=avcodec",
        )
        self.player = self.vlc_instance.media_player_new()
        
        # UI
        central = QWidget()
        self.setCentralWidget(central)
        layout = QVBoxLayout(central)
        
        # Info
        title = QLabel("Test: Embedding VLC + UDP Stream")
        title.setStyleSheet("font-size: 16px; font-weight: bold; padding: 10px;")
        layout.addWidget(title)
        
        # Campo de URL
        url_layout = QHBoxLayout()
        url_layout.addWidget(QLabel("URL Stream:"))
        self.url_input = QLineEdit("udp://@:5000")
        self.url_input.setMinimumWidth(300)
        url_layout.addWidget(self.url_input)
        url_layout.addStretch()
        layout.addLayout(url_layout)
        
        # Widget de video
        self.video_widget = VideoWidget()
        layout.addWidget(self.video_widget)
        
        # Botones
        buttons_layout = QHBoxLayout()
        
        self.start_btn = QPushButton("▶ Iniciar Recepción UDP")
        self.start_btn.clicked.connect(self.start_udp)
        self.start_btn.setStyleSheet("background-color: #4CAF50; color: white; padding: 10px;")
        buttons_layout.addWidget(self.start_btn)
        
        self.stop_btn = QPushButton("⏹ Detener")
        self.stop_btn.clicked.connect(self.stop_udp)
        self.stop_btn.setEnabled(False)
        self.stop_btn.setStyleSheet("background-color: #f44336; color: white; padding: 10px;")
        buttons_layout.addWidget(self.stop_btn)
        
        layout.addLayout(buttons_layout)
        
        # Status
        self.status = QLabel("Status: Listo para recibir stream UDP")
        self.status.setStyleSheet("padding: 10px; background-color: #e0e0e0;")
        layout.addWidget(self.status)
        
        # Instrucciones
        instructions = QLabel(
            "Instrucciones:\n"
            "1. En otro terminal, transmite con FFmpeg:\n"
            "   ffmpeg -re -f lavfi -i testsrc=size=1280x720:rate=30 \\\n"
            "          -f lavfi -i sine=frequency=1000 \\\n"
            "          -c:v libx264 -preset ultrafast -tune zerolatency \\\n"
            "          -c:a aac -f mpegts udp://localhost:5000\n\n"
            "2. Click en 'Iniciar Recepción UDP'\n"
            "3. Deberías ver el video de prueba en el widget negro"
        )
        instructions.setStyleSheet("padding: 10px; background-color: #ffffcc; font-family: monospace;")
        layout.addWidget(instructions)
    
    def start_udp(self):
        """Iniciar recepción UDP con VLC"""
        url = self.url_input.text()
        wid = int(self.video_widget.winId())
        
        print(f"Iniciando VLC con URL: {url}")
        print(f"Window ID: {wid}")
        
        # Enlazar VLC al widget de Qt
        self.player.set_xwindow(wid)
        
        # Crear media desde URL
        media = self.vlc_instance.media_new(url)
        self.player.set_media(media)
        
        # Reproducir
        self.player.play()
        
        self.status.setText(f"Status: Reproduciendo {url}")
        self.status.setStyleSheet("padding: 10px; background-color: #4CAF50; color: white;")
        self.start_btn.setEnabled(False)
        self.stop_btn.setEnabled(True)
        
        print("✓ VLC iniciado")
    
    def stop_udp(self):
        """Detener recepción"""
        self.player.stop()
        
        self.status.setText("Status: Detenido")
        self.status.setStyleSheet("padding: 10px; background-color: #e0e0e0;")
        self.start_btn.setEnabled(True)
        self.stop_btn.setEnabled(False)
        
        print("Detenido")
    
    def closeEvent(self, event):
        """Limpiar al cerrar"""
        self.player.stop()
        event.accept()


if __name__ == "__main__":
    print("=" * 60)
    print("Test de Embedding VLC en PyQt6")
    print("=" * 60)
    print("")
    print("Este script prueba la recepción de stream UDP con VLC")
    print("embebido en un widget de PyQt6.")
    print("")
    print("Para generar un stream de prueba, ejecuta en otro terminal:")
    print("")
    print("  ffmpeg -re -f lavfi -i testsrc=size=1280x720:rate=30 \\")
    print("         -f lavfi -i sine=frequency=1000 \\")
    print("         -c:v libx264 -preset ultrafast -tune zerolatency \\")
    print("         -c:a aac -f mpegts udp://localhost:5000")
    print("")
    print("=" * 60)
    print("")
    
    app = QApplication(sys.argv)
    window = TestWindow()
    window.show()
    sys.exit(app.exec())