#!/bin/bash

# Script para codificar video con múltiples configuraciones (bitrates y QP)
# Uso: ./encode_video.sh <nombre_video> [directorio_videos]

# Variables
VIDEO_NAME=$1
VIDEOS_DIR=${2:-"$PWD/videos"}

# Arrays de configuraciones
BITRATES=("100k" "300k")
QPS=("5" "28")

# Validar parámetros
if [ -z "$VIDEO_NAME" ]; then
    echo "[-] Error: Se requiere el nombre del video"
    echo "Uso: $0 <nombre_video> [directorio_videos]"
    exit 1
fi

# Crear directorio de videos si no existe
if [ ! -d "$VIDEOS_DIR" ]; then
    echo "[*] Creando directorio: $VIDEOS_DIR"
    mkdir -p "$VIDEOS_DIR"
fi

# Buscar archivo de video de entrada
VIDEO_INPUT=""
if [ -f "${VIDEO_NAME}.yuv" ]; then
    VIDEO_INPUT="${VIDEO_NAME}.yuv"
elif [ -f "mobile.yuv" ]; then
    VIDEO_INPUT="mobile.yuv"
elif [ -f "${VIDEO_NAME}.mp4" ]; then
    # Si es mp4, usamos el mp4
    VIDEO_INPUT="${VIDEO_NAME}.mp4"
else
    echo "[-] Error: No se encontró archivo de video de entrada"
    echo "[*] Buscando: ${VIDEO_NAME}.yuv, mobile.yuv o ${VIDEO_NAME}.mp4"
    exit 1
fi

echo "[+] Archivo de entrada: $VIDEO_INPUT"
echo "[+] Directorio de salida: $VIDEOS_DIR"
echo ""

# Validar que ffmpeg y MP4Box están disponibles
if ! command -v ffmpeg &> /dev/null; then
    echo "[-] Error: ffmpeg no encontrado"
    exit 1
fi

if ! command -v MP4Box &> /dev/null; then
    echo "[-] Error: MP4Box no encontrado"
    exit 1
fi

# Contador de codificaciones
TOTAL_ENCODINGS=$((${#BITRATES[@]} + ${#QPS[@]}))
CURRENT=0

# Codificar con bitrates
for bitrate in "${BITRATES[@]}"; do
    CURRENT=$((CURRENT + 1))
    
    # Crear directorio para esta configuración
    FOLDER_NAME="${bitrate}"
    OUTPUT_DIR="$VIDEOS_DIR/$FOLDER_NAME"
    
    mkdir -p "$OUTPUT_DIR"
    
    # Nombres de archivos de salida (combinando nombre_video_carpeta)
    OUTPUT_FILENAME="${VIDEO_NAME}_${FOLDER_NAME%/}"
    H264_FILE="$OUTPUT_DIR/${OUTPUT_FILENAME}.264"
    MP4_FILE="$OUTPUT_DIR/${OUTPUT_FILENAME}.mp4"
    
    echo "[$CURRENT/$TOTAL_ENCODINGS] Codificando con bitrate: $bitrate"
    echo "[*] Directorio: $OUTPUT_DIR"
    echo "[*] Entrada: $VIDEO_INPUT"
    echo "[*] Salida: $H264_FILE"
    
    # Codificar con ffmpeg
    if ffmpeg -s cif -i "$VIDEO_INPUT" -vcodec libx264 -s cif -b:v "$bitrate" -f h264 "$H264_FILE" -y 2>&1 | tail -5; then
        echo "[+] Codificación a H.264 completada"
        
        # Encapsular en MP4 con MP4Box
        echo "[*] Encapsulando en MP4 con MP4Box..."
        if MP4Box -hint -mtu 1024 -fps 30 -add "$H264_FILE" -new "$MP4_FILE" 2>&1 | grep -E "Writing|error"; then
            echo "[+] Encapsulación MP4 completada: $MP4_FILE"
        else
            echo "[-] Error en encapsulación MP4"
            exit 1
        fi
    else
        echo "[-] Error en codificación H.264"
        exit 1
    fi
    
    echo ""
done

# Codificar con QP
for qp in "${QPS[@]}"; do
    CURRENT=$((CURRENT + 1))
    
    # Crear directorio para esta configuración
    FOLDER_NAME="${qp}qp"
    OUTPUT_DIR="$VIDEOS_DIR/$FOLDER_NAME"
    
    mkdir -p "$OUTPUT_DIR"
    
    # Nombres de archivos de salida (combinando nombre_video_carpeta)
    OUTPUT_FILENAME="${VIDEO_NAME}_${FOLDER_NAME%/}"
    H264_FILE="$OUTPUT_DIR/${OUTPUT_FILENAME}.264"
    MP4_FILE="$OUTPUT_DIR/${OUTPUT_FILENAME}.mp4"
    
    echo "[$CURRENT/$TOTAL_ENCODINGS] Codificando con QP: $qp"
    echo "[*] Directorio: $OUTPUT_DIR"
    echo "[*] Entrada: $VIDEO_INPUT"
    echo "[*] Salida: $H264_FILE"
    
    # Codificar con ffmpeg (usando qp en lugar de bitrate)
    if ffmpeg -s cif -i "$VIDEO_INPUT" -vcodec libx264 -s cif -qp "$qp" -f h264 "$H264_FILE" -y 2>&1 | tail -5; then
        echo "[+] Codificación a H.264 completada"
        
        # Encapsular en MP4 con MP4Box
        echo "[*] Encapsulando en MP4 con MP4Box..."
        if MP4Box -hint -mtu 1024 -fps 30 -add "$H264_FILE" -new "$MP4_FILE" 2>&1 | grep -E "Writing|error"; then
            echo "[+] Encapsulación MP4 completada: $MP4_FILE"
        else
            echo "[-] Error en encapsulación MP4"
            exit 1
        fi
    else
        echo "[-] Error en codificación H.264"
        exit 1
    fi
    
    echo ""
done

echo "[+] ¡Codificación completada!"
echo ""
echo "[*] Estructura generada:"
tree "$VIDEOS_DIR" 2>/dev/null || find "$VIDEOS_DIR" -type f | sort
