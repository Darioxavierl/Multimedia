# Script de lanzamiento optimizado
#!/bin/bash
export QT_QPA_PLATFORM=xcb
export SDL_VIDEODRIVER=x11
export __GL_SYNC_TO_VBLANK=0

# Deshabilitar compositor (para XFCE)
xfconf-query -c xfwm4 -p /general/use_compositing -s false

python3 tests/test_ffplay_embedding.py

# Reactivar compositor al salir
xfconf-query -c xfwm4 -p /general/use_compositing -s true
