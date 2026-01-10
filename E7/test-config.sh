#!/bin/bash

# Script de prueba de configuraciones
# Uso: ./test-config.sh [ultra-estable|balanceado|ultra-rapido]

CONFIG=${1:-balanceado}

echo "[+] Configurando modo: $CONFIG"
echo ""

case $CONFIG in
  "ultra-estable")
    echo "[+] Configuración ULTRA ESTABLE"
    echo "   - Latencia esperada: ~3-3.5 segundos"
    echo "   - Cortes: Casi ninguno"
    echo "   - Ideal para: Conexiones inestables"
    echo ""
    
    # Parámetros a ajustar manualmente:
    echo "[+]  Edita estos archivos:"
    echo ""
    echo "1. www/html/js/video-player.js"
    echo "   Copia el contenido de: configs/video-player-ultra-estable.js"
    echo "   Línea 31 (función configurePlayer)"
    echo ""
    echo "2. backend/main.py"
    echo "   Copia el contenido de: configs/ffmpeg-ultra-estable.txt"
    echo "   Línea 72 (variable command)"
    echo ""
    echo "3. Ejecuta: ./rebuild.sh"
    echo "4. Recarga la página: Ctrl+F5"
    ;;
    
  "ultra-rapido")
    echo "⚡ Configuración ULTRA RÁPIDA"
    echo "   - Latencia esperada: ~1.5-2 segundos"
    echo "   - Cortes: Posibles en red lenta"
    echo "   - Ideal para: Mínima latencia, red estable"
    echo ""
    
    echo "[+]  Edita estos archivos:"
    echo ""
    echo "1. www/html/js/video-player.js"
    echo "   Copia el contenido de: configs/video-player-ultra-rapido.js"
    echo "   Línea 31 (función configurePlayer)"
    echo ""
    echo "2. backend/main.py"
    echo "   Copia el contenido de: configs/ffmpeg-ultra-rapido.txt"
    echo "   Línea 72 (variable command)"
    echo ""
    echo "3. Ejecuta: ./rebuild.sh"
    echo "4. Recarga la página: Ctrl+F5"
    ;;
    
  "balanceado")
    echo "[+]  Configuración BALANCEADA (ACTUAL)"
    echo "   - Latencia esperada: ~2-2.5 segundos"
    echo "   - Cortes: Ocasionales"
    echo "   - Ideal para: Balance latencia/estabilidad"
    echo ""
    echo "[+] Esta es la configuración actual"
    echo "   No necesitas hacer cambios"
    ;;
    
  *)
    echo "[+] Configuración no válida"
    echo ""
    echo "Uso: ./test-config.sh [ultra-estable|balanceado|ultra-rapido]"
    echo ""
    echo "Configuraciones disponibles:"
    echo "  ultra-estable  - Máxima estabilidad, mayor latencia (~3 seg)"
    echo "  balanceado     - Balance (actual) (~2.5 seg)"
    echo "  ultra-rapido   - Mínima latencia, menos estable (~1.5 seg)"
    exit 1
    ;;
esac

echo ""
echo "[+] Más información en: GUIA_AJUSTE.md"
