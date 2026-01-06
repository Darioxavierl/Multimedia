#!/bin/bash

# Script para crear un mosaico de videos y reproducirlo

# Verificar que se ha pasado un argumento
if [ $# -eq 0 ]; then
    echo "Uso: $0 <directorio_con_videos>"
    exit 1
fi

# Directorio de entrada
INPUT_DIR="$1"

# Verificar que el directorio existe
if [ ! -d "$INPUT_DIR" ]; then
    echo "Error: El directorio '$INPUT_DIR' no existe"
    exit 1
fi

# ==========================
# Configuración del mosaico
# ==========================
WINDOW_WIDTH=400    # ancho de cada ventana
WINDOW_HEIGHT=300   # alto de cada ventana
SPACING_X=10        # separación horizontal
SPACING_Y=50        # separación vertical (considerar barra título)
DELAY=0.3           # retardo entre abrir ventanas

# Buscar todos los archivos de video (mp4, avi, mkv, yuv, y4m)
mapfile -t VIDEOS < <(find "$INPUT_DIR" -type f \( -name "*.mp4" -o -name "*.avi" -o -name "*.mkv" -o -name "*.yuv" -o -name "*.y4m" \) | sort)

# Verificar que hay videos
NUM_VIDEOS=${#VIDEOS[@]}
if [ $NUM_VIDEOS -eq 0 ]; then
    echo "Error: No se encontraron videos en '$INPUT_DIR'"
    exit 1
fi

echo "Reproduciendo $NUM_VIDEOS videos en mosaico..."

# Calcular el layout óptimo (filas x columnas)
if [ $NUM_VIDEOS -le 2 ]; then
    ROWS=1
    COLS=$NUM_VIDEOS
elif [ $NUM_VIDEOS -le 4 ]; then
    ROWS=2
    COLS=2
elif [ $NUM_VIDEOS -le 6 ]; then
    ROWS=2
    COLS=3
elif [ $NUM_VIDEOS -le 9 ]; then
    ROWS=3
    COLS=3
else
    ROWS=3
    COLS=4
fi

# ==========================
# Abrir videos en mosaico
# ==========================
COUNT=0
for VIDEO in "${VIDEOS[@]}"; do
    # Calcular posición en la pantalla
    ROW=$(( COUNT / COLS ))
    COL=$(( COUNT % COLS ))
    X_POS=$(( COL * (WINDOW_WIDTH + SPACING_X) ))
    Y_POS=$(( ROW * (WINDOW_HEIGHT + SPACING_Y) ))

    # Extraer solo el nombre del archivo
    VIDEO_NAME=$(basename "$VIDEO")

    # Abrir ffplay en segundo plano con el nombre del archivo como título
    ffplay -autoexit -x $WINDOW_WIDTH -y $WINDOW_HEIGHT -left $X_POS -top $Y_POS -window_title "$VIDEO_NAME" "$VIDEO" &
    
    COUNT=$((COUNT + 1))
    sleep $DELAY

    # Limitar según el layout calculado
    if [ $COUNT -ge $((ROWS*COLS)) ]; then
        break
    fi
done

wait
echo "Reproducción finalizada."
