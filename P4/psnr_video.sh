#!/bin/bash

# Script para calcular PSNR entre video original y reconstruido
# Uso: ./psnr_video.sh <directorio_trabajo> <video_reconstruido> [video_original]

# Variables
TRABAJO_DIR=$1
VIDEO_REC=$2
VIDEO_ORIG=${3:-"video"}  # Por defecto "video" si no se especifica

EVAL_DIR="$HOME/evalvid"

# Validar parámetros
if [ $# -lt 2 ]; then
    echo "[-] Error: Se requieren al menos 2 parámetros"
    echo "Uso: $0 <directorio_trabajo> <video_reconstruido> [video_original]"
    exit 1
fi

# Validar que el directorio de trabajo existe
if [ ! -d "$TRABAJO_DIR" ]; then
    echo "[-] Error: Directorio de trabajo '$TRABAJO_DIR' no existe"
    exit 1
fi

# Validar que evalvid existe
if [ ! -d "$EVAL_DIR" ]; then
    echo "[-] Error: Directorio $EVAL_DIR no existe"
    exit 1
fi

# Validar que la herramienta psnr existe
if [ ! -f "$EVAL_DIR/psnr" ]; then
    echo "[-] Error: Herramienta $EVAL_DIR/psnr no encontrada"
    exit 1
fi

cd "$TRABAJO_DIR" || exit 1

VIDEO_REC_MP4="${VIDEO_REC}.mp4"
VIDEO_ORIG_MP4="${VIDEO_ORIG}.mp4"
VIDEO_REC_YUV="${VIDEO_REC}.yuv"
VIDEO_ORIG_YUV="${VIDEO_ORIG}.yuv"

# Validar que los archivos .mp4 existen
if [ ! -f "$VIDEO_REC_MP4" ]; then
    echo "[-] Error: Archivo '$VIDEO_REC_MP4' no existe en $TRABAJO_DIR"
    exit 1
fi

if [ ! -f "$VIDEO_ORIG_MP4" ]; then
    echo "[-] Error: Archivo '$VIDEO_ORIG_MP4' no existe en $TRABAJO_DIR"
    exit 1
fi

echo "[+] Extrayendo parámetros del video original: $VIDEO_ORIG_MP4"

# Extraer parámetros del video original
WIDTH=$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of default=noprint_wrappers=1:nokey=1 "$VIDEO_ORIG_MP4")
HEIGHT=$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of default=noprint_wrappers=1:nokey=1 "$VIDEO_ORIG_MP4")
PIX_FMT=$(ffprobe -v error -select_streams v:0 -show_entries stream=pix_fmt -of default=noprint_wrappers=1:nokey=1 "$VIDEO_ORIG_MP4")

# Mapear formato de píxel a código de formato
case "$PIX_FMT" in
    yuv420p)
        FORMAT_CODE="420"
        ;;
    yuv422p)
        FORMAT_CODE="422"
        ;;
    yuv444p)
        FORMAT_CODE="444"
        ;;
    *)
        echo "[-] Error: Formato de píxel '$PIX_FMT' no soportado"
        echo "[*] Formatos soportados: yuv420p, yuv422p, yuv444p"
        exit 1
        ;;
esac

if [ -z "$WIDTH" ] || [ -z "$HEIGHT" ]; then
    echo "[-] Error: No se pudo extraer resolución del video"
    exit 1
fi

echo "[+] Parámetros detectados:"
echo "    - Ancho: $WIDTH"
echo "    - Alto: $HEIGHT"
echo "    - Formato de píxel: $PIX_FMT (Código: $FORMAT_CODE)"
echo ""

# Convertir video reconstruido a YUV si no existe
if [ ! -f "$VIDEO_REC_YUV" ]; then
    echo "[*] Convirtiendo $VIDEO_REC_MP4 a YUV..."
    if ffmpeg -i "$VIDEO_REC_MP4" -pix_fmt yuv420p "$VIDEO_REC_YUV" -y 2>&1 | tail -5; then
        if [ ! -f "$VIDEO_REC_YUV" ]; then
            echo "[-] Error: No se pudo convertir $VIDEO_REC_MP4 a YUV"
            exit 1
        fi
        echo "[+] Conversión completada: $VIDEO_REC_YUV"
    else
        echo "[-] Error durante la conversión de $VIDEO_REC_MP4"
        exit 1
    fi
else
    echo "[+] Archivo $VIDEO_REC_YUV ya existe, se utilizará"
fi

echo ""

# Convertir video original a YUV si no existe
if [ ! -f "$VIDEO_ORIG_YUV" ]; then
    echo "[*] Convirtiendo $VIDEO_ORIG_MP4 a YUV..."
    if ffmpeg -i "$VIDEO_ORIG_MP4" -pix_fmt yuv420p "$VIDEO_ORIG_YUV" -y 2>&1 | tail -5; then
        if [ ! -f "$VIDEO_ORIG_YUV" ]; then
            echo "[-] Error: No se pudo convertir $VIDEO_ORIG_MP4 a YUV"
            exit 1
        fi
        echo "[+] Conversión completada: $VIDEO_ORIG_YUV"
    else
        echo "[-] Error durante la conversión de $VIDEO_ORIG_MP4"
        exit 1
    fi
else
    echo "[+] Archivo $VIDEO_ORIG_YUV ya existe, se utilizará"
fi

echo ""
echo "[*] Ejecutando PSNR analysis..."
echo "[*] Comando: $EVAL_DIR/psnr $WIDTH $HEIGHT $FORMAT_CODE $VIDEO_ORIG_YUV $VIDEO_REC_YUV"
echo ""

# Archivo de salida PSNR
PSNR_OUTPUT="psnr_${VIDEO_REC}.txt"

# Ejecutar PSNR y guardar salida en archivo
"$EVAL_DIR/psnr" "$WIDTH" "$HEIGHT" "$FORMAT_CODE" "$VIDEO_ORIG_YUV" "$VIDEO_REC_YUV" > "$PSNR_OUTPUT" 2>&1

if [ $? -eq 0 ]; then
    echo ""
    echo "[+] ¡Análisis PSNR completado exitosamente!"
    echo "[+] Resultados guardados en: $PSNR_OUTPUT"
else
    echo "[-] Error: El análisis PSNR falló"
    exit 1
fi
