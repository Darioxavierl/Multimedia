#!/bin/bash
# Script de utilidad para gestionar captura y conversión de tráfico de video (Tx)
# Uso:
#   ./video_capture.sh help
#   ./video_capture.sh start
#   ./video_capture.sh stop
#   ./video_capture.sh convert PCAP_FILE
#   ./video_capture.sh workflow

# Cargar variables desde .env
ENV_FILE="$(dirname "$0")/.env"
if [ -f "$ENV_FILE" ]; then
    source "$ENV_FILE"
fi

# Variables por defecto
PCAP_DIR="${PCAP_DIR:-PCAP}"
EVALVID_PATH="${EVALVID_PATH:-~/evalvid}"

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m'

show_help() {
    cat << EOF
${BLUE}═══════════════════════════════════════════════════════════════${NC}
${BLUE}  Utilidad de Captura y Conversión de Video - Tx${NC}
${BLUE}═══════════════════════════════════════════════════════════════${NC}

${GREEN}Comandos:${NC}

  start
    Inicia captura de tráfico UDP con tcpdump
    Uso: ./video_capture.sh start

  stop
    Detiene captura y guarda PCAP
    Uso: ./video_capture.sh stop

  convert <PCAP_FILE>
    Convierte PCAP a archivo dump (.dump)
    Uso: ./video_capture.sh convert PCAP/tx_20231213_120000.pcap

  status
    Verifica estado actual de captura
    Uso: ./video_capture.sh status

  workflow
    Muestra el workflow completo de prueba
    Uso: ./video_capture.sh workflow

  help
    Muestra esta ayuda
    Uso: ./video_capture.sh help

${BLUE}═══════════════════════════════════════════════════════════════${NC}

${YELLOW}Ejemplos:${NC}

1. Iniciar captura:
   $ sudo ./video_capture.sh start

2. Enviar video con mp4trace (en otra terminal):
   $ cd ~/evalvid
   $ ./mp4trace video.mp4 -u 192.168.12.2 5000 > tx_trace.f

3. Detener captura:
   $ sudo ./video_capture.sh stop

4. Convertir PCAP a dump:
   $ ./video_capture.sh convert PCAP/tx_20231213_120000.pcap

5. Reconstruir con etmp4:
   $ ~/evalvid/etmp4 -f 0 tx_dump rx_dump tx_trace.f video.mp4 output.mp4

${BLUE}═══════════════════════════════════════════════════════════════${NC}
EOF
}

show_workflow() {
    cat << EOF
${BLUE}═══════════════════════════════════════════════════════════════${NC}
${BLUE}  Workflow de Captura y Reconstrucción de Video${NC}
${BLUE}═══════════════════════════════════════════════════════════════${NC}

${GREEN}Paso 1: Preparar Tx (Servidor)${NC}

  # Iniciar captura de tráfico
  $ cd Tx
  $ sudo ./video_capture.sh start

${GREEN}Paso 2: Preparar Rx (Cliente)${NC}

  # En otra máquina
  $ cd Rx
  $ sudo ./video_capture.sh start

${GREEN}Paso 3: Enviar video desde Tx${NC}

  # En Tx, enviar video con mp4trace
  $ cd ~/evalvid
  $ ./mp4trace video.mp4 -u 192.168.12.2 5000 > tx_trace.f

${GREEN}Paso 4: Detener capturas${NC}

  # En Tx
  $ sudo ./video_capture.sh stop

  # En Rx
  $ sudo ./video_capture.sh stop

${GREEN}Paso 5: Convertir PCAP a dump${NC}

  # En Tx
  $ ./video_capture.sh convert PCAP/tx_*.pcap

  # En Rx
  $ ./video_capture.sh convert PCAP/rx_*.pcap

${GREEN}Paso 6: Reconstruir video${NC}

  # Copiar archivos necesarios a directorio común
  # Necesitas:
  #   - tx_dump (del PCAP de Tx)
  #   - rx_dump (del PCAP de Rx)
  #   - tx_trace.f (generado por mp4trace)
  #   - video.mp4 (original)

  $ ~/evalvid/etmp4 -f 0 tx_dump rx_dump tx_trace.f video.mp4 output.mp4

${BLUE}═══════════════════════════════════════════════════════════════${NC}

${YELLOW}Archivos generados:${NC}

  • PCAP/tx_YYYYMMDD_HHMMSS.pcap    → Captura de tráfico
  • PCAP/tx_YYYYMMDD_HHMMSS.dump    → Dump de tráfico (formato EvalVid)
  • tx_trace.f                        → Traza de mp4trace (generada manualmente)

${BLUE}═══════════════════════════════════════════════════════════════${NC}
EOF
}

case "$1" in
    start)
        echo -e "${GREEN}Iniciando captura...${NC}"
        sudo ./capture_traffic.sh start
        ;;
    
    stop)
        echo -e "${GREEN}Deteniendo captura...${NC}"
        sudo ./capture_traffic.sh stop
        ;;
    
    status)
        ./capture_traffic.sh status
        ;;
    
    convert)
        if [ -z "$2" ]; then
            echo -e "${RED}Error: debe proporcionar archivo PCAP${NC}"
            echo "Uso: $0 convert <PCAP_FILE>"
            exit 1
        fi
        
        if [ ! -f "$2" ]; then
            echo -e "${RED}Error: archivo no encontrado: $2${NC}"
            exit 1
        fi
        
        echo -e "${GREEN}Convirtiendo PCAP a dump...${NC}"
        python3 pcap_to_dump.py "$2"
        ;;
    
    workflow)
        show_workflow
        ;;
    
    help)
        show_help
        ;;
    
    *)
        echo -e "${RED}Error: comando desconocido: $1${NC}"
        echo ""
        show_help
        exit 1
        ;;
esac
