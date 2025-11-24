#!/bin/bash
# Script para configurar red ad-hoc para VideoConferencia P2P
# Uso: ./setup_adhoc.sh IP_ADDRESS INTERFACE

ESSID="videoconf"
CHANNEL=6
IP_ADDRESS=$1
INTERFACE=$2

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "================================"
echo " Configuración de Red Ad-Hoc"
echo "================================"
echo ""

# Verificar parámetros
if [ -z "$IP_ADDRESS" ] || [ -z "$INTERFACE" ]; then
    echo -e "${RED}Error: Falta IP o interfaz${NC}"
    echo ""
    echo "Uso: $0 <IP_ADDRESS> <INTERFACE>"
    echo ""
    echo "Ejemplo:"
    echo "  $0 192.168.10.2 wlp3s0"
    echo ""
    exit 1
fi

# Verificar formato IP
if ! [[ $IP_ADDRESS =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    echo -e "${RED}Error: Formato de IP inválido${NC}"
    exit 1
fi

# Requerir sudo
if [ "$EUID" -ne 0 ]; then
    echo -e "${YELLOW}Este script requiere sudo. Reintentando...${NC}"
    exec sudo "$0" "$@"
fi

# Verificar interfaz
if ! ip link show "$INTERFACE" &>/dev/null; then
    echo -e "${RED}Interfaz $INTERFACE no encontrada${NC}"
    exit 1
fi

echo -e "${BLUE}Configurando Ad-Hoc en ${INTERFACE}${NC}"
echo "  ESSID: $ESSID"
echo "  Canal: $CHANNEL"
echo "  IP: $IP_ADDRESS/24"
echo ""

echo "→ Desactivando NetworkManager en $INTERFACE..."
nmcli device set "$INTERFACE" managed no 2>/dev/null || echo "  (NM no disponible)"

echo "→ Deteniendo wpa_supplicant..."
killall wpa_supplicant 2>/dev/null || true

echo "→ Bajando interfaz..."
ip link set "$INTERFACE" down
sleep 1

echo "→ Configurando modo ad-hoc..."
iwconfig "$INTERFACE" mode ad-hoc
iwconfig "$INTERFACE" essid "$ESSID"
iwconfig "$INTERFACE" channel "$CHANNEL"

echo "→ Limpiando IPs anteriores..."
ip addr flush dev "$INTERFACE"

echo "→ Asignando IP nueva..."
ip addr add "$IP_ADDRESS/24" dev "$INTERFACE"

echo "→ Levantando interfaz..."
ip link set "$INTERFACE" up
sleep 1

echo ""
echo "================================"
echo " Verificando configuración"
echo "================================"

echo -e "${BLUE}iwconfig:${NC}"
iwconfig "$INTERFACE"

echo ""
echo -e "${BLUE}Dirección IP:${NC}"
ip addr show "$INTERFACE" | grep "inet "

echo ""
echo -e "${GREEN}✓ Red ad-hoc configurada correctamente${NC}"
echo ""

# Sugerir siguiente IP al compañero
IFS='.' read -r a b c d <<< "$IP_ADDRESS"
NEXT_IP="$a.$b.$c.$((d == 1 ? 2 : 1))"

echo "================================"
echo " Próximos pasos"
echo "================================"
echo ""
echo "1. En el otro dispositivo:"
echo "   sudo ./setup_adhoc.sh $NEXT_IP $INTERFACE"
echo ""
echo "2. Probar conectividad:"
echo "   ping $NEXT_IP"
echo ""
echo "3. Para restaurar configuración normal:"
echo "   sudo nmcli device set $INTERFACE managed yes"
echo "   sudo systemctl restart NetworkManager"
echo ""
echo "================================"
