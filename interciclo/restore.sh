#!/bin/bash
# Script para restaurar interfaz WiFi a modo normal
# Uso: ./restore_wifi.sh INTERFACE

INTERFACE=$1

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "================================"
echo " Restaurando Interfaz WiFi"
echo "================================"
echo ""

# Verificar argumento
if [ -z "$INTERFACE" ]; then
    echo -e "${RED}Error: Falta la interfaz${NC}"
    echo ""
    echo "Uso: $0 <INTERFACE>"
    echo ""
    exit 1
fi

# Requerir sudo
if [ "$EUID" -ne 0 ]; then
    echo -e "${YELLOW}Este script requiere sudo. Reintentando...${NC}"
    exec sudo "$0" "$@"
fi

# Verificar interfaz
if ! ip link show "$INTERFACE" &>/dev/null; then
    echo -e "${RED}Error: Interfaz $INTERFACE no encontrada${NC}"
    exit 1
fi

echo -e "${BLUE}→ Bajando interfaz...${NC}"
ip link set "$INTERFACE" down
sleep 1

echo -e "${BLUE}→ Restaurando modo 'managed'...${NC}"
iwconfig "$INTERFACE" mode managed 2>/dev/null || true

echo -e "${BLUE}→ Limpiando IPs manuales...${NC}"
ip addr flush dev "$INTERFACE"

echo -e "${BLUE}→ Reactivando NetworkManager en la interfaz...${NC}"
nmcli device set "$INTERFACE" managed yes 2>/dev/null || echo "  (NM no disponible)"

echo -e "${BLUE}→ Reiniciando NetworkManager...${NC}"
systemctl restart NetworkManager 2>/dev/null || true

echo -e "${BLUE}→ Reiniciando wpa_supplicant (si aplica)...${NC}"
systemctl restart wpa_supplicant 2>/dev/null || true

echo -e "${BLUE}→ Levantando interfaz...${NC}"
ip link set "$INTERFACE" up
sleep 2

echo -e "${BLUE}→ Obteniendo dirección IP por DHCP...${NC}"
dhclient "$INTERFACE" 2>/dev/null || true

echo ""
echo "================================"
echo -e " ${GREEN}✓ Interfaz restaurada a modo normal${NC}"
echo "================================"
echo ""

echo -e "${BLUE}Estado actual:${NC}"
iwconfig "$INTERFACE" | grep -E "Mode|ESSID"
echo ""
ip addr show "$INTERFACE" | grep "inet "
echo ""
