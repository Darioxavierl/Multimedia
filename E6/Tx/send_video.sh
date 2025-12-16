#!/bin/bash
# Script para enviar video y capturar tráfico en Tx
# Uso: ./send_video.sh <ruta_video> <ip_destino> <puerto>
# Ejemplo: ./send_video.sh ./videos/100k/mobile_cif_100k.mp4 10.42.0.245 5000

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
    echo "Uso: $0 <ruta_video> [ip_destino] [puerto]"
    echo ""
    echo "Ejemplos:"
    echo "  $0 ./videos/100k/mobile_cif_100k.mp4"
    echo "  $0 ./videos/100k/mobile_cif_100k.mp4 10.42.0.245 5000"
    echo ""
    exit 1
fi

VIDEO_PATH="$1"
IP_DESTINO="${2:-$RX_CLIENT_IP}"
PUERTO="${3:-$VIDEO_UDP_PORT}"

# Validar que el video existe
if [ ! -f "$VIDEO_PATH" ]; then
    echo -e "${RED}✗ Archivo de video no encontrado: $VIDEO_PATH${NC}"
    exit 1
fi

# Extraer nombre del video sin extensión y directorio
VIDEO_NAME=$(basename "$VIDEO_PATH" .mp4)
VIDEO_DIR=$(dirname "$VIDEO_PATH")

# Crear directorios si no existen
mkdir -p ./PCAP 2>/dev/null
mkdir -p ./trazas 2>/dev/null

# Rutas de salida
PCAP_FILE="./PCAP/${VIDEO_NAME}.pcap"
TRACE_FILE="./trazas/${VIDEO_NAME}.f"

echo "================================"
echo "   Tx: Envío de Video"
echo "================================"
echo ""
echo "Parámetros:"
echo "  Video: $VIDEO_PATH"
echo "  IP destino: $IP_DESTINO"
echo "  Puerto: $PUERTO"
echo "  PCAP: $PCAP_FILE"
echo "  Trace: $TRACE_FILE"
echo ""

# Verificar que el servidor está disponible
echo -e "${BLUE}→ Verificando conectividad al Rx...${NC}"
if ! ping -c 1 "$IP_DESTINO" &>/dev/null; then
    echo -e "${RED}✗ No se puede alcanzar $IP_DESTINO${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Rx alcanzable${NC}"
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

# Mostrar línea de envío
echo -e "${BLUE}→ Enviando video con mp4trace...${NC}"
SEND_CMD="~/evalvid/mp4trace -f -s \"$IP_DESTINO\" $PUERTO \"$VIDEO_PATH\" > \"$TRACE_FILE\""
echo "  Comando: $SEND_CMD"
echo ""

# Ejecutar mp4trace
~/evalvid/mp4trace -f -s "$IP_DESTINO" $PUERTO "$VIDEO_PATH" > "$TRACE_FILE"
SEND_EXIT_CODE=$?

echo ""
echo -e "${BLUE}→ Deteniendo captura...${NC}"

# Detener tcpdump
kill $TCPDUMP_PID 2>/dev/null
wait $TCPDUMP_PID 2>/dev/null

sleep 1

# Verificar que se crearon los archivos
if [ -f "$PCAP_FILE" ]; then
    PCAP_SIZE=$(du -h "$PCAP_FILE" | awk '{print $1}')
    echo -e "${GREEN}✓ PCAP capturado: $PCAP_FILE ($PCAP_SIZE)${NC}"
else
    echo -e "${RED}✗ Error: No se generó el PCAP${NC}"
fi

if [ -f "$TRACE_FILE" ]; then
    TRACE_LINES=$(wc -l < "$TRACE_FILE")
    echo -e "${GREEN}✓ Trace generado: $TRACE_FILE ($TRACE_LINES líneas)${NC}"
else
    echo -e "${RED}✗ Error: No se generó el trace${NC}"
fi

echo ""

if [ $SEND_EXIT_CODE -eq 0 ]; then
    echo "================================"
    echo "   ✓ Envío completado"
    echo "================================"
    echo ""
    echo "Archivos generados:"
    echo "  PCAP: $PCAP_FILE"
    echo "  Trace: $TRACE_FILE"
    echo ""
    echo "Próximo paso:"
    echo "  python3 pcap_analyzer.py Tx/$PCAP_FILE Rx/$PCAP_FILE $INTERFACE $IP_DESTINO ./Tx/tx_dump ./Rx/rx_dump -p $PUERTO"
    echo ""
else
    echo -e "${RED}✗ Error en el envío (código: $SEND_EXIT_CODE)${NC}"
    exit 1
fi
