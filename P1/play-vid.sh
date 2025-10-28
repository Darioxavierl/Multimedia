#!/usr/bin/env bash

# ==========================
# Carpeta donde están los videos .mp4
# ==========================
VIDEO_DIR="${1:-./output}"   # Se puede pasar como argumento, por defecto ./output

# ==========================
# Configuración del mosaico
# ==========================
ROWS=2
COLS=4
WINDOW_WIDTH=480    # ancho de cada ventana
WINDOW_HEIGHT=360   # alto de cada ventana
SPACING_X=10        # separación horizontal
SPACING_Y=50        # separación vertical (considerar barra título)
DELAY=0.5           # retardo entre abrir ventanas para evitar que colapsen

# ==========================
# Obtener lista de videos
# ==========================
VIDEOS=("$VIDEO_DIR"/*.y4m)
TOTAL=${#VIDEOS[@]}

if [ $TOTAL -eq 0 ]; then
    echo " No se encontraron videos en $VIDEO_DIR"
    exit 1
fi

echo " Reproduciendo $TOTAL videos en un mosaico de ${ROWS}x${COLS}..."

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

    # Abrir ffplay en segundo plano
    ffplay -autoexit -x $WINDOW_WIDTH -y $WINDOW_HEIGHT -left $X_POS -top $Y_POS "$VIDEO" &
    
    COUNT=$((COUNT + 1))
    sleep $DELAY

    # Limitar a 2x3
    if [ $COUNT -ge $((ROWS*COLS)) ]; then
        break
    fi
done

wait
echo "Reproducción finalizada."

