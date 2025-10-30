#!/bin/bash

# Verificar parámetros
if [ $# -ne 2 ]; then
  echo "Uso: $0 <directorio_entrada> <directorio_salida>"
  exit 1
fi

INPUT_DIR="$1"
OUTPUT_DIR="$2"
BITRATE=3000

# Crear directorio de salida si no existe
mkdir -p "$OUTPUT_DIR"


# Recorrer todos los archivos .y4m
for f in "$INPUT_DIR"/*.y4m; do
  # Verificar si hay archivos
  [ -e "$f" ] || { echo "No se encontraron archivos .y4m en $INPUT_DIR"; exit 1; }

  filename=$(basename -- "$f")
  name="${filename%.*}"
  output_file="$OUTPUT_DIR/${name}_${BITRATE}.mp4"

  echo "[+] Codificando $f → $output_file"

  # Obtener FPS desde la cabecera del archivo Y4M
  fps_str=$(head -n 1 "$f" | grep -o 'F[0-9]*:[0-9]*' | cut -c2-)
  if [ -z "$fps_str" ]; then
    echo "   ⚠ No se pudo detectar FPS, usando 30 fps por defecto."
    fps="30"
  else
    fps=$(echo "$fps_str" | awk -F: '{printf "%.3f", $1/$2}')
    echo "   → FPS detectado: $fps"
  fi

  ffmpeg -y -i "$f" -r "$fps"  -c:v libx264 -b:v ${BITRATE}k -pix_fmt yuv420p "$output_file"

  if [ $? -eq 0 ]; then
    echo "    ✔ $output_file generado correctamente."
  else
    echo "    ✖ Error al codificar $f"
  fi
done