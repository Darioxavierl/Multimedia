#!/bin/bash
# Script para desconectarse del hotspot y detener Chrony

# Cargar variables desde .env
ENV_FILE="$(dirname "$0")/.env"
if [ -f "$ENV_FILE" ]; then
    source "$ENV_FILE"
fi

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "================================"
echo "   Rx: Desconectando"
echo "================================"
echo ""

# Requerir sudo
if [ "$EUID" -ne 0 ]; then
    echo -e "${YELLOW}Este script requiere sudo. Reintentando...${NC}"
    exec sudo "$0" "$@"
fi

INTERFACE="${WIFI_INTERFACE:-wlan0}"

# Detener Chrony
echo -e "${BLUE}→ Deteniendo Chrony...${NC}"
pkill chronyd 2>/dev/null || true
systemctl stop chronyd 2>/dev/null || true
if [ $? -eq 0 ] || [ $? -eq 1 ]; then
    echo -e "${GREEN}✓ Chrony detenido${NC}"
fi

# Desconectar del hotspot
echo -e "${BLUE}→ Desconectando de $HOTSPOT_SSID...${NC}"
nmcli device disconnect "$INTERFACE" 2>/dev/null || true
if [ $? -eq 0 ] || [ $? -eq 1 ]; then
    echo -e "${GREEN}✓ Interfaz desconectada${NC}"
fi

# Limpiar archivos temporales
echo -e "${BLUE}→ Limpiando archivos temporales...${NC}"
rm -f /tmp/chrony_rx_runtime.conf
rm -rf /tmp/chrony_rx_logs

echo ""
echo "================================"
echo "   Desconexión completada"
echo "================================"
echo ""
echo -e "${GREEN}✓ Chrony detenido${NC}"
echo -e "${GREEN}✓ Desconectado del hotspot${NC}"
