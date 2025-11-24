#!/bin/bash
#
# Script para captura de tráfico en pruebas de videoconferencia P2P
# Mide: Throughput, Delay (de análisis posterior)
#
# Uso:
#   ./capture_experiment.sh <INTERFAZ> <PUERTO> <DURACION_SEG>
#
# Ejemplo:
#   ./capture_experiment.sh eth0 5000 120
#

### ================================
### VALIDACIÓN DE PARÁMETROS
### ================================
if [ $# -ne 3 ]; then
    echo "Uso: $0 <INTERFAZ> <PUERTO> <DURACION_SEG>"
    exit 1
fi

IFACE=$1
PORT=$2
DURATION=$3

### ================================
### PREPARAR DIRECTORIOS
### ================================
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
OUTDIR="capturas/capture_${TIMESTAMP}"

mkdir -p "$OUTDIR"

PCAP_FILE="$OUTDIR/capture_${PORT}.pcap"
LOG_FILE="$OUTDIR/capture_info.txt"

### ================================
### INFORMACIÓN DE LA CAPTURA
### ================================
echo "===================================" | tee "$LOG_FILE"
echo "     EXPERIMENTO DE CAPTURA"       | tee -a "$LOG_FILE"
echo "===================================" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

echo "Interfaz:   $IFACE" | tee -a "$LOG_FILE"
echo "Puerto UDP: $PORT" | tee -a "$LOG_FILE"
echo "Duración:   $DURATION seg" | tee -a "$LOG_FILE"
echo "Output:     $PCAP_FILE" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

sleep 1

### ================================
### INICIAR CAPTURA
### ================================
echo "Iniciando captura durante $DURATION segundos..."
echo "Presiona Ctrl+C para detener antes."

sudo timeout "$DURATION" tcpdump -i "$IFACE" udp port "$PORT" -w "$PCAP_FILE"

CAPTURE_EXIT=$?

if [ $CAPTURE_EXIT -eq 124 ]; then
    echo "" | tee -a "$LOG_FILE"
    echo ">>> Captura finalizada automáticamente tras ${DURATION}s." | tee -a "$LOG_FILE"
else
    echo "" | tee -a "$LOG_FILE"
    echo ">>> Captura detenida manualmente." | tee -a "$LOG_FILE"
fi

### ================================
### RESUMEN DE LA CAPTURA
### ================================
echo "" | tee -a "$LOG_FILE"
echo "===================================" | tee -a "$LOG_FILE"
echo "   RESUMEN DE LA CAPTURA (tcpdump)"
echo "===================================" | tee -a "$LOG_FILE"

tcpdump -nn -r "$PCAP_FILE" 2>/dev/null | head -n 20 | tee -a "$LOG_FILE"

echo "" | tee -a "$LOG_FILE"
echo "Archivo pcap listo: $PCAP_FILE" | tee -a "$LOG_FILE"
echo "Directorio:         $OUTDIR"
echo "" | tee -a "$LOG_FILE"

echo "Ahora puedes realizar el análisis con Python, Wireshark o scripts personalizados."
