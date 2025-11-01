#!/bin/bash

# ==========================
# Carpeta donde están los videos .mp4
# ==========================
VIDEO_DIR="${1:-./output/rep}"   # Se puede pasar como argumento, por defecto ./output
VIDEOS=("$VIDEO_DIR"/*.y4m)
# Archivo base original
original=("$VIDEO_DIR"/mobile_cif.y4m)

# Verifica si existe
if [ ! -f "$original" ]; then
  echo "Error: no se encuentra $original en el directorio actual"
  exit 1
fi

# Recorre todos los .y4m excepto el original
for vid in "${VIDEOS[@]}"; do
  if [ "$vid" != "$original" ]; then
    filename=$(basename -- "$vid")
    echo "Reproduciendo par: $original y $vid"
    output="${VIDEO_DIR}/comparacion_${filename}.y4m"
    
    
     ffmpeg -y \
      -i "$original" \
      -i "$vid" \
      -filter_complex "\
        [0:v]drawtext=text='ORIGINAL':x=10:y=10:fontsize=20:fontcolor=white:borderw=2[orig]; \
        [1:v]drawtext=text='${filename}':x=10:y=10:fontsize=20:fontcolor=white:borderw=2[v]; \
        [orig][v]hstack=inputs=2[out]" \
      -map "[out]" -c:v rawvideo -pix_fmt yuv420p "$output"

    ffplay -loglevel error -autoexit "$output" 

    rm "$output"

  fi
done
