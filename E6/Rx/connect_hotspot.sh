#!/bin/bash
# Script para:
# 1) Conectarse a un hotspot WiFi
# 2) Iniciar Chrony como cliente contra el Tx
#
# Requisitos:
#   - Archivo .env en el mismo directorio con la configuración
#
# Uso:
#   ./connect_hotspot.sh
#   o con parámetros manuales:
#   ./connect_hotspot.sh <INTERFACE> <SSID> <PASSWORD> <SERVER_IP>

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
SERVER_IP="${4:-$TX_SERVER_IP}"

# Valores por defecto para opciones avanzadas (si no están en .env)
CONNECT_TIMEOUT="${CONNECT_TIMEOUT:-30}"
DHCP_TIMEOUT="${DHCP_TIMEOUT:-15}"
PING_ATTEMPTS="${PING_ATTEMPTS:-3}"
RETRY_WAIT="${RETRY_WAIT:-2}"
CHRONY_START_TIMEOUT="${CHRONY_START_TIMEOUT:-10}"

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "================================"
echo "   Rx: WiFi + Chrony cliente"
echo "================================"
echo ""
echo "Configuración:"
echo "  Interfaz: $INTERFACE"
echo "  SSID: $SSID"
echo "  Servidor Tx: $SERVER_IP"
echo ""

# Verificar parámetros
if [ -z "$INTERFACE" ] || [ -z "$SSID" ] || [ -z "$PASSWORD" ] || [ -z "$SERVER_IP" ]; then
    echo -e "${RED}Error: Faltan parámetros${NC}"
    echo ""
    echo "Uso: $0 [INTERFACE] [SSID] [PASSWORD] [SERVER_IP]"
    echo ""
    echo "Ejemplo con CLI:"
    echo "  $0 wlan0 evalvid_lab 12345678 192.168.12.1"
    echo ""
    echo "Ejemplo con .env:"
    echo "  $0"
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
# 1. Conectarse al hotspot
# --------------------------------------------------
echo -e "${BLUE}→ Conectando a la red WiFi...${NC}"
echo "  SSID: $SSID"
echo ""

nmcli device disconnect "$INTERFACE" 2>/dev/null || true

nmcli device wifi connect "$SSID" password "$PASSWORD" ifname "$INTERFACE"

if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Error al conectar al hotspot${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Conectado al hotspot${NC}"

# Esperar IP con timeout
echo -e "${BLUE}→ Esperando asignación de IP (timeout: ${DHCP_TIMEOUT}s)...${NC}"
ELAPSED=0
while [ $ELAPSED -lt $DHCP_TIMEOUT ]; do
    IP_ADDR=$(nmcli -g IP4.ADDRESS device show "$INTERFACE" 2>/dev/null | head -n 1)
    if [ -n "$IP_ADDR" ]; then
        break
    fi
    sleep 1
    ELAPSED=$((ELAPSED + 1))
done

if [ -z "$IP_ADDR" ]; then
    echo -e "${RED}✗ No se obtuvo dirección IP${NC}"
    exit 1
fi

echo -e "${GREEN}✓ IP asignada: $IP_ADDR${NC}"

# Obtener la puerta de enlace (Tx) automáticamente si no está configurada
if [ -z "$SERVER_IP" ] || [ "$SERVER_IP" == "192.168.12.1" ]; then
    echo -e "${BLUE}→ Detectando servidor Tx automáticamente...${NC}"
    DETECTED_GATEWAY=$(ip route show dev "$INTERFACE" 2>/dev/null | grep "default via" | awk '{print $3}')
    if [ -n "$DETECTED_GATEWAY" ]; then
        SERVER_IP="$DETECTED_GATEWAY"
        echo -e "${GREEN}✓ Servidor Tx detectado: $SERVER_IP${NC}"
    fi
fi

# --------------------------------------------------
# 2. Verificar reachability del servidor
# --------------------------------------------------
echo -e "${BLUE}→ Verificando conectividad (${PING_ATTEMPTS} intentos)...${NC}"

if ping -c "$PING_ATTEMPTS" "$SERVER_IP" &>/dev/null; then
    echo -e "${GREEN}✓ Servidor $SERVER_IP alcanzable${NC}"
else
    echo -e "${RED}✗ No se puede alcanzar el servidor Chrony${NC}"
    exit 1
fi

# --------------------------------------------------
# 3. Iniciar Chrony como cliente
# --------------------------------------------------
echo -e "${BLUE}→ Configurando Chrony como cliente...${NC}"

if ! command -v chronyd &>/dev/null; then
    echo -e "${RED}Chrony no está instalado. Instálalo primero.${NC}"
    exit 1
fi

# Detener chronyd si estaba corriendo
echo -e "${BLUE}→ Deteniendo instancia anterior de chronyd...${NC}"
systemctl stop chrony 2>/dev/null || true
pkill chronyd 2>/dev/null || true
sleep 1

# Crear directorio de logs si no existe
mkdir -p /tmp/chrony_rx_logs 2>/dev/null || true

# Preparar configuración con la IP del servidor
echo -e "${BLUE}→ Configurando Chrony como cliente...${NC}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CHRONY_CONF_TEMPLATE="$SCRIPT_DIR/config/chrony_rx.conf"

if [ ! -f "$CHRONY_CONF_TEMPLATE" ]; then
    echo -e "${RED}✗ Archivo no encontrado: $CHRONY_CONF_TEMPLATE${NC}"
    exit 1
fi

# Generar configuración dinámica reemplazando TX_IP
sed "s/TX_IP/$SERVER_IP/g" "$CHRONY_CONF_TEMPLATE" | grep -v "^$" | grep -v "^[[:space:]]*$" > /tmp/chrony_rx_runtime.conf

# Verificar que se generó correctamente
if [ ! -f "/tmp/chrony_rx_runtime.conf" ] || [ ! -s "/tmp/chrony_rx_runtime.conf" ]; then
    echo -e "${RED}✗ Error al generar configuración temporal${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Configuración generada: /tmp/chrony_rx_runtime.conf${NC}"
grep "server" /tmp/chrony_rx_runtime.conf

# Mostrar el contenido generado para debugging
echo -e "${BLUE}→ Contenido de la configuración (lineas significativas):${NC}"
cat /tmp/chrony_rx_runtime.conf | nl

# Respaldar y copiar configuración al sistema
if [ -f "/etc/chrony/chrony.conf" ]; then
    echo -e "${BLUE}→ Instalando configuración personalizada de Chrony...${NC}"
    cp /etc/chrony/chrony.conf /etc/chrony/chrony.conf.backup 2>/dev/null
    # Crear un archivo limpio sin el contenido original
    cat /tmp/chrony_rx_runtime.conf > /etc/chrony/chrony.conf
    
    # Verificar permisos
    chmod 644 /etc/chrony/chrony.conf 2>/dev/null || true
    
    # Verificar que se copió correctamente
    echo -e "${BLUE}→ Verificando archivo final en /etc/chrony/chrony.conf:${NC}"
    wc -l /etc/chrony/chrony.conf
    cat /etc/chrony/chrony.conf | nl
fi

# Iniciar Chrony con systemctl
echo -e "${BLUE}→ Iniciando Chrony como cliente...${NC}"
if systemctl start chrony 2>/dev/null; then
    sleep 2
    echo -e "${GREEN}✓ Chrony iniciado${NC}"
else
    echo -e "${RED}✗ Error al iniciar Chrony con systemctl${NC}"
    echo -e "${YELLOW}→ Intentando diagnóstico...${NC}"
    systemctl status chrony 2>&1 | head -20
    echo ""
    echo -e "${YELLOW}Contenido del archivo /etc/chrony/chrony.conf:${NC}"
    cat /etc/chrony/chrony.conf | nl | head -30
    echo ""
    echo -e "${YELLOW}Posibles soluciones:${NC}"
    echo "  1. Revisa la línea 22 del archivo de configuración"
    echo "  2. Instala Chrony: sudo apt-get install chrony"
    echo "  3. Revisa logs: sudo journalctl -u chrony -n 20"
    echo ""
    echo "Comando para depuración:"
    echo "  sudo chronyd -f /etc/chrony/chrony.conf 2>&1 | head -20"
    exit 1
fi

# Esperar a que sincronice (con timeout)
echo -e "${BLUE}→ Esperando sincronización (${CHRONY_START_TIMEOUT}s)...${NC}"
ELAPSED=0
while [ $ELAPSED -lt $CHRONY_START_TIMEOUT ]; do
    if chronyc tracking > /dev/null 2>&1; then
        break
    fi
    sleep 1
    ELAPSED=$((ELAPSED + 1))
done

# Verificar estado
echo -e "${BLUE}→ Verificando estado de Chrony...${NC}"

if chronyc tracking > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Chrony operativo${NC}"
    chronyc tracking
else
    echo -e "${YELLOW}⚠ Chrony aún no sincronizado, continuando...${NC}"
fi

# Mostrar fuentes de sincronización
echo ""
chronyc sources -v 2>/dev/null || echo "⚠ Fuentes de sincronización no disponibles aún"

# --------------------------------------------------
# 4. Estado final
# --------------------------------------------------
echo ""
echo "================================"
echo "   Rx listo para experimentos"
echo "================================"
echo ""

echo -e "${GREEN}✓ Conectado a $SSID${NC}"
echo -e "${GREEN}✓ Chrony sincronizando con $SERVER_IP${NC}"
echo ""
echo "Puedes iniciar la recepción EvalVid."
