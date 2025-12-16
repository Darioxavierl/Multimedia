#!/bin/bash

VIDEOS_DIR="${1:-./videos}"
DISTANCE="${2:-70}"
VIDEO_NAME="${3:-mobile_cif}"

# Convertir ruta relativa a absoluta si es necesario
if [[ "$VIDEOS_DIR" != /* ]]; then
    VIDEOS_DIR="$(cd "$VIDEOS_DIR" 2>/dev/null && pwd)" || {
        echo "[-] Error: No se puede acceder al directorio '$VIDEOS_DIR'"
        exit 1
    }
fi

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                  Ejecutando toda la simulacion                 ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "[*] Parámetros:"
echo "    - Videos dir: $VIDEOS_DIR"
echo "    - Distancia: $DISTANCE m"
echo "    - Nombre de video: $VIDEO_NAME"
echo ""

echo "[+] Codificando videos..."
./encode_video.sh "$VIDEO_NAME" 
if [ $? -ne 0 ]; then
    echo "[-] Error en la codificación de videos"
    exit 1
fi

echo "[+] Generando trazas..."
./generate_traces.sh
if [ $? -ne 0 ]; then
    echo "[-] Error en la generación de trazas"
    exit 1
fi  

echo "[+] Corriendo simulaciones de red..."
./run_ns3_simulations.sh "$VIDEOS_DIR" "$DISTANCE"
if [ $? -ne 0 ]; then
    echo "[-] Error en las simulaciones de red"
    exit 1
fi

echo "[+] Reconstruyendo videos..."
./reconstruct_videos.sh "$VIDEOS_DIR"
if [ $? -ne 0 ]; then
    echo "[-] Error en la reconstrucción de videos"
    exit 1
fi

echo "[+] Calculando PSNR de videos reconstruidos..."
./calculate_psnr.sh "$VIDEOS_DIR"
if [ $? -ne 0 ]; then
    echo "[-] Error en el cálculo de PSNR"
    exit 1
fi  