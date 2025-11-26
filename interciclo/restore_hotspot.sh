#!/bin/bash
# Script para restaurar la interfaz después de usar un hotspot
# Uso: ./restore_hotspot.sh <INTERFACE>

INTERFACE=$1

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "================================"
echo " Restauración de Interfaz WiFi"
echo "================================"
echo ""

# Verificar parámetros
if [ -z "$INTERFACE" ]; then
    echo -e "${RED}Error: Falta la interfaz${NC}"
    echo ""
    echo "Uso: $0 <INTERFACE>"
    echo ""
    echo "Ejemplo:"
    echo "  $0 wlan0"
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
    echo -e "${RED}Interfaz $INTERFACE no encontrada${NC}"
    exit 1
fi

echo -e "${BLUE}→ Deteniendo hotspot en $INTERFACE${NC}"

echo "→ Desconectando interfaz..."
nmcli device disconnect "$INTERFACE" 2>/dev/null || true

echo "→ Restaurando control de NetworkManager..."
nmcli device set "$INTERFACE" managed yes 2>/dev/null || true

echo "→ Reiniciando NetworkManager..."
systemctl restart NetworkManager

echo ""
echo "================================"
echo " Estado de la interfaz"
echo "================================"
ip addr show "$INTERFACE" | grep "inet " || echo "Sin IP asignada aún"

echo ""
echo -e "${GREEN}✓ La interfaz ha sido restaurada correctamente${NC}"
