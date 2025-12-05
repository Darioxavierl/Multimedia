#!/bin/bash
# ==============================
# CONFIGURACIÓN
# ==============================
OUTPUT_DIR_BASE="$HOME/multimedia/ns3"
NS3_CMD="./ns3 run"
SIM_SCRIPT="ad-hoc"
PACKETS=2000
INTERVAL=1
PROP_MODEL="LogDistance"

# ==============================
# FECHA PARA SUBCARPETA
# ==============================
TODAY=$(date +%Y-%m-%d-%H-%M-%S)
OUTPUT_DIR="${OUTPUT_DIR_BASE}/${TODAY}"
mkdir -p "$OUTPUT_DIR"

echo "Guardando resultados en: $OUTPUT_DIR"
echo "========================================"

# ==============================
# BUCLE DE DISTANCIAS
# ==============================
START=1
END=130
STEP=2

for DIST in $(seq $START $STEP $END); do
    echo "Ejecutando simulación para distancia = ${DIST}m"
    
    # Archivo temporal para esta distancia
    TEMP_FILE="${OUTPUT_DIR}/temp_${DIST}.txt"
    CSV_FILE="${OUTPUT_DIR}/${DIST}.csv"
    
    # Ejecutar simulación y filtrar directamente a archivo temporal
    $NS3_CMD "$SIM_SCRIPT --distance=$DIST --numPackets=$PACKETS --interval=$INTERVAL --propModel=$PROP_MODEL" 2>&1 | \
        grep -E "Received packet number" > "$TEMP_FILE"
    
    # Verificar si hay datos
    if [ ! -s "$TEMP_FILE" ]; then
        echo "⚠ No se recibieron paquetes a ${DIST}m"
        rm -f "$TEMP_FILE"
        continue
    fi
    
    # Escribir encabezado del CSV
    echo "packet,source_ip,port,time" > "$CSV_FILE"
    
    # Procesar archivo temporal con sed 
    sed -E 's/.*packet number->([0-9]+).*from:([0-9.]+).*port:[[:space:]]*([0-9]+).*time *= *([0-9.]+).*/\1,\2,\3,\4/' \
        "$TEMP_FILE" >> "$CSV_FILE"
    
    # Limpiar archivo temporal
    rm -f "$TEMP_FILE"
    
    # Contar paquetes recibidos
    PACKET_COUNT=$(($(wc -l < "$CSV_FILE") - 1))
    echo " Guardado: ${CSV_FILE} (${PACKET_COUNT}/${PACKETS} paquetes recibidos)"
done

echo "========================================"
echo "Simulaciones completas."
echo "Archivos CSV en: $OUTPUT_DIR"
