#!/bin/bash
# Script para:
# 1) Iniciar Chrony como servidor local
# 2) Crear un hotspot WiFi con nmcli y configurar DHCP
#
# Requisitos:
#   - Archivo .env en el mismo directorio con la configuración
#   - dnsmasq instalado para DHCP
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

# Detener chronyd si estaba corriendo (systemctl o instancia anterior)
echo -e "${BLUE}→ Deteniendo instancia anterior de chronyd...${NC}"
pkill chronyd 2>/dev/null || true
systemctl stop chronyd 2>/dev/null || true
sleep 1

# Iniciar chronyd como servidor con la configuración específica de Tx
echo -e "${BLUE}→ Iniciando chronyd como servidor (Tx)...${NC}"
chronyd -f config/chrony_tx.conf

# Espera breve para que el daemon esté listo
sleep 2

# Prueba básica
if chronyc tracking &>/dev/null; then
    echo -e "${GREEN}✓ Chrony operativo como servidor${NC}"
    chronyc tracking
else
    echo -e "${RED}✗ Chrony no responde${NC}"
    exit 1
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

echo "→ Iniciando hotspot..."
nmcli dev wifi hotspot ifname "$INTERFACE" ssid "$SSID" password "$PASSWORD"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Hotspot creado correctamente${NC}"
else
    echo -e "${RED}✗ Error al crear el hotspot${NC}"
    exit 1
fi

# Esperar a que la interfaz esté lista
sleep 2

# Configurar IP estática en la interfaz
echo "→ Configurando IP estática en $INTERFACE: $GATEWAY_IP/$NETWORK_MASK..."
ip addr add "$GATEWAY_IP/$NETWORK_MASK" dev "$INTERFACE" 2>/dev/null || \
ip addr replace "$GATEWAY_IP/$NETWORK_MASK" dev "$INTERFACE"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ IP configurada${NC}"
else
    echo -e "${RED}✗ Error al configurar IP${NC}"
    exit 1
fi

# Configurar DHCP si dnsmasq está disponible
echo "→ Configurando servidor DHCP..."
if command -v dnsmasq &>/dev/null; then
    # Crear configuración temporal de dnsmasq
    DNSMASQ_CONF="/tmp/dnsmasq_hotspot.conf"
    cat > "$DNSMASQ_CONF" << EOF
# Configuración de dnsmasq para hotspot
interface=$INTERFACE
dhcp-range=$DHCP_START,$DHCP_END,${NETWORK_MASK},$((DHCP_LEASE / 60))m
dhcp-option=option:router,$GATEWAY_IP
dhcp-option=option:dns-server,$GATEWAY_IP
address=/#/$GATEWAY_IP
EOF

    # Detener dnsmasq anterior si existe
    pkill dnsmasq 2>/dev/null || true
    sleep 1

    # Iniciar dnsmasq
    dnsmasq -C "$DNSMASQ_CONF"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ DHCP configurado correctamente${NC}"
        echo "  Rango: $DHCP_START - $DHCP_END"
        echo "  Gateway: $GATEWAY_IP"
        echo "  Lease: $DHCP_LEASE segundos"
    else
        echo -e "${YELLOW}⚠ Error al iniciar dnsmasq, pero hotspot está activo${NC}"
    fi
else
    echo -e "${YELLOW}⚠ dnsmasq no instalado. El hotspot está activo pero sin DHCP.${NC}"
    echo "   Instala dnsmasq para habilitar DHCP: sudo apt install dnsmasq"
fi


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
ip addr show "$INTERFACE" | grep "inet " || true

echo ""
echo -e "${GREEN}✓ Chrony activo (servidor local)${NC}"
echo -e "${GREEN}✓ Hotspot activo${NC}"
echo -e "${GREEN}✓ DHCP activo (pool: $DHCP_START - $DHCP_END)${NC}"
echo ""
echo "Instrucciones para el Rx:"
echo "  $0 wlan0 $SSID $PASSWORD $GATEWAY_IP"
echo ""
echo "Puedes ahora conectar el Rx y sincronizarlo."
