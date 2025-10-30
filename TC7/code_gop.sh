#!/bin/bash

# Uso:
# ./encode_h264_gop.sh <directorio_entrada> <directorio_salida> <GOP_length>
# Ejemplo:
# ./encode_h264_gop.sh ./videos_y4m ./salida_h264 30

if [ $# -ne 3 ]; then
  echo "Uso: $0 <directorio_entrada> <directorio_salida> <GOP_length>"
  exit 1
fi

INPUT_DIR="$1"
OUTPUT_DIR="$2"
GOP_LENGTH="$3"

# Crear subcarpeta según GOP
OUTPUT_SUBDIR="$OUTPUT_DIR/GOP_$GOP_LENGTH"
mkdir -p "$OUTPUT_SUBDIR"

shopt -s nullglob
FILES=("$INPUT_DIR"/*.y4m)
if [ ${#FILES[@]} -eq 0 ]; then
  echo "No se encontraron archivos .y4m en $INPUT_DIR"
  exit 1
fi

for f in "${FILES[@]}"; do
  filename=$(basename -- "$f")
  name="${filename%.*}"
  output_file="$OUTPUT_SUBDIR/${name}_h264_gop${GOP_LENGTH}.mp4"

  echo "[+] Procesando $f → $output_file"

  # Obtener FPS desde la cabecera del archivo Y4M
  fps_str=$(head -n 1 "$f" | grep -o 'F[0-9]*:[0-9]*' | cut -c2-)
  if [ -z "$fps_str" ]; then
    echo "   ⚠ No se pudo detectar FPS, usando 30 fps por defecto."
    fps="30"
  else
    fps=$(echo "$fps_str" | awk -F: '{printf "%.3f", $1/$2}')
    echo "   → FPS detectado: $fps"
  fi

  # Codificar H.264 con bitrate 3000k y GOP especificado
  ffmpeg -y -i "$f" -r "$fps" -c:v libx264 -b:v 3000k \
    -g "$GOP_LENGTH" -keyint_min "$GOP_LENGTH" -pix_fmt yuv420p \
    -movflags +faststart "$output_file"

  if [ $? -eq 0 ]; then
    echo "    ✔ $output_file generado correctamente."
  else
    echo "    ✖ Error al codificar $f"
  fi
done

echo -e "\n✔ Todos los videos se han codificado en $OUTPUT_SUBDIR"
