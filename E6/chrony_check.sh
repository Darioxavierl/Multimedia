#!/bin/bash

set -e

echo "========================================"
echo "  Verificando instalación de Chrony"
echo "========================================"

# 1. Verificar si chronyd existe
if ! command -v chronyd &> /dev/null; then
    echo "[INFO] Chrony no está instalado. Instalando..."

    sudo apt update
    sudo apt install -y chrony

    echo "[OK] Chrony instalado correctamente."
else
    echo "[OK] Chrony ya está instalado."
fi

echo
echo "========================================"
echo "  Verificando servicio chronyd"
echo "========================================"

# 2. Verificar estado del servicio
if systemctl is-active --quiet chronyd; then
    echo "[INFO] chronyd ya está activo."
else
    echo "[INFO] Iniciando chronyd para prueba..."
    sudo systemctl start chronyd
fi

# 3. Esperar un poco para que arranque
sleep 3

# 4. Comprobar que responde
echo
echo "========================================"
echo "  Probando funcionamiento de Chrony"
echo "========================================"

if chronyc tracking &> /dev/null; then
    echo "[OK] Chrony responde correctamente."
    chronyc tracking
else
    echo "[ERROR] Chrony no responde correctamente."
    exit 1
fi

# 5. Detener el servicio (estado limpio)
echo
echo "========================================"
echo "  Deteniendo chronyd (estado limpio)"
echo "========================================"

sudo systemctl stop chronyd

if systemctl is-active --quiet chronyd; then
    echo "[ERROR] chronyd no se pudo detener."
    exit 1
else
    echo "[OK] chronyd detenido correctamente."
fi

echo
echo "========================================"
echo "  Chrony listo para uso en Tx o Rx"
echo "========================================"
echo "Puedes continuar con los scripts específicos."
