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
INTERFACE=wlp3s0

echo -e "${BLUE}→ Iniciando captura en interfaz $INTERFACE...${NC}"
echo ""

# Iniciar tcpdump en background sin filtro de puerto
# Usando -U para flush inmediato y -n para no resolver DNS
tcpdump -i "$INTERFACE" -w "$PCAP_FILE" -U 2>&1 &
TCPDUMP_PID=$!
sleep 2  # Esperar a que tcpdump inicie correctamente

# Verificar que tcpdump está corriendo
if ! kill -0 $TCPDUMP_PID 2>/dev/null; then
    echo -e "${RED}✗ Error: tcpdump falló al iniciar${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Captura iniciada (PID: $TCPDUMP_PID)${NC}"
echo ""

# Mostrar línea de envío
echo -e "${BLUE}→ Enviando video con mp4trace...${NC}"
SEND_CMD="~/evalvid/mp4trace -f -s \"$IP_DESTINO\" $PUERTO \"$VIDEO_PATH\" > \"$TRACE_FILE\""
echo "  Comando: $SEND_CMD"
echo ""

# Ejecutar mp4trace
/home/dariox/evalvid/mp4trace -f -s "$IP_DESTINO" $PUERTO "$VIDEO_PATH" > "$TRACE_FILE"
SEND_EXIT_CODE=$?

echo -e "${BLUE}→ Deteniendo captura...${NC}"

# Detener tcpdump
kill $TCPDUMP_PID 2>/dev/null
wait $TCPDUMP_PID 2>/dev/null

sleep 1

# Debug: Mostrar estadísticas de tcpdump
echo -e "${BLUE}→ Estadísticas de captura:${NC}"
if [ -f "$PCAP_FILE" ]; then
    PCAP_SIZE=$(ls -lh "$PCAP_FILE" | awk '{print $5}')
    echo "  Tamaño archivo: $PCAP_SIZE"
    echo "  Contenido PCAP:"
    tcpdump -r "$PCAP_FILE" -c 5 2>/dev/null | head -10
fi

# Verificar que se crearon los archivos
if [ -f "$PCAP_FILE" ]; then
    PCAP_SIZE=$(du -h "$PCAP_FILE" | awk '{print $1}')
    PCAP_PACKETS=$(tcpdump -r "$PCAP_FILE" 2>/dev/null | wc -l)
    echo -e "${GREEN}✓ PCAP capturado: $PCAP_FILE ($PCAP_SIZE, $PCAP_PACKETS paquetes)${NC}"
else
    echo -e "${RED}✗ Error: No se generó el PCAP${NC}"
    echo "  Debug: Verificar permisos en ./PCAP/"
    ls -la ./PCAP/
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
