#!/usr/bin/env bash
set -e

# ========================================
#   PARÁMETROS DE ENTRADA
# ========================================
INPUT_DIR="${1:-./videos}"        # Carpeta con los videos a comparar
OUTPUT_DIR="${2:-./psnr}"         # Carpeta donde se guardarán los CSV
ORIGIN="${3:-mobile_cif}"         # Nombre base del video original (sin extensión)

# ========================================
#   CONFIGURACIÓN INICIAL
# ========================================
#mkdir -p "$OUTPUT_DIR"

ORIGINAL_PATH="$INPUT_DIR/${ORIGIN}.y4m"
if [ ! -f "$ORIGINAL_PATH" ]; then
  echo "[!] No se encontró el video original: $ORIGINAL_PATH"
  exit 1
fi

echo "[+] Directorio de entrada: $INPUT_DIR"
echo "[+] Directorio de salida:  $OUTPUT_DIR"
echo "[+] Video original:        $ORIGINAL_PATH"
echo

# ========================================
#   BUCLE SOBRE TODOS LOS VIDEOS DEL INPUT
# ========================================
for VIDEO in "$INPUT_DIR"/*.y4m; do
  BASENAME=$(basename "$VIDEO")
  if [ "$BASENAME" != "${ORIGIN}.y4m" ]; then

    echo "[→] Procesando: $BASENAME"

    LOG_FILE="$OUTPUT_DIR/${BASENAME}_psnr.log"
    CSV_FILE="$OUTPUT_DIR/${BASENAME}_psnr.csv"

    # ======================================
    #   CALCULAR PSNR FRAME A FRAME
    # ======================================
    ffmpeg -i "$ORIGINAL_PATH" -i "$VIDEO" \
        -lavfi psnr="stats_file=$LOG_FILE" -f null - >/dev/null 2>&1

    # ======================================
    #   EXTRAER FRAME Y PSNR A CSV
    # ======================================
    #sed -n 's/.*n:\([0-9]*\).*psnr_avg:\([0-9.]*\).*/\1,\2/p' "$LOG_FILE" > "$CSV_FILE"
    sed -n 's/.*n:\([0-9]*\).*psnr_y:\([0-9.]*\).*psnr_u:\([0-9.]*\).*psnr_v:\([0-9.]*\).*/\1,\2,\3,\4/p' "$LOG_FILE" > "$CSV_FILE"


    echo "    ✓ Guardado: $CSV_FILE"
  fi
done

echo
echo "[✓] Proceso completado. Archivos CSV en: $OUTPUT_DIR"
