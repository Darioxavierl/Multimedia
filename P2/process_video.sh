#!/bin/bash
set -e

# ==========================
#   VARIABLES DE ENTRADA
# ==========================
INPUT_DIR="${1:-./videos}"        # Carpeta donde está el .y4m
OUTPUT_DIR="${2:-./output}"       # Carpeta donde se guardarán los resultados
VIDEO_NAME="${3:-mobile_cif}"     # Nombre base del video (sin extensión)

# ==========================
#   CONFIGURACIÓN
# ==========================

# Crear carpeta de salida
if [ ! -d "$OUTPUT_DIR" ]; then
    mkdir -p "$OUTPUT_DIR"
    echo " Carpeta de salida creada: $OUTPUT_DIR"
else
    echo " Carpeta de salida ya existe, continuando..."
fi



# ==========================
# Extraer el video crudo .yuv
# ==========================

echo "[+] Extrayendo videos en crudo"

for f in "$INPUT_DIR"/*; do
    filename=$(basename -- "$f")
    name="${filename%.*}"
    echo "[+] Procesando $f → $OUTPUT_DIR/$name.mp4"
    ffmpeg -y -i "$f" -pix_fmt yuv420p -fps_mode passthrough -f rawvideo "$OUTPUT_DIR/$name.yuv"
done

echo "[+] Encapsulando videos para la reproduccion"

if [ ! -d "$OUTPUT_DIR/rep" ]; then
    mkdir -p "$OUTPUT_DIR/rep"
    echo " Carpeta de salida creada: $OUTPUT_DIR/rep"
else
    echo " Carpeta de salida ya existe, continuando..."
fi

for f in "$OUTPUT_DIR"/*; do
    # saltar si no es archivo regular
    [ -f "$f" ] || continue

    filename=$(basename -- "$f")
    name="${filename%.*}"
    orig="$INPUT_DIR/$name.mp4"

    echo "[+] Procesando $f → $OUTPUT_DIR/$name.yuv"

    if [ ! -f "$orig" ]; then
        echo "No se encontró el original para $name, usando 30 fps por defecto."
        fps=30
    else
        fps=$(ffprobe -v 0 -of csv=p=0 -select_streams v:0 -show_entries stream=r_frame_rate "$orig" | bc -l)
    fi

    ffmpeg -y -f rawvideo -pix_fmt yuv420p -s:v 352x288 -r "$fps" -i "$f" "$OUTPUT_DIR/rep/$name.y4m"
done


