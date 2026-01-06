#! /bin/bash

# En este script se emula el comportamiento de la codificación SVC. Especificamente se ha empleado 
# Escalabilidad Espacial con cinco valores del parámetro bit rate, como resultado se obtienen cinco capas o versiones 
# de la secuencia de video

# Verificar que se ha pasado un argumento
if [ $# -eq 0 ]; then
    echo "Uso: $0 <ruta_video>"
    exit 1
fi

# Obtener la ruta del video de entrada
INPUT_VIDEO="$1"

# Extraer el nombre del video sin extensión
VIDEO_NAME=$(basename "$INPUT_VIDEO" | sed 's/\.[^.]*$//')

# Crear directorio de salida
OUTPUT_DIR="videos-salida/espacial"
mkdir -p "$OUTPUT_DIR"
 
 
 br4=800k
 br3=600k
 br2=400k
 br1=200k
 br0=100k


# crew_layer 0 -R0

ffmpeg -s cif -r 30 -i "$INPUT_VIDEO"  -vcodec libx264 -s cif -r 30 -b:v $br0 -f h264 "$OUTPUT_DIR/${VIDEO_NAME}_${br0}.mp4"


# crew_layer 1 -R1

ffmpeg -s cif -r 30 -i "$INPUT_VIDEO"  -vcodec libx264 -s cif -r 30 -b:v $br1 -f h264 "$OUTPUT_DIR/${VIDEO_NAME}_${br1}.mp4"


# crew_layer 2 -R2

ffmpeg -s cif -r 30 -i "$INPUT_VIDEO"  -vcodec libx264 -s cif -r 30 -b:v $br2 -f h264 "$OUTPUT_DIR/${VIDEO_NAME}_${br2}.mp4"


# crew_layer 3 -R3

ffmpeg -s cif -r 30 -i "$INPUT_VIDEO"  -vcodec libx264 -s cif -r 30 -b:v $br3 -f h264 "$OUTPUT_DIR/${VIDEO_NAME}_${br3}.mp4"


# crew_layer 4 -R4

ffmpeg -s cif -r 30 -i "$INPUT_VIDEO"  -vcodec libx264 -s cif -r 30 -b:v $br4 -f h264 "$OUTPUT_DIR/${VIDEO_NAME}_${br4}.mp4"
