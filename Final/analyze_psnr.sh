#!/bin/bash

# Directorios
RECUPERACION_DIR="recuperacion"
PSNR_DIR="PSNR"
VIDEOS_ORIGINALES="videos"

echo "==================================="
echo "Recuperación de YUV y Cálculo PSNR"
echo "==================================="

# Crear directorios base
mkdir -p "$RECUPERACION_DIR"
mkdir -p "$PSNR_DIR"

# Función para obtener resolución del video
get_resolution() {
    local video=$1
    ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=s=x:p=0 "$video"
}

# Función para procesar videos y recuperar YUV
recuperar_yuv() {
    local codec_dir=$1  # h264 o vp8
    local mode_dir=$2   # BR o QP
    local input_path="$codec_dir/$mode_dir"
    
    # Verificar si existe el directorio
    if [ ! -d "$input_path" ]; then
        echo "Directorio $input_path no existe, saltando..."
        return
    fi
    
    # Crear directorios de salida
    local output_path="$RECUPERACION_DIR/$codec_dir/$mode_dir"
    local psnr_path="$PSNR_DIR/$codec_dir/$mode_dir"
    mkdir -p "$output_path"
    mkdir -p "$psnr_path"
    
    echo ""
    echo "Procesando: $input_path"
    echo "----------------------------------------"
    
    # Buscar todos los videos en el directorio
    for video in "$input_path"/*.*; do
        # Verificar si el archivo existe
        [ -e "$video" ] || continue
        
        filename=$(basename "$video")
        name="${filename%.*}"
        
        # Archivo YUV recuperado
        yuv_output="$output_path/${name}.yuv"
        
        echo ""
        echo "[1/2] Recuperando YUV: $filename"
        
        # Obtener resolución del video codificado
        resolution=$(get_resolution "$video")
        echo "    Resolución detectada: $resolution"
        
        # Convertir video codificado a YUV
        ffmpeg -i "$video" -f rawvideo -pix_fmt yuv420p -y "$yuv_output" -v quiet
        
        if [ $? -eq 0 ]; then
            echo "    [+] YUV recuperado: $yuv_output"
        else
            echo "    [+] Error al recuperar YUV"
            continue
        fi
        
        # Ahora calcular PSNR con el video original
        # Extraer el nombre base del video original (quitar sufijos _BR, _QP, _VP8, etc)
        original_name=$(echo "$name" | sed -e 's/_BR$//' -e 's/_QP$//' -e 's/_VP8_BR$//' -e 's/_VP8_QP$//')
        
        # Buscar el video original en videos/
        original_video=""
        for ext in yuv mp4 avi mkv mov; do
            if [ -f "$VIDEOS_ORIGINALES/${original_name}.$ext" ]; then
                original_video="$VIDEOS_ORIGINALES/${original_name}.$ext"
                break
            fi
        done
        
        if [ -z "$original_video" ]; then
            echo "    [+] Video original no encontrado: ${original_name}"
            continue
        fi
        
        echo "[2/2] Calculando PSNR con original: $(basename $original_video)"
        
        # Si el original es YUV, usarlo directamente
        # Si no, convertirlo primero a YUV temporalmente
        if [[ "$original_video" == *.yuv ]]; then
            original_yuv="$original_video"
            # Para YUV necesitamos especificar resolución
            width=$(echo $resolution | cut -d'x' -f1)
            height=$(echo $resolution | cut -d'x' -f2)
            
            # CSV de salida para PSNR
            psnr_csv="$psnr_path/${name}_psnr.csv"
            
            # Calcular PSNR frame por frame
            ffmpeg -f rawvideo -pix_fmt yuv420p -s $resolution -i "$original_yuv" \
                   -f rawvideo -pix_fmt yuv420p -s $resolution -i "$yuv_output" \
                   -lavfi psnr="stats_file=$psnr_csv" -f null - -v quiet 2>&1
        else
            # Convertir original a YUV temporal
            temp_original="/tmp/${original_name}_temp.yuv"
            ffmpeg -i "$original_video" -f rawvideo -pix_fmt yuv420p -y "$temp_original" -v quiet
            
            # CSV de salida para PSNR
            psnr_csv="$psnr_path/${name}_psnr.csv"
            
            # Calcular PSNR
            ffmpeg -f rawvideo -pix_fmt yuv420p -s $resolution -i "$temp_original" \
                   -f rawvideo -pix_fmt yuv420p -s $resolution -i "$yuv_output" \
                   -lavfi psnr="stats_file=$psnr_csv" -f null - -v quiet 2>&1
            
            # Eliminar temporal
            rm -f "$temp_original"
        fi
        
        if [ $? -eq 0 ] && [ -f "$psnr_csv" ]; then
            echo "    [+] PSNR calculado: $psnr_csv"
        else
            echo "    [+] Error al calcular PSNR"
        fi
    done
}

# Procesar todas las combinaciones
echo ""
echo "=== Procesando H264 ==="
recuperar_yuv "h264" "BR"
recuperar_yuv "h264" "QP"

echo ""
echo "=== Procesando VP8 ==="
recuperar_yuv "vp8" "BR"
recuperar_yuv "vp8" "QP"

echo ""
echo "==================================="
echo "Proceso completado"
echo "YUV recuperados en: $RECUPERACION_DIR"
echo "Datos PSNR en: $PSNR_DIR"
echo "==================================="
