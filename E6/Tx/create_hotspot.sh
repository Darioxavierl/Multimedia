#!/bin/bash
# Script para:
# 1) Iniciar Chrony como servidor local
# 2) Crear un hotspot WiFi con nmcli y configurar DHCP
#
# Requisitos:
#   - Archivo .env en el mismo directorio con la configuración
#   - NetworkManager para crear hotspot (DHCP automático)
#
# Uso:
#   ./create_hotspot.sh
#   o con parámetros manuales:
#   ./create_hotspot.sh <INTERFACE> <SSID> <PASSWORD>

# Cargar variables desde .env si existe
ENV_FILE="$(dirname "$0")/.env"
if [ -f "$ENV_FILE" ]; then
    source "$ENV_FILE"
    echo "✓ Configuración cargada desde .env"
else
    echo "⚠ Archivo .env no encontrado, usando parámetros de línea de comandos"
fi

# Permitir override de parámetros via línea de comandos
INTERFACE="${1:-$WIFI_INTERFACE}"
SSID="${2:-$HOTSPOT_SSID}"
PASSWORD="${3:-$HOTSPOT_PASSWORD}"

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "================================"
echo "   Tx: Chrony + Hotspot WiFi"
echo "================================"
echo ""

# Verificar parámetros
if [ -z "$INTERFACE" ] || [ -z "$SSID" ] || [ -z "$PASSWORD" ]; then
    echo -e "${RED}Error: Faltan parámetros${NC}"
    echo ""
    echo "Uso: $0 <INTERFACE> <SSID> <PASSWORD>"
    echo ""
    echo "Ejemplo:"
    echo "  $0 wlan0 evalvid_lab 12345678"
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

# --------------------------------------------------
# 1. Verificar / iniciar Chrony como servidor
# --------------------------------------------------
echo -e "${BLUE}→ Verificando Chrony...${NC}"

if ! command -v chronyd &>/dev/null; then
    echo -e "${RED}Chrony no está instalado. Instálalo primero.${NC}"
    exit 1
fi

# Detener chronyd si estaba corriendo
echo -e "${BLUE}→ Deteniendo instancia anterior de chronyd...${NC}"
systemctl stop chrony 2>/dev/null || true
pkill chronyd 2>/dev/null || true
sleep 1

# Configurar Chrony como servidor con la configuración específica de Tx
echo -e "${BLUE}→ Configurando Chrony como servidor (Tx)...${NC}"

# Ruta absoluta al config de Chrony
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CHRONY_CONF="$SCRIPT_DIR/config/chrony_tx.conf"

if [ ! -f "$CHRONY_CONF" ]; then
    echo -e "${RED}✗ Archivo no encontrado: $CHRONY_CONF${NC}"
    exit 1
fi

# Respaldar configuración original y copiar la nueva
if [ -f "/etc/chrony/chrony.conf" ]; then
    echo -e "${BLUE}→ Instalando configuración personalizada de Chrony...${NC}"
    cp /etc/chrony/chrony.conf /etc/chrony/chrony.conf.backup 2>/dev/null
    cp "$CHRONY_CONF" /etc/chrony/chrony.conf
else
    echo -e "${YELLOW}⚠ /etc/chrony/chrony.conf no encontrado, usando configuración alternativa${NC}"
fi

# Iniciar Chrony con systemctl
echo -e "${BLUE}→ Iniciando Chrony...${NC}"
if systemctl start chrony 2>/dev/null; then
    sleep 2
else
    echo -e "${RED}✗ No se pudo iniciar Chrony con systemctl${NC}"
    echo -e "${YELLOW}Intenta instalarlo: sudo apt-get install chrony${NC}"
    exit 1
fi

# Prueba básica
if chronyc tracking > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Chrony operativo como servidor${NC}"
    chronyc tracking
else
    echo -e "${RED}✗ Chrony no responde después de 2 segundos${NC}"
    echo -e "${YELLOW}→ Revisando estado...${NC}"
    systemctl status chrony 2>/dev/null || echo "Estado de chrony no disponible"
    echo -e "${YELLOW}Espera unos segundos e intenta nuevamente: chronyc tracking${NC}"
    # No salir, permitir continuar con el hotspot
fi

# --------------------------------------------------
# 2. Crear hotspot WiFi y configurar DHCP
# --------------------------------------------------
echo ""
echo -e "${BLUE}→ Activando hotspot en $INTERFACE${NC}"
echo "  SSID: $SSID"
echo "  Password: $PASSWORD"
echo "  Gateway IP: $GATEWAY_IP/$NETWORK_MASK"
echo "  DHCP Range: $DHCP_START - $DHCP_END"
echo ""

echo "→ Deteniendo posibles conexiones previas..."
nmcli device disconnect "$INTERFACE" 2>/dev/null || true
sleep 1

echo "→ Iniciando hotspot..."
nmcli dev wifi hotspot ifname "$INTERFACE" ssid "$SSID" password "$PASSWORD" 2>&1

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Hotspot creado correctamente${NC}"
    sleep 2  # Esperar a que NetworkManager asigne IP
else
    echo -e "${RED}✗ Error al crear el hotspot${NC}"
    echo "Verificando estado de NetworkManager..."
    nmcli device status
    exit 1
fi

# Mostrar IP asignada automáticamente por NetworkManager
echo -e "${BLUE}→ IP asignada por NetworkManager:${NC}"
ip addr show "$INTERFACE" | grep -E "inet |state" || true

echo -e "${GREEN}✓ Hotspot activo con DHCP automático${NC}"


# --------------------------------------------------
# 3. Estado final de Chrony
# --------------------------------------------------

echo -e "${GREEN}✓ Chrony funcionando como servidor${NC}"
chronyc sources -v


# --------------------------------------------------
# 4. Información final
# --------------------------------------------------
echo ""
echo "================================"
echo "   Tx listo para experimentos"
echo "================================"
echo ""

# Mostrar información de la red
echo -e "${GREEN}Configuración de red:${NC}"
ip addr show "$INTERFACE" | grep -E "inet |state" || true

echo ""
echo -e "${GREEN}✓ Chrony activo (servidor local)${NC}"
echo -e "${GREEN}✓ Hotspot activo${NC}"
echo -e "${GREEN}✓ DHCP automático via NetworkManager${NC}"
echo ""
echo "Instrucciones para el Rx:"
echo "  sudo ./Rx/connect_hotspot.sh"
echo ""
echo "Puedes ahora conectar el Rx y sincronizarlo."
