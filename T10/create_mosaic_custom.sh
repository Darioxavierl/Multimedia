#!/bin/bash

# Script para crear un mosaico de 3 videos específicos
# Los videos se configuran directamente en el script

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║        CREACIÓN DE MOSAICO - 3 VIDEOS ESPECÍFICOS             ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# =========================
# CONFIGURACIÓN DE VIDEOS
# =========================
# Edita estas rutas para cambiar los videos del mosaico
VIDEO1="videos-salida/calidad/crew_cif_q60.mp4"
VIDEO2="videos-salida/temporal/crew_cif_2fps.mp4"
VIDEO3="videos-salida/espacial/crew_cif_100k.mp4"

# Nombre del archivo de salida (se guarda en la raíz)
OUTPUT_FILE="mosaico_analisis.mp4"
# =========================

# Verificar que los 3 videos existen
VIDEOS=("$VIDEO1" "$VIDEO2" "$VIDEO3")
MISSING=0

for video in "${VIDEOS[@]}"; do
    if [ ! -f "$video" ]; then
        echo "[-] Error: No se encuentra el video: $video"
        MISSING=1
    fi
done

if [ $MISSING -eq 1 ]; then
    echo ""
    echo "[-] Verifica las rutas de los videos en el script"
    exit 1
fi

echo "[+] Videos a combinar:"
echo "    1. $(basename "$VIDEO1")"
echo "    2. $(basename "$VIDEO2")"
echo "    3. $(basename "$VIDEO3")"
echo ""
echo "[+] Salida: $OUTPUT_FILE"
echo ""

# Configuración de dimensiones
WIDTH=352
HEIGHT=288

echo "[→] Creando mosaico 1x3..."
echo ""

# Construir filtro con xstack (1 fila, 3 columnas)
FILTER=""
FILTER+="[0:v]scale=${WIDTH}:${HEIGHT},drawtext=text='$(basename "$VIDEO1")':x=10:y=10:fontsize=18:fontcolor=white:borderw=2[v0];"
FILTER+="[1:v]scale=${WIDTH}:${HEIGHT},drawtext=text='$(basename "$VIDEO2")':x=10:y=10:fontsize=18:fontcolor=white:borderw=2[v1];"
FILTER+="[2:v]scale=${WIDTH}:${HEIGHT},drawtext=text='$(basename "$VIDEO3")':x=10:y=10:fontsize=18:fontcolor=white:borderw=2[v2];"
FILTER+="[v0][v1][v2]xstack=inputs=3:layout=0_0|${WIDTH}_0|$((WIDTH*2))_0[out]"

echo "[→] Procesando videos con ffmpeg..."
echo "    Esto puede tomar varios minutos dependiendo del tamaño..."
echo ""

# Crear el mosaico
ffmpeg -y \
    -i "$VIDEO1" \
    -i "$VIDEO2" \
    -i "$VIDEO3" \
    -filter_complex "$FILTER" \
    -map "[out]" \
    -c:v libx264 \
    -preset fast \
    -pix_fmt yuv420p \
    "$OUTPUT_FILE" 2>&1 | grep -E "frame=|Duration|time=" || true

echo ""
if [ -f "$OUTPUT_FILE" ]; then
    echo "[+] Mosaico creado exitosamente: $OUTPUT_FILE"
    echo "[+] Tamaño: $(du -h "$OUTPUT_FILE" | cut -f1)"
    echo ""
    echo "[→] Reproduciendo mosaico..."
    ffplay -autoexit "$OUTPUT_FILE" 2>/dev/null
    echo ""
    echo "[+] Reproducción finalizada"
else
    echo "[-] Error al crear el mosaico"
    exit 1
fi
