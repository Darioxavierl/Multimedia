#!/bin/bash

# Cargar variables de entorno
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
else
    echo "Error: archivo .env no encontrado"
    exit 1
fi

# Validar que se pasó la ruta de input
if [ -z "$1" ]; then
    echo "Uso: $0 <ruta_videos>"
    exit 1
fi

INPUT_DIR="$1"

# Validar que el directorio existe
if [ ! -d "$INPUT_DIR" ]; then
    echo "Error: El directorio $INPUT_DIR no existe"
    exit 1
fi

# Crear directorio de salida
OUTPUT_DIR="vp8/QP"
mkdir -p "$OUTPUT_DIR"

# Crear directorio para logs de CPU
LOGS_DIR="cpu_logs/VP8/QP"
mkdir -p "$LOGS_DIR"

echo "==================================="
echo "Codificación VP8"
echo "QP: $QP"
echo "Input: $INPUT_DIR"
echo "Output: $OUTPUT_DIR"
echo "==================================="

# Función para monitorear CPU y memoria
monitor_cpu() {
    local pid=$1
    local csv_file=$2
    
    # Escribir header del CSV
    echo "timestamp,cpu_percent,memory_mb,memory_percent" > "$csv_file"
    
    # Monitorear mientras el proceso existe
    while kill -0 $pid 2>/dev/null; do
        timestamp=$(date +"%Y-%m-%d %H:%M:%S.%3N")
        
        # Obtener uso de CPU y memoria usando ps
        stats=$(ps -p $pid -o %cpu,%mem,rss --no-headers 2>/dev/null)
        
        if [ -n "$stats" ]; then
            cpu=$(echo $stats | awk '{print $1}')
            mem_percent=$(echo $stats | awk '{print $2}')
            mem_kb=$(echo $stats | awk '{print $3}')
            mem_mb=$(echo "scale=2; $mem_kb / 1024" | bc)
            
            echo "$timestamp,$cpu,$mem_mb,$mem_percent" >> "$csv_file"
        fi
        
        # Esperar 10ms
        sleep 0.01
    done
}

# Procesar cada video en el directorio
for video in "$INPUT_DIR"/*.{mp4,avi,mkv,mov,yuv,264,h264}; do
    # Verificar si el archivo existe (evitar error si no hay coincidencias)
    [ -e "$video" ] || continue
    
    # Obtener nombre del archivo sin extensión
    filename=$(basename "$video")
    name="${filename%.*}"
    
    # Archivo de salida
    output_file="$OUTPUT_DIR/${name}_QP.webm"
    
    # Archivo CSV para logs de CPU
    csv_file="$LOGS_DIR/${name}_QP_cpu.csv"
    
    echo ""
    echo "Procesando: $filename"
    echo "Salida: $output_file"
    echo "Log CPU: $csv_file"
    
    # Iniciar ffmpeg en background y obtener su PID
    # Para archivos YUV, necesitamos especificar formato y resolución
    if [[ "$filename" == *.yuv ]]; then
        # Intentar detectar resolución del nombre (ej: file_cif.yuv, file_1920x1080.yuv)
        if [[ "$filename" =~ cif ]]; then
            resolution="352x288"
        elif [[ "$filename" =~ qcif ]]; then
            resolution="176x144"
        elif [[ "$filename" =~ ([0-9]+)x([0-9]+) ]]; then
            resolution="${BASH_REMATCH[1]}x${BASH_REMATCH[2]}"
        else
            # Resolución por defecto
            resolution="352x288"
            echo "Advertencia: No se detectó resolución, usando $resolution"
        fi
        
        ffmpeg -f rawvideo -pixel_format yuv420p -video_size $resolution -framerate 24 \
               -i "$video" -c:v libvpx -crf $QP -b:v 0 -y "$output_file" &
    else
        ffmpeg -i "$video" -c:v libvpx -crf $QP -b:v 0 -c:a libvorbis -y "$output_file" &
    fi
    
    ffmpeg_pid=$!
    
    # Iniciar monitoreo de CPU en background
    monitor_cpu $ffmpeg_pid "$csv_file" &
    monitor_pid=$!
    
    # Esperar a que ffmpeg termine
    wait $ffmpeg_pid
    ffmpeg_status=$?
    
    # Esperar a que el monitoreo termine
    wait $monitor_pid
    
    if [ $ffmpeg_status -eq 0 ]; then
        echo "[+] Codificación completada exitosamente"
    else
        echo "[+] Error en la codificación (código: $ffmpeg_status)"
    fi
done

echo ""
echo "==================================="
echo "Proceso completado"
echo "Videos codificados en: $OUTPUT_DIR"
echo "Logs de CPU en: $LOGS_DIR"
echo "==================================="
