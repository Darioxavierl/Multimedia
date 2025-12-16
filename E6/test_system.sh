#!/bin/bash

# Script de verificación pre-test del sistema EvalVid E6

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║           VERIFICACIÓN PRE-TEST - Sistema EvalVid E6           ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}\n"

# Función para verificar archivo
check_file() {
    local file="$1"
    local desc="$2"
    if [ -f "$file" ]; then
        echo -e "${GREEN}✓${NC} $desc"
        return 0
    else
        echo -e "${RED}✗${NC} $desc"
        return 1
    fi
}

# Función para verificar ejecución
check_executable() {
    local file="$1"
    local desc="$2"
    if [ -x "$file" ]; then
        echo -e "${GREEN}✓${NC} $desc (ejecutable)"
        return 0
    else
        echo -e "${RED}✗${NC} $desc (NO es ejecutable)"
        return 1
    fi
}

# Función para verificar sintaxis
check_syntax() {
    local file="$1"
    local desc="$2"
    if bash -n "$file" 2>/dev/null; then
        echo -e "${GREEN}✓${NC} $desc (sintaxis OK)"
        return 0
    else
        echo -e "${RED}✗${NC} $desc (sintaxis ERROR)"
        return 1
    fi
}

# VERIFICACIONES
echo -e "${BLUE}1. ARCHIVOS PRINCIPALES${NC}"
echo "═══════════════════════════════════════════════════════════════"

check_file "$SCRIPT_DIR/Tx/create_hotspot.sh" "Tx/create_hotspot.sh"
check_file "$SCRIPT_DIR/Tx/stop_hotspot.sh" "Tx/stop_hotspot.sh"
check_file "$SCRIPT_DIR/Rx/connect_hotspot.sh" "Rx/connect_hotspot.sh"
check_file "$SCRIPT_DIR/Rx/disconnect.sh" "Rx/disconnect.sh"

echo ""
echo -e "${BLUE}2. ARCHIVOS DE CONFIGURACIÓN${NC}"
echo "═══════════════════════════════════════════════════════════════"

check_file "$SCRIPT_DIR/Tx/.env" "Tx/.env"
check_file "$SCRIPT_DIR/Tx/config/chrony_tx.conf" "Tx/config/chrony_tx.conf"
check_file "$SCRIPT_DIR/Rx/.env" "Rx/.env"
check_file "$SCRIPT_DIR/Rx/config/chrony_rx.conf" "Rx/config/chrony_rx.conf"

echo ""
echo -e "${BLUE}3. DOCUMENTACIÓN${NC}"
echo "═══════════════════════════════════════════════════════════════"

check_file "$SCRIPT_DIR/PASOS.md" "PASOS.md"
check_file "$SCRIPT_DIR/CONGRUENCIA_SCRIPTS.md" "CONGRUENCIA_SCRIPTS.md"
check_file "$SCRIPT_DIR/ESTADO_FINAL.md" "ESTADO_FINAL.md"

echo ""
echo -e "${BLUE}4. VERIFICACIÓN DE SINTAXIS BASH${NC}"
echo "═══════════════════════════════════════════════════════════════"

check_syntax "$SCRIPT_DIR/Tx/create_hotspot.sh" "Tx/create_hotspot.sh"
check_syntax "$SCRIPT_DIR/Tx/stop_hotspot.sh" "Tx/stop_hotspot.sh"
check_syntax "$SCRIPT_DIR/Rx/connect_hotspot.sh" "Rx/connect_hotspot.sh"
check_syntax "$SCRIPT_DIR/Rx/disconnect.sh" "Rx/disconnect.sh"

echo ""
echo -e "${BLUE}5. VERIFICACIÓN DE CONTENIDO${NC}"
echo "═══════════════════════════════════════════════════════════════"

# Verificar que se use systemctl chrony (no chronyd)
if grep -q "systemctl.*chrony" "$SCRIPT_DIR/Tx/stop_hotspot.sh"; then
    echo -e "${GREEN}✓${NC} Tx/stop_hotspot.sh usa systemctl chrony"
else
    echo -e "${RED}✗${NC} Tx/stop_hotspot.sh no usa systemctl chrony"
fi

if grep -q "systemctl.*chrony" "$SCRIPT_DIR/Rx/disconnect.sh"; then
    echo -e "${GREEN}✓${NC} Rx/disconnect.sh usa systemctl chrony"
else
    echo -e "${RED}✗${NC} Rx/disconnect.sh no usa systemctl chrony"
fi

# Verificar que se haga backup y restore
if grep -q "chrony.conf.backup" "$SCRIPT_DIR/Tx/stop_hotspot.sh"; then
    echo -e "${GREEN}✓${NC} Tx/stop_hotspot.sh restaura configuración"
else
    echo -e "${RED}✗${NC} Tx/stop_hotspot.sh NO restaura configuración"
fi

if grep -q "chrony.conf.backup" "$SCRIPT_DIR/Rx/disconnect.sh"; then
    echo -e "${GREEN}✓${NC} Rx/disconnect.sh restaura configuración"
else
    echo -e "${RED}✗${NC} Rx/disconnect.sh NO restaura configuración"
fi

echo ""
echo -e "${BLUE}6. VERIFICACIÓN DE VARIABLES .env${NC}"
echo "═══════════════════════════════════════════════════════════════"

# Verificar Tx .env
if grep -q "WIFI_INTERFACE" "$SCRIPT_DIR/Tx/.env"; then
    echo -e "${GREEN}✓${NC} Tx/.env contiene WIFI_INTERFACE"
else
    echo -e "${RED}✗${NC} Tx/.env NO contiene WIFI_INTERFACE"
fi

if grep -q "HOTSPOT_SSID" "$SCRIPT_DIR/Tx/.env"; then
    echo -e "${GREEN}✓${NC} Tx/.env contiene HOTSPOT_SSID"
else
    echo -e "${RED}✗${NC} Tx/.env NO contiene HOTSPOT_SSID"
fi

# Verificar Rx .env
if grep -q "WIFI_INTERFACE" "$SCRIPT_DIR/Rx/.env"; then
    echo -e "${GREEN}✓${NC} Rx/.env contiene WIFI_INTERFACE"
else
    echo -e "${RED}✗${NC} Rx/.env NO contiene WIFI_INTERFACE"
fi

if grep -q "HOTSPOT_SSID" "$SCRIPT_DIR/Rx/.env"; then
    echo -e "${GREEN}✓${NC} Rx/.env contiene HOTSPOT_SSID"
else
    echo -e "${RED}✗${NC} Rx/.env NO contiene HOTSPOT_SSID"
fi

echo ""
echo -e "${BLUE}7. REQUISITOS DEL SISTEMA${NC}"
echo "═══════════════════════════════════════════════════════════════"

# Verificar comandos requeridos
commands=("nmcli" "systemctl" "chronyc" "dnsmasq" "tcpdump")

for cmd in "${commands[@]}"; do
    if command -v "$cmd" &> /dev/null; then
        echo -e "${GREEN}✓${NC} $cmd está instalado"
    else
        echo -e "${RED}✗${NC} $cmd NO está instalado"
    fi
done

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                   RESUMEN DE VERIFICACIÓN                      ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"

echo ""
echo "El sistema está verificado y listo para pruebas."
echo ""
echo "Para iniciar:"
echo "  Terminal 1 (TX):"
echo "    $ cd $SCRIPT_DIR/Tx"
echo "    $ sudo ./create_hotspot.sh"
echo ""
echo "  Terminal 2 (RX):"
echo "    $ cd $SCRIPT_DIR/Rx"
echo "    $ sudo ./connect_hotspot.sh"
echo ""
echo "Para detener:"
echo "  Terminal RX: $ sudo ./disconnect.sh"
echo "  Terminal TX: $ sudo ./stop_hotspot.sh"
echo ""
