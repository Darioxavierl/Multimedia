"""
Componentes de interfaz de usuario reutilizables
"""

from PyQt6.QtWidgets import QLabel, QLineEdit, QSpinBox, QHBoxLayout, QWidget, QFrame
from PyQt6.QtCore import Qt


class VideoWidget(QWidget):
    """
    Widget para contener el video de VLC embebido
    
    Este widget proporciona una ventana X11 nativa donde VLC renderiza directamente.
    Qt NO debe pintar sobre este widget - solo proporciona la ventana.
    
    IMPORTANTE: Heredar de QWidget (no QFrame) evita sistema de pintura interno.
    """
    
    def __init__(self, parent=None):
        super().__init__(parent)
        
        # Tamaño
        self.setMinimumSize(640, 480)
        
        # Estilo: solo fondo negro
        self.setStyleSheet("background-color: black;")
        
        # Expandir
        self.setSizePolicy(
            self.sizePolicy().Policy.Expanding,
            self.sizePolicy().Policy.Expanding
        )
        
        # CRÍTICO: Hacer que sea ventana X11 NATIVA
        self.setAttribute(Qt.WidgetAttribute.WA_NativeWindow, True)
        self.setAttribute(Qt.WidgetAttribute.WA_DontCreateNativeAncestors, True)
        
        # CRÍTICO: Desactivar completamente el motor de pintura de Qt
        # Esto evita conflictos entre Qt y VLC
        self.setAttribute(Qt.WidgetAttribute.WA_PaintOnScreen, True)
        self.setAttribute(Qt.WidgetAttribute.WA_NoSystemBackground, True)
        self.setAttribute(Qt.WidgetAttribute.WA_OpaquePaintEvent, True)
        
        self.setVisible(True)
    
    def get_window_id(self):
        """
        Obtener el ID de ventana para FFplay/VLC
        
        Returns:
            int: Window ID que FFplay/VLC puede usar
        """
        return int(self.winId())
    
    def get_effective_window_id(self):
        """
        Obtener el ID de ventana efectiva (más confiable para X11)
        
        En algunos casos, effectiveWinId() es más confiable que winId()
        para embedding en X11.
        
        Returns:
            int: Effective Window ID
        """
        return int(self.effectiveWinId())
        
    def showEvent(self, event):
        """Se llama cuando el widget es mostrado en pantalla"""
        super().showEvent(event)
        print(f"  [VideoWidget] showEvent - tamaño: {self.size()}, pos: {self.pos()}")
        # NO hacer update() - dejar que sea manejado por VLC
    
    def resizeEvent(self, event):
        """Se llama cuando el widget cambia de tamaño"""
        super().resizeEvent(event)
        print(f"  [VideoWidget] resizeEvent - nuevo tamaño: {event.size()}")
    
    def paintEvent(self, event):
        """
        IMPORTANTE: No hacer NADA aquí.
        VLC pinta directamente sobre la ventana X11.
        Si Qt pinta aquí, bloquea a VLC.
        """
        # NO llamar a super() - evita que Qt pinte
        # NO dibujar nada - dejar que VLC lo haga
        pass


def create_spin_field(layout, label_text, min_val, max_val, default):
    """
    Crear un campo numérico (SpinBox) con etiqueta
    
    Args:
        layout: Layout donde agregar el campo
        label_text: Texto de la etiqueta
        min_val: Valor mínimo permitido
        max_val: Valor máximo permitido
        default: Valor por defecto
        
    Returns:
        QSpinBox: Widget SpinBox creado y configurado
    """
    h_layout = QHBoxLayout()
    
    # Crear etiqueta
    label = QLabel(label_text)
    label.setMinimumWidth(150)
    label.setAlignment(Qt.AlignmentFlag.AlignRight | Qt.AlignmentFlag.AlignVCenter)
    h_layout.addWidget(label)
    
    # Crear SpinBox
    spinbox = QSpinBox()
    spinbox.setMinimum(min_val)
    spinbox.setMaximum(max_val)
    spinbox.setValue(default)
    spinbox.setMinimumWidth(100)
    spinbox.setMaximumWidth(150)
    h_layout.addWidget(spinbox)
    
    # Agregar espacio flexible
    h_layout.addStretch()
    
    layout.addLayout(h_layout)
    return spinbox


def create_text_field(layout, label_text, default):
    """
    Crear un campo de texto (LineEdit) con etiqueta
    
    Args:
        layout: Layout donde agregar el campo
        label_text: Texto de la etiqueta
        default: Valor por defecto del campo
        
    Returns:
        QLineEdit: Widget LineEdit creado y configurado
    """
    h_layout = QHBoxLayout()
    
    # Crear etiqueta
    label = QLabel(label_text)
    label.setMinimumWidth(150)
    label.setAlignment(Qt.AlignmentFlag.AlignRight | Qt.AlignmentFlag.AlignVCenter)
    h_layout.addWidget(label)
    
    # Crear LineEdit
    lineedit = QLineEdit(default)
    lineedit.setMinimumWidth(200)
    h_layout.addWidget(lineedit)
    
    layout.addLayout(h_layout)
    return lineedit


def create_combo_field(layout, label_text, items, default_index=0):
    """
    Crear un campo de selección (ComboBox) con etiqueta
    
    Args:
        layout: Layout donde agregar el campo
        label_text: Texto de la etiqueta
        items: Lista de items para el ComboBox
        default_index: Índice del item seleccionado por defecto
        
    Returns:
        QComboBox: Widget ComboBox creado y configurado
    """
    from PyQt6.QtWidgets import QComboBox
    
    h_layout = QHBoxLayout()
    
    # Crear etiqueta
    label = QLabel(label_text)
    label.setMinimumWidth(150)
    label.setAlignment(Qt.AlignmentFlag.AlignRight | Qt.AlignmentFlag.AlignVCenter)
    h_layout.addWidget(label)
    
    # Crear ComboBox
    combobox = QComboBox()
    combobox.addItems(items)
    combobox.setCurrentIndex(default_index)
    combobox.setMinimumWidth(200)
    h_layout.addWidget(combobox)
    
    h_layout.addStretch()
    
    layout.addLayout(h_layout)
    return combobox


def create_button(text, callback, style="default"):
    """
    Crear un botón estilizado
    
    Args:
        text: Texto del botón
        callback: Función a ejecutar al hacer click
        style: Estilo del botón ("default", "success", "danger", "info")
        
    Returns:
        QPushButton: Botón configurado
    """
    from PyQt6.QtWidgets import QPushButton
    
    button = QPushButton(text)
    button.clicked.connect(callback)
    
    # Estilos predefinidos
    styles = {
        "success": "background-color: #4CAF50; color: white; padding: 10px; font-weight: bold;",
        "danger": "background-color: #f44336; color: white; padding: 10px; font-weight: bold;",
        "info": "background-color: #2196F3; color: white; padding: 10px; font-weight: bold;",
        "default": "padding: 8px;"
    }
    
    button.setStyleSheet(styles.get(style, styles["default"]))
    return button


def create_labeled_value(layout, label_text, value_text=""):
    """
    Crear una etiqueta con valor para mostrar información
    
    Args:
        layout: Layout donde agregar el campo
        label_text: Texto de la etiqueta
        value_text: Valor inicial
        
    Returns:
        QLabel: Label del valor (para actualizar después)
    """
    h_layout = QHBoxLayout()
    
    label = QLabel(label_text)
    label.setMinimumWidth(150)
    label.setAlignment(Qt.AlignmentFlag.AlignRight | Qt.AlignmentFlag.AlignVCenter)
    h_layout.addWidget(label)
    
    value_label = QLabel(value_text)
    value_label.setStyleSheet("font-weight: bold;")
    h_layout.addWidget(value_label)
    
    h_layout.addStretch()
    
    layout.addLayout(h_layout)
    return value_label


class StatusBar(QFrame):
    """
    Barra de estado personalizada con colores
    """
    
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setFrameStyle(QFrame.Shape.StyledPanel)
        
        layout = QHBoxLayout(self)
        self.label = QLabel("Estado: Listo")
        layout.addWidget(self.label)
        
        self.set_status("Listo", "default")
    
    def set_status(self, text, status_type="default"):
        """
        Actualizar el estado con texto y color
        
        Args:
            text: Texto del estado
            status_type: Tipo de estado ("default", "success", "error", "warning", "info")
        """
        self.label.setText(f"Estado: {text}")
        
        colors = {
            "default": "#e0e0e0",
            "success": "#4CAF50",
            "error": "#f44336",
            "warning": "#FF9800",
            "info": "#2196F3"
        }
        
        bg_color = colors.get(status_type, colors["default"])
        text_color = "white" if status_type != "default" else "black"
        
        self.setStyleSheet(f"padding: 5px; background-color: {bg_color}; color: {text_color};")