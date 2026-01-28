#!/bin/bash

# Script para comparación visual de videos H264 vs VP8
# Uso: ./compare_videos.sh [1|2|3]
#   1 = akiyo_cif
#   2 = coastguard_cif
#   3 = ElephantsDream

# Directorios
H264_DIR="h264"
VP8_DIR="vp8"
TEMP_DIR="temp_vid"
mkdir -p "$TEMP_DIR"

# Validar parámetro
if [ -z "$1" ]; then
    echo "Error: Debe especificar el número de video a comparar"
    echo "Uso: $0 [1|2|3]"
    echo "  1 = akiyo_cif"
    echo "  2 = coastguard_cif"
    echo "  3 = ElephantsDream"
    exit 1
fi

# Seleccionar video según parámetro
case $1 in
    1)
        VIDEO_NAME="akiyo_cif"
        DISPLAY_NAME="Akiyo CIF"
        ;;
    2)
        VIDEO_NAME="coastguard_cif"
        DISPLAY_NAME="Coastguard CIF"
        ;;
    3)
        VIDEO_NAME="ElephantsDream"
        DISPLAY_NAME="Elephants Dream"
        ;;
    *)
        echo "Error: Opción inválida '$1'"
        echo "Debe ser 1, 2 o 3"
        exit 1
        ;;
esac

echo "==================================="
echo "Comparación Visual: $DISPLAY_NAME"
echo "==================================="
echo ""

# Rutas de videos
H264_BR="$H264_DIR/BR/${VIDEO_NAME}_BR.mp4"
H264_QP="$H264_DIR/QP/${VIDEO_NAME}_QP.mp4"
VP8_BR="$VP8_DIR/BR/${VIDEO_NAME}_BR.webm"
VP8_QP="$VP8_DIR/QP/${VIDEO_NAME}_QP.webm"

# Verificar que existen los archivos
if [ ! -f "$H264_BR" ]; then
    echo "Error: No se encuentra $H264_BR"
    exit 1
fi
if [ ! -f "$H264_QP" ]; then
    echo "Error: No se encuentra $H264_QP"
    exit 1
fi
if [ ! -f "$VP8_BR" ]; then
    echo "Error: No se encuentra $VP8_BR"
    exit 1
fi
if [ ! -f "$VP8_QP" ]; then
    echo "Error: No se encuentra $VP8_QP"
    exit 1
fi

# Archivos de salida temporal
COMPARISON_BR="$TEMP_DIR/${VIDEO_NAME}_comparison_BR.mp4"
COMPARISON_QP="$TEMP_DIR/${VIDEO_NAME}_comparison_QP.mp4"

echo "[1/4] Generando comparación Bitrate (H264 vs VP8)..."
ffmpeg -i "$H264_BR" -i "$VP8_BR" -filter_complex "\
    [0:v]scale=640:-1,drawtext=text='H.264 Bitrate':fontsize=24:fontcolor=white:box=1:boxcolor=black@0.5:boxborderw=5:x=(w-text_w)/2:y=10[v0]; \
    [1:v]scale=640:-1,drawtext=text='VP8 Bitrate':fontsize=24:fontcolor=white:box=1:boxcolor=black@0.5:boxborderw=5:x=(w-text_w)/2:y=10[v1]; \
    [v0][v1]hstack=inputs=2[v]" \
    -map "[v]" -map 0:a? -c:v libx264 -preset fast -crf 18 -c:a copy -y "$COMPARISON_BR" -v quiet -stats

if [ $? -eq 0 ]; then
    echo "    [+] Comparación BR generada: $COMPARISON_BR"
else
    echo "    [+] Error al generar comparación BR"
    exit 1
fi

echo "[2/4] Generando comparación QP (H264 vs VP8)..."
ffmpeg -i "$H264_QP" -i "$VP8_QP" -filter_complex "\
    [0:v]scale=640:-1,drawtext=text='H.264 QP':fontsize=24:fontcolor=white:box=1:boxcolor=black@0.5:boxborderw=5:x=(w-text_w)/2:y=10[v0]; \
    [1:v]scale=640:-1,drawtext=text='VP8 QP':fontsize=24:fontcolor=white:box=1:boxcolor=black@0.5:boxborderw=5:x=(w-text_w)/2:y=10[v1]; \
    [v0][v1]hstack=inputs=2[v]" \
    -map "[v]" -map 0:a? -c:v libx264 -preset fast -crf 18 -c:a copy -y "$COMPARISON_QP" -v quiet -stats

if [ $? -eq 0 ]; then
    echo "    ✓ Comparación QP generada: $COMPARISON_QP"
else
    echo "    ✗ Error al generar comparación QP"
    exit 1
fi

echo ""
echo "==================================="
echo "Videos de comparación generados"
echo "==================================="
echo ""
echo "Archivos creados en $TEMP_DIR/:"
echo "  - ${VIDEO_NAME}_comparison_BR.mp4"
echo "  - ${VIDEO_NAME}_comparison_QP.mp4"
echo ""
echo "==================================="
echo "Reproducción"
echo "==================================="
echo ""
echo "Presione cualquier tecla para reproducir comparación BITRATE..."
read -n 1 -s

echo "[3/4] Reproduciendo comparación Bitrate..."
echo "  (Presione 'q' para detener y continuar)"
ffplay -window_title "$DISPLAY_NAME - Comparación Bitrate (H264 vs VP8)" "$COMPARISON_BR" 2>/dev/null

echo ""
echo "Presione cualquier tecla para reproducir comparación QP..."
read -n 1 -s

echo "[4/4] Reproduciendo comparación QP..."
echo "  (Presione 'q' para detener y salir)"
ffplay -window_title "$DISPLAY_NAME - Comparación QP (H264 vs VP8)" "$COMPARISON_QP" 2>/dev/null

echo ""
echo "==================================="
echo "Comparación completada"
echo "==================================="
echo ""
echo "Los videos temporales se mantienen en: $TEMP_DIR/"
echo "Puede reproducirlos nuevamente con:"
echo "  ffplay $COMPARISON_BR"
echo "  ffplay $COMPARISON_QP"
