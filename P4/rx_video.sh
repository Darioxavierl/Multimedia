#!/bin/bash

# Directorios y variables
EVAL_DIR="$HOME/evalvid"
TYPE_TRAZA=$1
ARCHIVO_TX=$2
ARCHIVO_RX=$3
ARCHIVO_TRACE=$4
VIDEO_ORIGINAL=$5
VIDEO_RECONSTRUIDO=$6

# Validar número de parámetros
if [ $# -ne 6 ]; then
    echo "[-] Error: Se requieren 6 parámetros"
    echo "Uso: $0 <tipo_traza> <archivo_tx> <archivo_rx> <archivo_trace> <video_original> <video_reconstruido>"
    exit 1
fi

# Validar que el directorio evalvid existe
if [ ! -d "$EVAL_DIR" ]; then
    echo "[-] Error: Directorio $EVAL_DIR no existe"
    exit 1
fi

# Validar que la herramienta etmp4 existe
if [ ! -f "$EVAL_DIR/etmp4" ]; then
    echo "[-] Error: Herramienta $EVAL_DIR/etmp4 no encontrada"
    exit 1
fi

# Validar que los archivos de entrada existen
for archivo in "$ARCHIVO_TX" "$ARCHIVO_RX" "$ARCHIVO_TRACE"; do
    if [ ! -f "$archivo" ]; then
        echo "[-] Error: Archivo '$archivo' no existe"
        exit 1
    fi
done

echo "[+] Recontruyendo video a partir de la traza RX"
echo "[+] Tipo de traza: $TYPE_TRAZA"
echo "[+] Archivo TX: $ARCHIVO_TX"
echo "[+] Archivo RX: $ARCHIVO_RX"
echo "[+] Archivo TRACE: $ARCHIVO_TRACE"
echo "[+] Video original: $VIDEO_ORIGINAL.mp4"
echo "[+] Video reconstruido: $VIDEO_RECONSTRUIDO"
echo ""

# Construir y ejecutar el comando
CMD="$EVAL_DIR/etmp4 -$TYPE_TRAZA -0 $ARCHIVO_TX $ARCHIVO_RX $ARCHIVO_TRACE $VIDEO_ORIGINAL.mp4 $VIDEO_RECONSTRUIDO"

echo "[*] Ejecutando: $CMD"
$CMD

# Validar el resultado
if [ $? -eq 0 ]; then
    echo "[+] ¡Éxito! Video reconstruido en: $VIDEO_RECONSTRUIDO"
else
    echo "[-] Error: La reconstrucción del video falló"
    exit 1
fi

