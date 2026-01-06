#! /bin/bash

# En este script se emula el comportamiento de la codificación SVC. Especificamente se ha empleado 
# Escalabilidad temporal y cinco valores de frame rate, como resultado se obtienen cinco capas o versiones 
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
OUTPUT_DIR="videos-salida/temporal"
mkdir -p "$OUTPUT_DIR"

 T4=30
 T3=16
 T2=8
 T1=4
 T0=2
 

# crew_layer 0 -T0

ffmpeg -s cif -r 30 -i "$INPUT_VIDEO"  -vcodec libx264 -s cif -r $T0 -f h264 "$OUTPUT_DIR/${VIDEO_NAME}_${T0}fps.mp4"


# crew_layer 1 -T1
ffmpeg -s cif -r 30 -i "$INPUT_VIDEO"  -vcodec libx264 -s cif -r $T1 -f h264 "$OUTPUT_DIR/${VIDEO_NAME}_${T1}fps.mp4"


# crew_layer 2 -T2
ffmpeg -s cif -r 30 -i "$INPUT_VIDEO"  -vcodec libx264 -s cif -r $T2 -f h264 "$OUTPUT_DIR/${VIDEO_NAME}_${T2}fps.mp4"


# crew_layer 3 -T3
ffmpeg -s cif -r 30 -i "$INPUT_VIDEO"  -vcodec libx264 -s cif -r $T3 -f h264 "$OUTPUT_DIR/${VIDEO_NAME}_${T3}fps.mp4"


# crew_layer 4 -T4
ffmpeg -s cif -r 30 -i "$INPUT_VIDEO"  -vcodec libx264 -s cif -r $T4 -f h264 "$OUTPUT_DIR/${VIDEO_NAME}_${T4}fps.mp4"
