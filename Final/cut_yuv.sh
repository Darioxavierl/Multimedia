#!/bin/bash

# =========================
# CONFIGURACIÓN
# =========================
INPUT="ElephantsDream_CIF_24fps.yuv"
OUTPUT="videos/ElephantsDreamPesi.yuv"

WIDTH=352
HEIGHT=288
FPS=24
PIX_FMT="yuv420p"

START_TIME="00:01:45"   # desde donde cortar
DURATION=60             # segundos

# =========================
# CÁLCULOS
# =========================

FILE_SIZE=$(stat -c%s "$INPUT")

case $PIX_FMT in
  yuv420p) BPP=1.5 ;;
  yuv422p) BPP=2 ;;
  yuv444p) BPP=3 ;;
  *)
    echo "Formato YUV no soportado"
    exit 1
    ;;
esac

FRAME_SIZE=$(echo "$WIDTH * $HEIGHT * $BPP" | bc)
TOTAL_FRAMES=$(echo "$FILE_SIZE / $FRAME_SIZE" | bc)
TOTAL_DURATION=$(echo "scale=2; $TOTAL_FRAMES / $FPS" | bc)

echo "INFO DEL VIDEO"
echo "Resolución : ${WIDTH}x${HEIGHT}"
echo "FPS        : $FPS"
echo "Formato    : $PIX_FMT"
echo "Frames     : $TOTAL_FRAMES"
echo "Duración   : ${TOTAL_DURATION}s"
echo "---------------------------"

# =========================
# CORTE
# =========================
ffmpeg \
-f rawvideo \
-pix_fmt $PIX_FMT \
-s ${WIDTH}x${HEIGHT} \
-r $FPS \
-ss $START_TIME \
-i $INPUT \
-t $DURATION \
-c copy \
$OUTPUT

echo "[+] Video cortado: $OUTPUT"
