#!/bin/bash

NS3_CMD="./ns3 run"
SIM_SCRIPT="ad-hoc"
PACKETS=2000
INTERVAL=1
PROP_MODEL="LogDistance"

START=1
MAX_DIST=500   # límite por seguridad
LAST_GOOD_DIST=0

echo "========================================"
echo " Buscando máxima distancia con recepción "
echo "========================================"

DIST=$START
while [ $DIST -le $MAX_DIST ]; do
    echo -n "Distancia ${DIST}m → "

    # Ejecutar simulación y filtrar solo las líneas de recepción
    RECEIVED=$($NS3_CMD "$SIM_SCRIPT --distance=$DIST --numPackets=$PACKETS --interval=$INTERVAL --propModel=$PROP_MODEL" 2>&1 \
        | grep -c "Received packet number")

    # Si no recibió nada, terminamos
    if [ "$RECEIVED" -eq 0 ]; then
        echo "[+] 0 paquetes → FIN"
        break
    fi

    echo "✔ $RECEIVED paquetes"
    LAST_GOOD_DIST=$DIST

    DIST=$((DIST + 1))
done

echo "========================================"
if [ $LAST_GOOD_DIST -eq 0 ]; then
    echo " No se recibió nada ni siquiera a 1 metro."
else
    echo "Máxima distancia con recepción exitosa: ${LAST_GOOD_DIST}m"
fi
echo "========================================"

