#!/bin/bash

# Script para reconstruir videos usando rx_video.sh
# Recorre cada carpeta de configuración y reconstruye el video basándose en los dumps de NS3
# El video original es el .mp4 dentro de cada subdirectorio que se usó en la simulación
# Uso: ./reconstruct_videos.sh <directorio_videos> [tipo_traza]

VIDEOS_DIR=$1
TRACE_TYPE=${2:-f}

# Convertir ruta relativa a absoluta si es necesario
if [[ "$VIDEOS_DIR" != /* ]]; then
    VIDEOS_DIR="$(cd "$VIDEOS_DIR" 2>/dev/null && pwd)" || {
        echo "[-] Error: No se puede acceder al directorio '$VIDEOS_DIR'"
        exit 1
    }
fi

# Validar parámetros
if [ $# -lt 1 ]; then
    echo "[-] Error: Se requiere el directorio de videos"
    echo "Uso: $0 <directorio_videos> [tipo_traza]"
    echo ""
    echo "Ejemplo:"
    echo "  $0 /home/dariox/multimedia/P4/videos"
    echo "  $0 ./videos f"
    echo "  $0 videos"
    echo ""
    echo "Nota: El script buscará el .mp4 original dentro de cada carpeta de configuración"
    echo "      El tipo_traza puede ser 'f' (forward) o 'p' (packet), por defecto 'f'"
    exit 1
fi

# Validar que el directorio de videos existe
if [ ! -d "$VIDEOS_DIR" ]; then
    echo "[-] Error: Directorio '$VIDEOS_DIR' no existe"
    exit 1
fi

# Obtener el directorio raíz (padre del directorio de videos)
ROOT_DIR=$(dirname "$VIDEOS_DIR")

# Validar que rx_video.sh existe
RX_SCRIPT="$ROOT_DIR/rx_video.sh"
if [ ! -f "$RX_SCRIPT" ]; then
    echo "[-] Error: Script rx_video.sh no encontrado en $ROOT_DIR"
    exit 1
fi

echo "[+] Reconstruyendo videos para todas las configuraciones"
echo "[+] Directorio de videos: $VIDEOS_DIR"
echo "[+] Video original: Se buscará el .mp4 dentro de cada carpeta"
echo "[+] Tipo de traza: $TRACE_TYPE"
echo ""

# Obtener directorios de configuración
CONFIG_DIRS=$(find "$VIDEOS_DIR" -mindepth 1 -maxdepth 1 -type d | sort)

if [ -z "$CONFIG_DIRS" ]; then
    echo "[-] Error: No se encontraron directorios de configuración en $VIDEOS_DIR"
    exit 1
fi

# Contador de reconstrucciones
TOTAL_CONFIGS=$(echo "$CONFIG_DIRS" | wc -l)
CURRENT=0

# Recorrer cada directorio de configuración
while IFS= read -r CONFIG_DIR; do
    CURRENT=$((CURRENT + 1))
    CONFIG_NAME=$(basename "$CONFIG_DIR")
    
    echo "[$CURRENT/$TOTAL_CONFIGS] =========================================="
    echo "Reconstruyendo video para: $CONFIG_NAME"
    echo "[*] Directorio: $CONFIG_DIR"
    
    # Buscar los dumps en este directorio
    CONFIG_SD_DUMP=$(find "$CONFIG_DIR" -maxdepth 1 -name "*sd_dump" -type f | head -1)
    CONFIG_RD_DUMP=$(find "$CONFIG_DIR" -maxdepth 1 -name "*rd_dump" -type f | head -1)
    
    if [ -z "$CONFIG_SD_DUMP" ] || [ -z "$CONFIG_RD_DUMP" ]; then
        echo "[-] No se encontraron dumps (sd_dump o rd_dump) en $CONFIG_DIR"
        continue
    fi
    
    # Verificar que los dumps no estén vacíos
    SD_SIZE=$(stat -f%z "$CONFIG_SD_DUMP" 2>/dev/null || stat -c%s "$CONFIG_SD_DUMP" 2>/dev/null)
    RD_SIZE=$(stat -f%z "$CONFIG_RD_DUMP" 2>/dev/null || stat -c%s "$CONFIG_RD_DUMP" 2>/dev/null)
    
    if [ "$SD_SIZE" -eq 0 ] || [ "$RD_SIZE" -eq 0 ]; then
        echo "[-] Los dumps están vacíos (SD: $SD_SIZE bytes, RD: $RD_SIZE bytes)"
        echo "[-] Esto indica que la simulación NS3 no generó datos válidos"
        echo "[-] Saltando este directorio..."
        continue
    fi
    
    # Buscar la traza en este directorio
    CONFIG_TRACE=$(find "$CONFIG_DIR" -maxdepth 1 -name "*trace.f" -o -name "traza.f" | head -1)
    
    if [ -z "$CONFIG_TRACE" ]; then
        echo "[-] No se encontró archivo de traza en $CONFIG_DIR"
        continue
    fi
    
    # Buscar archivo .264 en este directorio para obtener el nombre base
    VIDEO_264=$(find "$CONFIG_DIR" -maxdepth 1 -name "*.264" -type f | head -1)
    
    if [ -z "$VIDEO_264" ]; then
        echo "[-] No se encontró archivo .264 en $CONFIG_DIR"
        continue
    fi
    
    # Obtener el nombre del video sin extensión
    VIDEO_BASE=$(basename "$VIDEO_264" .264)
    
    # Buscar el video original .mp4 en el mismo directorio
    VIDEO_ORIGINAL_MP4=$(find "$CONFIG_DIR" -maxdepth 1 -name "*.mp4" -type f | grep -v "_rec" | head -1)
    
    if [ -z "$VIDEO_ORIGINAL_MP4" ]; then
        echo "[-] No se encontró archivo .mp4 original en $CONFIG_DIR"
        continue
    fi
    
    VIDEO_ORIGINAL=$(basename "$VIDEO_ORIGINAL_MP4" .mp4)
    
    # Definir nombre de archivo reconstruido
    VIDEO_REC="${VIDEO_BASE}_rec"
    
    echo "[*] Video codificado: $VIDEO_BASE.264"
    echo "[*] Video original: $VIDEO_ORIGINAL.mp4"
    echo "[*] Video reconstruido será: $VIDEO_REC"
    echo "[*] SD dump: $(basename "$CONFIG_SD_DUMP")"
    echo "[*] RD dump: $(basename "$CONFIG_RD_DUMP")"
    echo "[*] Trace: $(basename "$CONFIG_TRACE")"
    echo ""
    
    echo "[*] Ejecutando rx_video.sh..."
    
    # Ejecutar reconstrucción (dentro del directorio de configuración)
    cd "$CONFIG_DIR" || exit 1
    
    # El script rx_video.sh espera: <tipo_traza> <archivo_tx> <archivo_rx> <archivo_trace> <video_original> <video_reconstruido>
    "$RX_SCRIPT" "$TRACE_TYPE" "$CONFIG_SD_DUMP" "$CONFIG_RD_DUMP" "$CONFIG_TRACE" "$VIDEO_ORIGINAL" "$VIDEO_REC"
    
    RESULT=$?
    
    if [ $RESULT -eq 0 ]; then
        echo ""
        echo "[+] Video reconstruido exitosamente para $CONFIG_NAME"
        
        # Verificar que los archivos de salida fueron creados
        if [ -f "${VIDEO_REC}.mp4" ]; then
            SIZE=$(du -h "${VIDEO_REC}.mp4" | cut -f1)
            echo "[+] Archivo de video reconstruido: ${VIDEO_REC}.mp4 ($SIZE)"
        fi
        
        # Listar archivos generados
        echo "[*] Archivos de análisis generados:"
        ls -lh loss_*.txt delay_*.txt rate_*.txt 2>/dev/null | awk '{print "    " $9 " (" $5 ")"}'
    else
        echo "[-] Error en reconstrucción para $CONFIG_NAME"
    fi
    
    echo ""
    cd - > /dev/null || exit 1
    
done <<< "$CONFIG_DIRS"

echo "[+] ¡Reconstrucción de todos los videos completada!"
echo ""
echo "[*] Videos reconstruidos:"
find "$VIDEOS_DIR" -maxdepth 2 -name "*_rec.mp4" -type f | sort

echo ""
echo "[*] Resumen de archivos de análisis generados:"
find "$VIDEOS_DIR" -maxdepth 2 \( -name "loss_*.txt" -o -name "delay_*.txt" -o -name "rate_*.txt" \) -type f | wc -l | xargs echo "Total de archivos de análisis:"
