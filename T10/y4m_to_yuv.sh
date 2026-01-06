#!/bin/bash

# Script para convertir video Y4M a formato YUV crudo

# Verificar que se ha pasado un argumento
if [ $# -eq 0 ]; then
    echo "Uso: $0 <archivo.y4m>"
    exit 1
fi

# Obtener el archivo de entrada
INPUT_FILE="$1"

# Verificar que el archivo existe
if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: El archivo '$INPUT_FILE' no existe"
    exit 1
fi

# Extraer el nombre sin extensión
BASENAME=$(basename "$INPUT_FILE" .y4m)

# Nombre del archivo de salida
OUTPUT_FILE="${BASENAME}.yuv"

# Convertir usando ffmpeg
ffmpeg -i "$INPUT_FILE" -c:v rawvideo -pix_fmt yuv420p "$OUTPUT_FILE"

echo "Conversión completada: $OUTPUT_FILE"
