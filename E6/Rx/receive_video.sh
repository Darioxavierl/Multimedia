#!/bin/bash
# Script para recibir video y capturar tráfico en Rx
# Uso: ./receive_video.sh <nombre_video> [puerto]
# Ejemplo: ./receive_video.sh 100k 5000

# Cargar variables desde .env
ENV_FILE="$(dirname "$0")/.env"
if [ -f "$ENV_FILE" ]; then
    source "$ENV_FILE"
    echo "✓ Configuración cargada desde .env"
fi

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Validar argumentos
if [ $# -lt 1 ]; then
    echo -e "${RED}Error: Faltan argumentos${NC}"
    echo ""
    echo "Uso: $0 <nombre_video> [puerto]"
    echo ""
    echo "Ejemplos:"
    echo "  $0 100k"
    echo "  $0 100k 5000"
    echo ""
    exit 1
fi

VIDEO_NAME="$1"
PUERTO="${2:-$VIDEO_UDP_PORT}"

# Crear directorios si no existen
mkdir -p ./PCAP 2>/dev/null

# Rutas de salida
PCAP_FILE="./PCAP/${VIDEO_NAME}.pcap"
RECEIVED_FILE="/tmp/${VIDEO_NAME}_received.data"

echo "================================"
echo "   Rx: Recepción de Video"
echo "================================"
echo ""
echo "Parámetros:"
echo "  Nombre video: $VIDEO_NAME"
echo "  Puerto: $PUERTO"
echo "  PCAP: $PCAP_FILE"
echo "  Buffer: $RECEIVED_FILE"
echo ""

# Requerir sudo para tcpdump
if [ "$EUID" -ne 0 ]; then
    echo -e "${YELLOW}Este script requiere sudo para tcpdump${NC}"
    exec sudo "$0" "$@"
fi

# Obtener interfaz de red activa
INTERFACE=$(ip route | grep default | awk '{print $5}' | head -1)
if [ -z "$INTERFACE" ]; then
    echo -e "${RED}✗ No se encontró interfaz de red activa${NC}"
    exit 1
fi

echo -e "${BLUE}→ Iniciando captura en interfaz $INTERFACE...${NC}"
echo "  Filtro: udp port $PUERTO"
echo ""

# Iniciar tcpdump en background
tcpdump -i "$INTERFACE" -w "$PCAP_FILE" "udp port $PUERTO" 2>/dev/null &
TCPDUMP_PID=$!
sleep 1  # Esperar a que tcpdump inicie

echo -e "${GREEN}✓ Captura iniciada (PID: $TCPDUMP_PID)${NC}"
echo ""

echo -e "${BLUE}→ Escuchando en puerto $PUERTO...${NC}"
echo "  Espera los datos del video..."
echo "  Presiona ENTER cuando termine de recibir los datos"
echo ""

# Iniciar nc escuchando en UDP
# nc redirige los datos a un archivo y permanece escuchando
nc -4lud "$PUERTO" > "$RECEIVED_FILE" &
NC_PID=$!

echo -e "${GREEN}✓ nc escuchando (PID: $NC_PID)${NC}"
echo ""

# Mostrar información en tiempo real del buffer
echo -e "${BLUE}→ Monitoreando recepción...${NC}"
echo ""

# Loop para mostrar tamaño del archivo cada segundo
LAST_SIZE=0
while true; do
    if [ -f "$RECEIVED_FILE" ]; then
        CURRENT_SIZE=$(stat -f%z "$RECEIVED_FILE" 2>/dev/null || stat -c%s "$RECEIVED_FILE" 2>/dev/null || echo "0")
        
        if [ "$CURRENT_SIZE" != "$LAST_SIZE" ]; then
            SIZE_MB=$(echo "scale=2; $CURRENT_SIZE / 1048576" | bc)
            echo -e "${GREEN}  Datos recibidos: $CURRENT_SIZE bytes ($SIZE_MB MB)${NC}"
            LAST_SIZE="$CURRENT_SIZE"
        fi
    fi
    
    sleep 1
    
    # Verificar si nc sigue activo
    if ! kill -0 $NC_PID 2>/dev/null; then
        break
    fi
done

# Esperar a que el usuario presione ENTER
read -p "$(echo -e ${YELLOW}→ Presiona ENTER para terminar la captura${NC})" dummy

echo ""
echo -e "${BLUE}→ Deteniendo recepción...${NC}"

# Detener nc
kill $NC_PID 2>/dev/null
wait $NC_PID 2>/dev/null

sleep 1

echo -e "${BLUE}→ Deteniendo captura de tcpdump...${NC}"

# Detener tcpdump
kill $TCPDUMP_PID 2>/dev/null
wait $TCPDUMP_PID 2>/dev/null

sleep 1

echo ""

# Verificar que se crearon los archivos
if [ -f "$PCAP_FILE" ]; then
    PCAP_SIZE=$(du -h "$PCAP_FILE" | awk '{print $1}')
    PCAP_PACKETS=$(tcpdump -r "$PCAP_FILE" 2>/dev/null | wc -l)
    echo -e "${GREEN}✓ PCAP capturado: $PCAP_FILE${NC}"
    echo "  Tamaño: $PCAP_SIZE"
    echo "  Paquetes: $PCAP_PACKETS"
else
    echo -e "${RED}✗ Error: No se generó el PCAP${NC}"
fi

if [ -f "$RECEIVED_FILE" ]; then
    RECEIVED_SIZE=$(du -h "$RECEIVED_FILE" | awk '{print $1}')
    echo -e "${GREEN}✓ Datos recibidos: $RECEIVED_FILE ($RECEIVED_SIZE)${NC}"
else
    echo -e "${YELLOW}⚠ No hay datos recibidos${NC}"
fi

echo ""
echo "================================"
echo "   ✓ Recepción completada"
echo "================================"
echo ""
echo "Archivos generados:"
echo "  PCAP: $PCAP_FILE"
echo "  Buffer: $RECEIVED_FILE"
echo ""
echo "Próximo paso (una vez haya recibido Tx):"
echo "  python3 pcap_analyzer.py Tx/PCAP/${VIDEO_NAME}.pcap Rx/$PCAP_FILE 10.42.0.1 10.42.0.245 ./Tx/tx_dump ./Rx/rx_dump -p $PUERTO"
echo ""

# Limpiar archivo temporal si es muy pequeño (menos de 1KB)
if [ -f "$RECEIVED_FILE" ]; then
    SIZE=$(stat -f%z "$RECEIVED_FILE" 2>/dev/null || stat -c%s "$RECEIVED_FILE" 2>/dev/null)
    if [ "$SIZE" -lt 1024 ]; then
        rm -f "$RECEIVED_FILE"
    fi
fi
