#!/bin/bash
# Script para crear un hotspot con nmcli
# Uso: ./setup_hotspot.sh <INTERFACE> <SSID> <PASSWORD>

INTERFACE=$1
SSID=$2
PASSWORD=$3

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "================================"
echo "   Creación de Hotspot WiFi"
echo "================================"
echo ""

# Verificar parámetros
if [ -z "$INTERFACE" ] || [ -z "$SSID" ] || [ -z "$PASSWORD" ]; then
    echo -e "${RED}Error: Faltan parámetros${NC}"
    echo ""
    echo "Uso: $0 <INTERFACE> <SSID> <PASSWORD>"
    echo ""
    echo "Ejemplo:"
    echo "  $0 wlan0 videollamada 12345678"
    echo ""
    exit 1
fi

# Requerir sudo
if [ "$EUID" -ne 0 ]; then
    echo -e "${YELLOW}Este script requiere sudo. Reintentando...${NC}"
    exec sudo "$0" "$@"
fi

# Verificar que la interfaz exista
if ! ip link show "$INTERFACE" &>/dev/null; then
    echo -e "${RED}Interfaz $INTERFACE no encontrada${NC}"
    exit 1
fi

echo -e "${BLUE}→ Activando hotspot en $INTERFACE${NC}"
echo "  SSID: $SSID"
echo "  Password: $PASSWORD"
echo ""

echo "→ Deteniendo posibles conexiones previas..."
nmcli device disconnect "$INTERFACE" 2>/dev/null || true

echo "→ Iniciando hotspot..."
nmcli dev wifi hotspot ifname "$INTERFACE" ssid "$SSID" password "$PASSWORD"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Hotspot creado correctamente${NC}"
else
    echo -e "${RED}✗ Error al crear el hotspot${NC}"
    exit 1
fi

echo ""
echo "================================"
echo " Hotspot activo"
echo "================================"
echo ""
nmcli device show "$INTERFACE" | grep IP4.ADDRESS
echo ""
echo -e "${GREEN}✓ Operación completada${NC}"
