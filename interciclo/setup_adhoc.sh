#!/bin/bash
# Script para configurar red ad-hoc para VideoConferencia P2P
# Uso: ./setup_adhoc.sh IP_ADRESS INTERFACE

ESSID="videoconf"
CHANNEL=6
IP_ADDRESS=$1
INTERFACE=$2

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "================================"
echo "Configuración de Red Ad-Hoc"
echo "================================"
echo ""

# Verificar argumentos
if [ -z "$IP_ADDRESS" ]; then
    echo -e "${RED}Error: Falta la dirección IP${NC}"
    echo ""
    echo "Uso: $0 <IP_ADDRESS>"
    echo ""
    echo "Ejemplos:"
    echo "  Dispositivo 1: $0 192.168.1.1"
    echo "  Dispositivo 2: $0 192.168.1.2"
    echo ""
    exit 1
fi

# Verificar formato de IP
if ! [[ $IP_ADDRESS =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    echo -e "${RED}Error: Formato de IP inválido${NC}"
    echo "Usa formato: 192.168.1.X"
    exit 1
fi

# Verificar si se ejecuta con sudo
if [ "$EUID" -ne 0 ]; then
    echo -e "${YELLOW}Este script requiere permisos de superusuario${NC}"
    echo "Reintentando con sudo..."
    exec sudo "$0" "$@"
fi

# Verificar que la interfaz existe
if ! ip link show "$INTERFACE" &> /dev/null; then
    echo -e "${RED}Error: Interfaz $INTERFACE no encontrada${NC}"
    echo ""
    echo "Interfaces inalámbricas disponibles:"
    ip link show | grep -E "^[0-9]+" | awk '{print $2}' | sed 's/://g' | grep -E "wl|wlan"
    echo ""
    read -p "Ingresa el nombre de tu interfaz inalámbrica: " INTERFACE
    
    if ! ip link show "$INTERFACE" &> /dev/null; then
        echo -e "${RED}Interfaz $INTERFACE no válida${NC}"
        exit 1
    fi
fi

echo -e "${BLUE}Configuración:${NC}"
echo "  Interfaz: $INTERFACE"
echo "  ESSID: $ESSID"
echo "  Canal: $CHANNEL"
echo "  IP: $IP_ADDRESS/24"
echo ""

# Detener NetworkManager en la interfaz
echo "→ Desactivando NetworkManager en $INTERFACE..."
nmcli device set "$INTERFACE" managed no 2>/dev/null || echo "  (NetworkManager no disponible, continuando...)"

# Detener wpa_supplicant si está corriendo
echo "→ Deteniendo wpa_supplicant..."
killall wpa_supplicant 2>/dev/null || true

# Bajar la interfaz
echo "→ Bajando interfaz..."
ip link set "$INTERFACE" down
sleep 1

# Configurar modo ad-hoc
echo "→ Configurando modo ad-hoc..."
iwconfig "$INTERFACE" mode ad-hoc
if [ $? -ne 0 ]; then
    echo -e "${YELLOW}  Advertencia: Algunos controladores pueden no soportar modo ad-hoc${NC}"
fi

iwconfig "$INTERFACE" essid "$ESSID"
iwconfig "$INTERFACE" channel "$CHANNEL"

# Levantar la interfaz
echo "→ Levantando interfaz..."
ip link set "$INTERFACE" up
sleep 2

# Asignar IP
echo "→ Asignando dirección IP..."
ip addr flush dev "$INTERFACE"
ip addr add "$IP_ADDRESS/24" dev "$INTERFACE"

# Deshabilitar power management
echo "→ Deshabilitando power management..."
iwconfig "$INTERFACE" power off 2>/dev/null || echo "  (No soportado en este dispositivo)"

# Ajustar tasa de transmisión (opcional, mejora estabilidad)
echo "→ Ajustando parámetros de transmisión..."
iwconfig "$INTERFACE" rate 54M 2>/dev/null || true

# Verificar configuración
echo ""
echo "================================"
echo "Verificando configuración..."
echo "================================"

# Esperar un poco más para que la interfaz se estabilice
sleep 2

# Mostrar estado de la interfaz
echo ""
echo -e "${BLUE}Estado de $INTERFACE:${NC}"
iwconfig "$INTERFACE" 2>/dev/null | grep -E "Mode:|ESSID:|Frequency:|Bit Rate:|Tx-Power:|Power Management:"

echo ""
echo -e "${BLUE}Dirección IP:${NC}"
ip addr show "$INTERFACE" | grep "inet " | awk '{print "  " $2}'

# Verificar conectividad básica
echo ""
echo -e "${BLUE}Verificando interfaz activa:${NC}"
if ip link show "$INTERFACE" | grep -q "state UP"; then
    echo -e "  ${GREEN}✓${NC} Interfaz levantada correctamente"
else
    echo -e "  ${RED}✗${NC} La interfaz no está activa"
fi

echo ""
echo -e "${GREEN}✓ Configuración completada${NC}"
echo ""
echo "================================"
echo "Próximos pasos"
echo "================================"
echo ""
echo -e "${BLUE}1. Configura el otro dispositivo con una IP diferente:${NC}"
if [[ "$IP_ADDRESS" == "192.168.1.1" ]]; then
    echo "   ./setup_adhoc.sh 192.168.1.2"
    OTHER_IP="192.168.1.2"
else
    echo "   ./setup_adhoc.sh 192.168.1.1"
    OTHER_IP="192.168.1.1"
fi
echo ""
echo -e "${BLUE}2. Verifica conectividad (desde este dispositivo):${NC}"
echo "   ping $OTHER_IP"
echo ""
echo -e "${BLUE}3. Configura la aplicación con estas direcciones:${NC}"
echo "   TX: udp://$OTHER_IP:39400"
echo "   RX: udp://@:39400"
echo ""
echo -e "${BLUE}4. Ejecuta la aplicación:${NC}"
echo "   python3 main.py"
echo ""
echo "================================"
echo "Comandos útiles"
echo "================================"
echo ""
echo "Ver estado de la red:"
echo "  iwconfig $INTERFACE"
echo "  ip addr show $INTERFACE"
echo ""
echo "Probar conectividad:"
echo "  ping $OTHER_IP"
echo ""
echo "Ver dispositivos conectados (opcional):"
echo "  arp -a"
echo ""
echo "Para restaurar la configuración de red normal:"
echo "  sudo nmcli device set $INTERFACE managed yes"
echo "  sudo systemctl restart NetworkManager"
echo ""
echo "================================"
echo ""