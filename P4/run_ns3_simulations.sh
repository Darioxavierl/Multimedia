#!/bin/bash

# Script para ejecutar simulaciones de NS3 para todos los videos
# Recorre cada carpeta de configuración y ejecuta videoNodes con los parámetros correspondientes
# Uso: ./run_ns3_simulations.sh <directorio_videos> <distancia> [ns3_dir]

VIDEOS_DIR=$1
DISTANCE=$2
NS3_DIR=${3:-"$HOME/ns3/ns-allinone-3.45/ns-3.45"}

# Convertir ruta relativa a absoluta si es necesario
if [[ "$VIDEOS_DIR" != /* ]]; then
    VIDEOS_DIR="$(cd "$VIDEOS_DIR" 2>/dev/null && pwd)" || {
        echo "[-] Error: No se puede acceder al directorio '$VIDEOS_DIR'"
        exit 1
    }
fi

# Validar parámetros
if [ -z "$VIDEOS_DIR" ] || [ -z "$DISTANCE" ]; then
    echo "[-] Error: Se requieren parámetros obligatorios"
    echo "Uso: $0 <directorio_videos> <distancia> [ns3_dir]"
    echo ""
    echo "Ejemplo:"
    echo "  $0 /home/dariox/multimedia/P4/videos 30"
    echo "  $0 ./videos 30"
    echo "  $0 videos 80"
    exit 1
fi

# Validar que el directorio de videos existe
if [ ! -d "$VIDEOS_DIR" ]; then
    echo "[-] Error: Directorio '$VIDEOS_DIR' no existe"
    exit 1
fi

# Validar que NS3 existe
if [ ! -f "$NS3_DIR/ns3" ]; then
    echo "[-] Error: NS3 no encontrado en '$NS3_DIR/ns3'"
    exit 1
fi

# Obtener directorios de configuración
CONFIG_DIRS=$(find "$VIDEOS_DIR" -mindepth 1 -maxdepth 1 -type d | sort)

if [ -z "$CONFIG_DIRS" ]; then
    echo "[-] Error: No se encontraron directorios de configuración en $VIDEOS_DIR"
    exit 1
fi

echo "[+] Ejecutando simulaciones NS3"
echo "[+] Directorio de videos: $VIDEOS_DIR"
echo "[+] Distancia: $DISTANCE m"
echo "[+] NS3 directorio: $NS3_DIR"
echo ""

# Contador de simulaciones
TOTAL_CONFIGS=$(echo "$CONFIG_DIRS" | wc -l)
CURRENT=0

# Recorrer cada directorio de configuración
while IFS= read -r CONFIG_DIR; do
    CURRENT=$((CURRENT + 1))
    CONFIG_NAME=$(basename "$CONFIG_DIR")
    
    echo "[$CURRENT/$TOTAL_CONFIGS] =========================================="
    echo "Ejecutando simulación para: $CONFIG_NAME"
    echo "[*] Directorio: $CONFIG_DIR"
    
    # Buscar archivo .p (traza) en este directorio
    TRACE_FILE=$(find "$CONFIG_DIR" -maxdepth 1 -name "*_trace.f" -o -name "traza.f" | head -1)
    
    if [ -z "$TRACE_FILE" ]; then
        echo "[-] No se encontró archivo de traza (.p) en $CONFIG_DIR"
        continue
    fi
    
    TRACE_FILENAME=$(basename "$TRACE_FILE")
    TRACE_NAME="${TRACE_FILENAME%.p}"
    
    echo "[*] Traza encontrada: $TRACE_FILE"
    
    # Definir nombres de archivos de salida (dump)
    SD_DUMP="$CONFIG_DIR/${CONFIG_NAME}_sd_dump"
    RD_DUMP="$CONFIG_DIR/${CONFIG_NAME}_rd_dump"
    
    echo "[*] SD dump: $SD_DUMP"
    echo "[*] RD dump: $RD_DUMP"
    echo ""
    
    # Construir comando de NS3
    CMD="$NS3_DIR/ns3 run \"videoNodes --distance=$DISTANCE --propModel=LogDistance --senderTrace=$TRACE_FILE --senderDump=$SD_DUMP --receiverDump=$RD_DUMP\""
    
    echo "[*] Ejecutando comando NS3..."
    echo "[*] $CMD"
    echo ""
    
    # Ejecutar comando
    eval "$CMD"
    
    RESULT=$?
    
    if [ $RESULT -eq 0 ]; then
        echo ""
        echo "[+] Simulación completada exitosamente para $CONFIG_NAME"
        
        # Verificar que los archivos de salida fueron creados
        if [ -f "${SD_DUMP}" ] || [ -f "${SD_DUMP}.pcap" ]; then
            echo "[+] Archivo SD dump creado: $SD_DUMP"
        fi
        
        if [ -f "${RD_DUMP}" ] || [ -f "${RD_DUMP}.pcap" ]; then
            echo "[+] Archivo RD dump creado: $RD_DUMP"
        fi
    else
        echo "[-] Error en simulación para $CONFIG_NAME"
    fi
    
    echo ""
    
done <<< "$CONFIG_DIRS"

echo "[+] ¡Todas las simulaciones completadas!"
echo ""
echo "[*] Archivos de salida generados:"
find "$VIDEOS_DIR" -maxdepth 2 \( -name "*_sd_dump*" -o -name "*_rd_dump*" \) -type f | sort
