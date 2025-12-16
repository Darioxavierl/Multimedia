#!/bin/bash

# Script para generar trazas de todos los videos en el directorio
# Recorre cada carpeta de configuración y genera trazas usando mp4trace
# Lee TRACE_MODE desde .env (ejemplo: -f para frame traces)
# Uso: ./generate_traces.sh <directorio_videos> [archivo_env]

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VIDEOS_DIR="${1:-$SCRIPT_DIR/videos}"
ENV_FILE="${2:-.env}"

# Si ENV_FILE es relativo, hacerlo relativo a SCRIPT_DIR
if [[ "$ENV_FILE" != /* ]]; then
    ENV_FILE="$SCRIPT_DIR/$ENV_FILE"
fi

# Convertir VIDEOS_DIR a absoluta si es necesario
if [[ "$VIDEOS_DIR" != /* ]]; then
    if [ "$VIDEOS_DIR" = "." ]; then
        VIDEOS_DIR="$SCRIPT_DIR/videos"
    elif [ "$VIDEOS_DIR" = "./videos" ]; then
        VIDEOS_DIR="$SCRIPT_DIR/videos"
    else
        VIDEOS_DIR="$SCRIPT_DIR/$VIDEOS_DIR"
    fi
fi

# Validar que el directorio de videos existe
if [ ! -d "$VIDEOS_DIR" ]; then
    echo "[-] Error: Directorio de videos no existe: $VIDEOS_DIR"
    exit 1
fi

# Validar que el archivo .env existe
if [ ! -f "$ENV_FILE" ]; then
    echo "[-] Error: Archivo .env no encontrado: $ENV_FILE"
    exit 1
fi

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║           GENERACIÓN DE TRAZAS - mp4trace                     ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "[+] Directorio de videos: $VIDEOS_DIR"
echo "[+] Archivo de configuración: $ENV_FILE"
echo ""

# Leer variables del .env
source "$ENV_FILE"

echo "[+] Configuración:"
echo "    - TRACE_MODE: $TRACE_MODE"
echo "    - DEST_IP: $DEST_IP"
echo "    - UDP_PORT: $UDP_PORT"
echo ""

# Validar que TRACE_MODE está definido
if [ -z "$TRACE_MODE" ]; then
    echo "[-] Error: TRACE_MODE no está definido en $ENV_FILE"
    exit 1
fi

# Obtener directorios de configuración (100k, 200k, 22qp, 28qp)
CONFIG_DIRS=$(find "$VIDEOS_DIR" -mindepth 1 -maxdepth 1 -type d | sort)

if [ -z "$CONFIG_DIRS" ]; then
    echo "[-] Error: No se encontraron directorios de configuración en $VIDEOS_DIR"
    exit 1
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "GENERANDO TRAZAS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Contador de trazas generadas
TOTAL_CONFIGS=$(echo "$CONFIG_DIRS" | wc -l)
CURRENT=0
SUCCESS=0
FAILED=0

# Recorrer cada directorio de configuración
while IFS= read -r CONFIG_DIR; do
    CURRENT=$((CURRENT + 1))
    CONFIG_NAME=$(basename "$CONFIG_DIR")
    
    echo "[$CURRENT/$TOTAL_CONFIGS] Procesando: $CONFIG_NAME"
    echo "[*] Directorio: $CONFIG_DIR"
    
    # Buscar archivo .mp4 en este directorio (video codificado)
    MP4_FILE=$(find "$CONFIG_DIR" -maxdepth 1 -name "mobile_cif_*.mp4" -type f | grep -v "_rec" | head -1)
    
    if [ -z "$MP4_FILE" ]; then
        echo "[-] No se encontró archivo .mp4 en $CONFIG_DIR"
        FAILED=$((FAILED + 1))
        echo ""
        continue
    fi
    
    VIDEO_FILENAME=$(basename "$MP4_FILE")
    echo "[*] Video: $VIDEO_FILENAME"
    
    # Definir nombre del archivo de salida de traza
    # Extrae el nombre base y añade _trace.f (o .p según TRACE_MODE)
    TRACE_EXT="${TRACE_MODE#-}"  # Extrae la letra después de "-"
    OUTPUT_NAME="${VIDEO_FILENAME%.mp4}_trace"
    OUTPUT_FILE="$CONFIG_DIR/${OUTPUT_NAME}.${TRACE_EXT}"
    
    echo "[*] Archivo de salida: ${OUTPUT_NAME}.${TRACE_EXT}"
    
    # Validar que evalvid existe
    EVALVID_DIR="$HOME/evalvid"
    if [ ! -f "$EVALVID_DIR/mp4trace" ]; then
        echo "[-] Error: $EVALVID_DIR/mp4trace no encontrado"
        FAILED=$((FAILED + 1))
        echo ""
        continue
    fi
    
    # Iniciar listener NC en segundo plano
    echo "[*] Iniciando listener NC en puerto $UDP_PORT..."
    (nc -4 -l -u -d "$UDP_PORT" > /dev/null 2>&1) &
    NC_PID=$!
    
    # Dar tiempo a nc para que se inicie
    sleep 1
    
    # Ejecutar mp4trace para generar la traza
    echo "[*] Ejecutando mp4trace..."
    CMD="$EVALVID_DIR/mp4trace $TRACE_MODE -s $DEST_IP $UDP_PORT $MP4_FILE"
    echo "[*] Comando: $CMD"
    
    $CMD > "$OUTPUT_FILE" 2>&1
    TRACE_RESULT=$?
    
    # Esperar a que nc termine
    sleep 1
    kill $NC_PID 2>/dev/null
    wait $NC_PID 2>/dev/null
    
    # Verificar resultado
    if [ $TRACE_RESULT -eq 0 ] && [ -f "$OUTPUT_FILE" ]; then
        FILE_SIZE=$(ls -lh "$OUTPUT_FILE" | awk '{print $5}')
        echo "[+] ✓ Traza generada: ${OUTPUT_NAME}.${TRACE_EXT} ($FILE_SIZE)"
        SUCCESS=$((SUCCESS + 1))
    else
        echo "[-] Error al generar traza para $CONFIG_NAME"
        FAILED=$((FAILED + 1))
    fi
    
    # Delay de 2 segundos antes de la siguiente traza
    if [ $CURRENT -lt $TOTAL_CONFIGS ]; then
        echo "[*] Aguardando 2 segundos antes de la siguiente traza..."
        sleep 2
    fi
    
    echo ""
    
done <<< "$CONFIG_DIRS"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "RESUMEN"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Total procesados: $TOTAL_CONFIGS"
echo "Exitosos:        $SUCCESS"
echo "Fallidos:        $FAILED"
echo ""

if [ $SUCCESS -gt 0 ]; then
    echo "[+] Trazas generadas:"
    find "$VIDEOS_DIR" -name "*_trace.*" -type f | sort | while read file; do
        size=$(ls -lh "$file" | awk '{print $5}')
        echo "    ✓ $(basename "$file") ($size)"
    done
fi

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
if [ $FAILED -eq 0 ] && [ $SUCCESS -gt 0 ]; then
    echo "║          GENERACIÓN DE TRAZAS COMPLETADA EXITOSAMENTE      ║"
else
    echo "║             GENERACIÓN CON ALGUNOS ERRORES                ║"
fi
echo "╚════════════════════════════════════════════════════════════════╝"
