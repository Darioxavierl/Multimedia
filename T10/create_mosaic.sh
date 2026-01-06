#!/bin/bash

# Script para crear un video mosaico a partir de múltiples videos
# Uso: ./create_mosaic.sh <directorio_videos> [archivo_salida.mp4]

# Verificar que se ha pasado un argumento
if [ $# -eq 0 ]; then
    echo "Uso: $0 <directorio_con_videos> [archivo_salida.mp4]"
    exit 1
fi

# Directorio de entrada
INPUT_DIR="$1"

# Verificar que el directorio existe
if [ ! -d "$INPUT_DIR" ]; then
    echo "Error: El directorio '$INPUT_DIR' no existe"
    exit 1
fi

# Archivo de salida en el mismo directorio
OUTPUT_FILE="$INPUT_DIR/mosaico_$(basename "$INPUT_DIR").mp4"

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║           CREACIÓN DE VIDEO MOSAICO                           ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Buscar todos los archivos de video (excluir el mosaico si existe)
mapfile -t VIDEOS < <(find "$INPUT_DIR" -maxdepth 1 -type f \( -name "*.mp4" -o -name "*.avi" -o -name "*.mkv" \) ! -name "mosaico_*.mp4" | sort)

# Verificar que hay videos
NUM_VIDEOS=${#VIDEOS[@]}
if [ $NUM_VIDEOS -eq 0 ]; then
    echo "[-] Error: No se encontraron videos en '$INPUT_DIR'"
    exit 1
fi

echo "[+] Videos encontrados: $NUM_VIDEOS"
echo "[+] Salida: $OUTPUT_FILE"
echo ""

# Configuración de dimensiones
WIDTH=352
HEIGHT=288

# Calcular layout según número de videos
if [ $NUM_VIDEOS -le 3 ]; then
    COLS=3
    ROWS=1
elif [ $NUM_VIDEOS -le 6 ]; then
    COLS=3
    ROWS=2
else
    COLS=3
    ROWS=3
    # Limitar a 9 videos
    VIDEOS=("${VIDEOS[@]:0:9}")
    NUM_VIDEOS=9
fi

echo "[→] Creando mosaico ${ROWS}x${COLS}..."

# Construir filtro con xstack
FILTER=""
LAYOUT=""

for i in $(seq 0 $((NUM_VIDEOS-1))); do
    VIDEO_NAME=$(basename "${VIDEOS[$i]}")
    FILTER+="[$i:v]scale=${WIDTH}:${HEIGHT},drawtext=text='${VIDEO_NAME}':x=10:y=10:fontsize=18:fontcolor=white:borderw=2[v$i];"
    
    ROW=$((i / COLS))
    COL=$((i % COLS))
    X=$((COL * WIDTH))
    Y=$((ROW * HEIGHT))
    
    if [ $i -eq 0 ]; then
        LAYOUT="${X}_${Y}"
    else
        LAYOUT="${LAYOUT}|${X}_${Y}"
    fi
done

# Agregar espacios vacíos si faltan videos para completar la grilla
TOTAL_SLOTS=$((ROWS * COLS))
if [ $NUM_VIDEOS -lt $TOTAL_SLOTS ]; then
    for i in $(seq $NUM_VIDEOS $((TOTAL_SLOTS-1))); do
        FILTER+="nullsrc=size=${WIDTH}x${HEIGHT}:duration=10[v$i];"
        
        ROW=$((i / COLS))
        COL=$((i % COLS))
        X=$((COL * WIDTH))
        Y=$((ROW * HEIGHT))
        LAYOUT="${LAYOUT}|${X}_${Y}"
    done
    NUM_VIDEOS=$TOTAL_SLOTS
fi

# Construir inputs para xstack
XSTACK_INPUTS=""
for i in $(seq 0 $((NUM_VIDEOS-1))); do
    XSTACK_INPUTS="${XSTACK_INPUTS}[v$i]"
done

FILTER+="${XSTACK_INPUTS}xstack=inputs=${NUM_VIDEOS}:layout=${LAYOUT}[out]"

echo ""
echo "[→] Procesando videos con ffmpeg..."
echo "    Esto puede tomar varios minutos dependiendo del tamaño..."
echo ""

# Construir inputs
INPUTS=()
for video in "${VIDEOS[@]}"; do
    INPUTS+=(-i "$video")
done

# Crear el mosaico
ffmpeg -y \
    "${INPUTS[@]}" \
    -filter_complex "$FILTER" \
    -map "[v]" \
    -c:v libx264 \
    -preset fast \
    -pix_fmt yuv420p \
    "$OUTPUT_FILE" 2>&1 | grep -E "frame=|Duration|time=" || true

echo ""
# Crear el mosaico
ffmpeg -y \
    "${INPUTS[@]}" \
    -filter_complex "$FILTER" \
    -map "[out]" \
    -c:v libx264 \
    -preset fast \
    -pix_fmt yuv420p \
    "$OUTPUT_FILE" 2>&1 | grep -E "frame=|Duration|time=" || true

echo ""
if [ -f "$OUTPUT_FILE" ]; then
    echo "[+] Mosaico creado exitosamente: $OUTPUT_FILE"
    echo "[+] Tamaño: $(du -h "$OUTPUT_FILE" | cut -f1)"
    echo ""
    echo "[→] Reproduciendo mosaico..."
    ffplay -autoexit "$OUTPUT_FILE" 2>/dev/null
    echo ""
    echo "[+] Reproducción finalizada"
else
    echo "[-] Error al crear el mosaico"
    exit 1
fi