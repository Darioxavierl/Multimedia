#!/bin/bash

# ======================================================
#   EJECUTAR TU SCRIPT DE SIMULACIÓN 10 VECES
# ======================================================

SIM_SCRIPT="./run_sims4.sh"   
REPEAT=10

echo "Ejecutando el script $SIM_SCRIPT un total de $REPEAT veces..."
echo "=============================================================="

for i in $(seq 1 $REPEAT); do
    echo ""
    echo "========================="
    echo "  EJECUCIÓN Nº $i"
    echo "========================="
    bash "$SIM_SCRIPT"

  
done

echo ""
echo "============================================"
echo "¡Listo! Se ejecutó el script 10 veces."
echo "============================================"

