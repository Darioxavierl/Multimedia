#!/usr/bin/env bash
set -e

# ==========================
#   VARIABLES DE ENTRADA
# ==========================
INPUT_DIR="${1:-./videos}"        # Carpeta donde está el .y4m y el .yuv
OUTPUT_DIR="${2:-./output}"       # Carpeta donde se guardarán los resultados
VIDEO_NAME="${3:-suzie_qcif}"     # Nombre base del video (sin extensión)

# ==========================
#   RUTAS Y CONFIGURACIÓN
# ==========================
INPUT_Y4M="$INPUT_DIR/${VIDEO_NAME}.y4m"
INPUT_YUV="$INPUT_DIR/${VIDEO_NAME}.yuv"
#mkdir -p "$OUTPUT_DIR"

echo "[+] Archivo Y4M original: $INPUT_Y4M"
echo "[+] Archivo YUV sin contenedor: $INPUT_YUV"
echo "[+] Carpeta de salida:  $OUTPUT_DIR"
echo "[+] Nombre base:        $VIDEO_NAME"

# ==========================
#   OBTENER DATOS DEL VIDEO ORIGINAL
# ==========================
width=$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of csv=p=0 "$INPUT_Y4M")
height=$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of csv=p=0 "$INPUT_Y4M")
fps=$(ffprobe -v error -select_streams v:0 \
  -show_entries stream=avg_frame_rate \
  -of default=nk=1:nw=1 "$INPUT_Y4M" | awk -F'/' '{printf "%.6f", $1/$2}')

echo "[+] Resolución detectada: ${width}x${height}"
echo "[+] FPS detectado:        ${fps}"

# ==========================
#   CODIFICAR A DIFERENTES BITRATES
# ==========================
echo "[+] Iniciando codificación con libx264 (mismo FPS y tamaño que el original)..."

for QP in 5 15 22 28 35 45 51; do
  OUTPUT_FILE="${OUTPUT_DIR}/${VIDEO_NAME}_${QP}.mp4"
  echo "     → Codificando a ${QP} QP..."
  ffmpeg -y -f rawvideo -pix_fmt yuv420p -s:v "${width}x${height}" -r "$fps" -i "$INPUT_YUV" \
  -c:v libx264 -qmin $QP -qmax $QP -pix_fmt yuv420p -r "$fps" "$OUTPUT_FILE"

  ffmpeg -y -f rawvideo -pix_fmt yuv420p -s:v "${width}x${height}" 
done

echo "[✓] Codificación completada."
  ffmpeg -y -f rawvideo -pix_fmt yuv420p -s:v "${width}x${height}" 
echo "[✓] Archivos generados en: $OUTPUT_DIR"

# ==========================
#   OPCIONAL: VERIFICAR FPS DE LOS CODIFICADOS
# ==========================
echo
echo "[*] Verificando FPS de los videos generados:"
for QP in 5 15 22 28 35 45 51; do
  OUTPUT_FILE="${OUTPUT_DIR}/${VIDEO_NAME}_${QP}.y4m"
  rate=$(ffprobe -v error -select_streams v:0 -show_entries stream=avg_frame_rate \
         -of default=nk=1:nw=1 "$OUTPUT_FILE" | awk -F'/' '{printf "%.3f", $1/$2}')
  echo "     ${VIDEO_NAME}_${QP}.mp4 → ${rate} fps"
done
