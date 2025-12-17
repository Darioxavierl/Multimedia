#!/bin/bash

# Script para reproducir video original y reconstruido lado a lado usando ffmpeg
# Usa hstack para colocar los videos horizontalmente
# Uso: ./play_videos.sh <directorio_videos>
# Ejemplo: ./play_videos.sh 40m/videos/5qp

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Validar argumentos
if [ $# -lt 1 ]; then
    echo "Uso: $0 <directorio_videos>"
    echo ""
    echo "Ejemplos:"
    echo "  $0 40m/videos/5qp"
    echo "  $0 ./76m/videos/10qp"
    echo ""
    exit 1
fi

VIDEO_DIR="$1"

# Convertir ruta relativa a absoluta
if [[ "$VIDEO_DIR" != /* ]]; then
    VIDEO_DIR="$SCRIPT_DIR/$VIDEO_DIR"
fi

# Validar que el directorio existe
if [ ! -d "$VIDEO_DIR" ]; then
    echo "[-] Error: Directorio no encontrado: $VIDEO_DIR"
    exit 1
fi

# Extraer el nombre del parámetro (última subcarpeta)
PARAM=$(basename "$VIDEO_DIR")

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║     REPRODUCCIÓN DE VIDEOS - ORIGINAL vs RECONSTRUIDO         ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "[+] Directorio: $VIDEO_DIR"
echo "[+] Parámetro:  $PARAM"
echo ""

# Buscar video original (sin _rec)
ORIG_VIDEO=$(find "$VIDEO_DIR" -maxdepth 1 -name "mobile_cif_${PARAM}.mp4" -type f)

# Buscar video reconstruido (_rec)
REC_VIDEO=$(find "$VIDEO_DIR" -maxdepth 1 -name "mobile_cif_${PARAM}_rec.mp4" -type f)

# Validar que ambos existen
if [ -z "$ORIG_VIDEO" ]; then
    echo "[-] Error: No se encontró video original: mobile_cif_${PARAM}.mp4"
    echo "    Buscando en: $VIDEO_DIR"
    ls -la "$VIDEO_DIR" | grep -i mp4
    exit 1
fi

if [ -z "$REC_VIDEO" ]; then
    echo "[-] Error: No se encontró video reconstruido: mobile_cif_${PARAM}_rec.mp4"
    echo "    Buscando en: $VIDEO_DIR"
    ls -la "$VIDEO_DIR" | grep -i mp4
    exit 1
fi

echo "[+] Video Original:     $(basename "$ORIG_VIDEO")"
echo "[+] Video Reconstruido: $(basename "$REC_VIDEO")"
echo ""

# Crear archivo temporal para la composición
TEMP_OUTPUT=$(mktemp --suffix=.mp4)

echo "[→] Creando composición lado a lado..."
echo "    Esto puede tomar unos segundos..."
echo ""

# Usar ffmpeg con hstack para poner videos lado a lado
# Añadir etiquetas de texto en cada video
ffmpeg -y \
    -i "$ORIG_VIDEO" \
    -i "$REC_VIDEO" \
    -filter_complex "\
        [0:v]drawtext=text='ORIGINAL':x=10:y=10:fontsize=24:fontcolor=white:borderw=3:bordercolor=black[orig]; \
        [1:v]drawtext=text='RECONSTRUIDO':x=10:y=10:fontsize=24:fontcolor=white:borderw=3:bordercolor=black[rec]; \
        [orig][rec]hstack=inputs=2[out]" \
    -map "[out]" \
    -c:v libx264 \
    -preset fast \
    -pix_fmt yuv420p \
    "$TEMP_OUTPUT" 2>&1 | grep -E "frame=|Duration" || true

echo ""
echo "[+] Composición creada: $TEMP_OUTPUT"
echo ""
echo "[→] Iniciando reproducción lado a lado..."
echo ""

# Reproducir la composición
ffplay -loglevel error -autoexit "$TEMP_OUTPUT" 2>/dev/null

# Limpiar archivo temporal
rm -f "$TEMP_OUTPUT" 2>/dev/null

echo ""
echo "[+] Reproducción finalizada"
