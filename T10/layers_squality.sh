#! /bin/bash

# En este script se emula el comportamiento de la codificación SVC. Especificamente se ha empleado 
# Escalabilidad de calidad con cinco valores del parámetro q, como resultado se obtienen cinco capas o versiones 
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
OUTPUT_DIR="videos-salida/calidad"
mkdir -p "$OUTPUT_DIR"
 
 Q4=5
 Q3=25
 Q2=35
 Q1=45
 Q0=60


# crew_layer 0 -Q0

ffmpeg -s cif -r 30 -i "$INPUT_VIDEO"  -vcodec libx264 -s cif -r 30 -qmin $Q0 -qmax $Q0 -f h264 "$OUTPUT_DIR/${VIDEO_NAME}_q${Q0}.mp4"


# crew_layer 1 -Q1

ffmpeg -s cif -r 30 -i "$INPUT_VIDEO"  -vcodec libx264 -s cif -r 30 -qmin $Q1 -qmax $Q1 -f h264 "$OUTPUT_DIR/${VIDEO_NAME}_q${Q1}.mp4"


# crew_layer 2 -Q2

ffmpeg -s cif -r 30 -i "$INPUT_VIDEO"  -vcodec libx264 -s cif -r 30 -qmin $Q2 -qmax $Q2 -f h264 "$OUTPUT_DIR/${VIDEO_NAME}_q${Q2}.mp4"


# crew_layer 3 -Q3

ffmpeg -s cif -r 30 -i "$INPUT_VIDEO"  -vcodec libx264 -s cif -r 30 -qmin $Q3 -qmax $Q3 -f h264 "$OUTPUT_DIR/${VIDEO_NAME}_q${Q3}.mp4"


# crew_layer 4 -Q4

ffmpeg -s cif -r 30 -i "$INPUT_VIDEO"  -vcodec libx264 -s cif -r 30 -qmin $Q4 -qmax $Q4 -f h264 "$OUTPUT_DIR/${VIDEO_NAME}_q${Q4}.mp4"
