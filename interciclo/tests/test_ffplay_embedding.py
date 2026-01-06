#!/usr/bin/env python3

import sys
import vlc
from PyQt6.QtWidgets import QApplication, QMainWindow, QWidget, QVBoxLayout, QPushButton, QLabel, QFrame
from PyQt6.QtCore import Qt, QTimer


class VideoWidget(QFrame):
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
        self.setGeometry(100, 100, 800, 600)

        self.vlc_instance = vlc.Instance(
    "--no-video-title-show",
    "--network-caching=50",       # prueba con 0–50
    "--live-caching=50",
    "--drop-late-frames",
    "--skip-frames",
    "--clock-jitter=0",
    "--clock-synchro=0",
    "--codec=avcodec",            # evita usar decoders lentos de software alternativos
)
        self.player = self.vlc_instance.media_player_new()

        central = QWidget()
        self.setCentralWidget(central)
        layout = QVBoxLayout(central)

        layout.addWidget(QLabel("Test: Embedding VLC inside PyQt6 + UDP stream"))

        self.video_widget = VideoWidget()
        layout.addWidget(self.video_widget)

        self.start_btn = QPushButton("Iniciar UDP Player")
        self.start_btn.clicked.connect(self.start_udp)
        layout.addWidget(self.start_btn)

        self.stop_btn = QPushButton("Detener")
        self.stop_btn.clicked.connect(self.stop_udp)
        self.stop_btn.setEnabled(False)
        layout.addWidget(self.stop_btn)

        self.status = QLabel("Status: Listo")
        layout.addWidget(self.status)

    def start_udp(self):
        wid = int(self.video_widget.winId())
        print("Window ID:", wid)

        # Enlazar VLC al widget
        self.player.set_xwindow(wid)   # Ubuntu / Linux

        # URL del stream UDP que estés usando
        media = self.vlc_instance.media_new("udp://@:5000")

        self.player.set_media(media)
        self.player.play()

        self.status.setText("Status: Reproduciendo UDP en VLC")
        self.start_btn.setEnabled(False)
        self.stop_btn.setEnabled(True)

    def stop_udp(self):
        self.player.stop()
        self.status.setText("Status: Detenido")
        self.start_btn.setEnabled(True)
        self.stop_btn.setEnabled(False)

    def closeEvent(self, event):
        self.player.stop()
        event.accept()


if __name__ == "__main__":
    app = QApplication(sys.argv)
    window = TestWindow()
    window.show()
    sys.exit(app.exec())
