#!/bin/bash
# Script para verificar que todo está correctamente configurado para EvalVid

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  VERIFICACIÓN DE CONFIGURACIÓN PARA EVALVID           ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# Función para revisar si comando existe
check_command() {
    local cmd=$1
    local name=$2
    
    if command -v "$cmd" > /dev/null 2>&1; then
        local version=$(command -v "$cmd")
        echo -e "${GREEN}✓${NC} $name: $version"
        return 0
    else
        echo -e "${RED}✗${NC} $name: NO ENCONTRADO"
        return 1
    fi
}

# Función para revisar si archivo existe
check_file() {
    local file=$1
    local name=$2
    
    if [ -f "$file" ]; then
        local size=$(du -h "$file" | cut -f1)
        echo -e "${GREEN}✓${NC} $name: $file ($size)"
        return 0
    else
        echo -e "${RED}✗${NC} $name: $file NO ENCONTRADO"
        return 1
    fi
}

# Función para revisar variable en .env
check_env() {
    local file=$1
    local var=$2
    
    if [ -f "$file" ]; then
        local value=$(grep "^${var}=" "$file" | cut -d= -f2)
        if [ -n "$value" ]; then
            echo -e "${GREEN}✓${NC} $file $var=$value"
            return 0
        else
            echo -e "${RED}✗${NC} $file $var: NO DEFINIDO"
            return 1
        fi
    else
        echo -e "${RED}✗${NC} $file: NO EXISTE"
        return 1
    fi
}

ERRORS=0

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}1. HERRAMIENTAS DEL SISTEMA${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
echo ""

check_command "tcpdump" "tcpdump" || ((ERRORS++))
check_command "python3" "Python 3" || ((ERRORS++))
check_command "nc" "netcat" || ((ERRORS++))
check_command "chronyc" "Chrony client" || ((ERRORS++))
check_command "nmcli" "NetworkManager" || ((ERRORS++))

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}2. LIBRERÍAS PYTHON${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
echo ""

if python3 -c "from scapy.all import rdpcap, IP, UDP" 2>/dev/null; then
    echo -e "${GREEN}✓${NC} scapy: instalado"
else
    echo -e "${RED}✗${NC} scapy: NO INSTALADO"
    echo -e "${YELLOW}  Instala con: pip3 install scapy${NC}"
    ((ERRORS++))
fi

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}3. HERRAMIENTAS EVALVID${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
echo ""

check_file "$HOME/evalvid/mp4trace" "mp4trace (Tx)" || ((ERRORS++))
check_file "$HOME/evalvid/etmp4" "etmp4 (reconstrucción)" || ((ERRORS++))

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}4. ARCHIVOS DE CONFIGURACIÓN${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
echo ""

check_file "Tx/.env" "Tx configuración" || ((ERRORS++))
check_file "Rx/.env" "Rx configuración" || ((ERRORS++))
check_file "Tx/config/chrony_tx.conf" "Chrony Tx config" || ((ERRORS++))
check_file "Rx/config/chrony_rx.conf" "Chrony Rx config" || ((ERRORS++))

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}5. SCRIPTS DE ENVÍO/RECEPCIÓN${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
echo ""

if [ -x "Tx/send_video.sh" ]; then
    echo -e "${GREEN}✓${NC} Tx/send_video.sh: ejecutable"
else
    echo -e "${RED}✗${NC} Tx/send_video.sh: NO ejecutable"
    ((ERRORS++))
fi

if [ -x "Rx/receive_video.sh" ]; then
    echo -e "${GREEN}✓${NC} Rx/receive_video.sh: ejecutable"
else
    echo -e "${RED}✗${NC} Rx/receive_video.sh: NO ejecutable"
    ((ERRORS++))
fi

if [ -x "Tx/pcap_to_dump.py" ]; then
    echo -e "${GREEN}✓${NC} Tx/pcap_to_dump.py: ejecutable"
else
    echo -e "${RED}✗${NC} Tx/pcap_to_dump.py: NO ejecutable"
    ((ERRORS++))
fi

if [ -x "Rx/pcap_to_dump.py" ]; then
    echo -e "${GREEN}✓${NC} Rx/pcap_to_dump.py: ejecutable"
else
    echo -e "${RED}✗${NC} Rx/pcap_to_dump.py: NO ejecutable"
    ((ERRORS++))
fi

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}6. VARIABLES EN Tx/.env${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
echo ""

check_env "Tx/.env" "WIFI_INTERFACE" || ((ERRORS++))
check_env "Tx/.env" "HOTSPOT_SSID" || ((ERRORS++))
check_env "Tx/.env" "GATEWAY_IP" || ((ERRORS++))
check_env "Tx/.env" "VIDEO_UDP_PORT" || ((ERRORS++))
check_env "Tx/.env" "RX_CLIENT_IP" || ((ERRORS++))
check_env "Tx/.env" "CAPTURE_INTERFACE" || ((ERRORS++))
check_env "Tx/.env" "VIDEO_FILE" || ((ERRORS++))
check_env "Tx/.env" "MP4TRACE_PATH" || ((ERRORS++))

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}7. VARIABLES EN Rx/.env${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
echo ""

check_env "Rx/.env" "WIFI_INTERFACE" || ((ERRORS++))
check_env "Rx/.env" "HOTSPOT_SSID" || ((ERRORS++))
check_env "Rx/.env" "TX_SERVER_IP" || ((ERRORS++))
check_env "Rx/.env" "VIDEO_UDP_PORT" || ((ERRORS++))
check_env "Rx/.env" "CAPTURE_INTERFACE" || ((ERRORS++))

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}8. DIRECTORIOS PCAP${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
echo ""

if [ -d "Tx/PCAP" ]; then
    echo -e "${GREEN}✓${NC} Tx/PCAP: existe"
else
    echo -e "${YELLOW}⚠${NC} Tx/PCAP: no existe (se creará automáticamente)"
fi

if [ -d "Rx/PCAP" ]; then
    echo -e "${GREEN}✓${NC} Rx/PCAP: existe"
else
    echo -e "${YELLOW}⚠${NC} Rx/PCAP: no existe (se creará automáticamente)"
fi

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}9. VERIFICACIÓN DE RED${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
echo ""

WIFI_IF=$(grep "^WIFI_INTERFACE=" Tx/.env | cut -d= -f2)
if [ -z "$WIFI_IF" ]; then
    WIFI_IF="wlp3s0"
fi

if ip link show "$WIFI_IF" > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Interfaz $WIFI_IF: existe"
else
    echo -e "${RED}✗${NC} Interfaz $WIFI_IF: NO EXISTE"
    echo -e "${YELLOW}  Interfaces disponibles:${NC}"
    ip link show | grep "^[0-9]" | awk '{print "    " $2}'
    ((ERRORS++))
fi

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"

if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}║  ✓ TODO CONFIGURADO CORRECTAMENTE                    ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${GREEN}Estás listo para usar EvalVid. Ejecuta:${NC}"
    echo ""
    echo -e "${CYAN}  En Rx: sudo ./Rx/receive_video.sh start-listen${NC}"
    echo -e "${CYAN}  En Tx: sudo ./Tx/send_video.sh start-capture${NC}"
    echo -e "${CYAN}  En Tx: ./Tx/send_video.sh send-video${NC}"
    echo ""
else
    echo -e "${RED}║  ✗ HAY $ERRORS PROBLEMAS QUE RESOLVER                 ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}Problemas a resolver:${NC}"
    echo -e "${YELLOW}1. Instala scapy: pip3 install scapy${NC}"
    echo -e "${YELLOW}2. Verifica que mp4trace y etmp4 estén en ~/evalvid/${NC}"
    echo -e "${YELLOW}3. Revisa las variables en Tx/.env y Rx/.env${NC}"
    echo -e "${YELLOW}4. Verifica que la interfaz WiFi sea correcta${NC}"
    exit 1
fi
