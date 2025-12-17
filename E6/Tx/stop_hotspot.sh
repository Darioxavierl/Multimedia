#!/bin/bash
# Script para detener el hotspot WiFi, DHCP y Chrony

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
echo "   Tx: Deteniendo servicios"
echo "================================"
echo ""

# Requerir sudo
if [ "$EUID" -ne 0 ]; then
    echo -e "${YELLOW}Este script requiere sudo. Reintentando...${NC}"
    exec sudo "$0" "$@"
fi

INTERFACE="${WIFI_INTERFACE:-wlan0}"

# Detener Chrony y restaurar configuración original
echo -e "${BLUE}→ Deteniendo Chrony...${NC}"
systemctl stop chrony 2>/dev/null || true
pkill chronyd 2>/dev/null || true

# Restaurar configuración original
if [ -f "/etc/chrony/chrony.conf.backup" ]; then
    echo -e "${BLUE}→ Restaurando configuración original de Chrony...${NC}"
    cp /etc/chrony/chrony.conf.backup /etc/chrony/chrony.conf
    echo -e "${GREEN}✓ Configuración restaurada${NC}"
fi

echo -e "${GREEN}✓ Chrony detenido${NC}"

# Detener DHCP (dnsmasq) - si fue instalado
echo -e "${BLUE}→ Limpiando DHCP si estaba activo...${NC}"
pkill dnsmasq 2>/dev/null || true
systemctl restart systemd-resolved 2>/dev/null || true

# Desconectar interfaz WiFi
echo -e "${BLUE}→ Desconectando interfaz $INTERFACE...${NC}"
nmcli device disconnect "$INTERFACE" 2>/dev/null || true
if [ $? -eq 0 ] || [ $? -eq 1 ]; then
    echo -e "${GREEN}✓ Interfaz desconectada${NC}"
fi

# Remover IP estática
echo -e "${BLUE}→ Removiendo IP estática...${NC}"
ip addr flush dev "$INTERFACE" 2>/dev/null || true
if [ $? -eq 0 ] || [ $? -eq 1 ]; then
    echo -e "${GREEN}✓ IP removida${NC}"
fi

echo ""
echo "================================"
echo "   Servicios detenidos"
echo "================================"
echo ""
echo -e "${GREEN}✓ Hotspot detenido${NC}"
echo -e "${GREEN}✓ Chrony detenido${NC}"
echo -e "${GREEN}✓ DHCP detenido${NC}"
