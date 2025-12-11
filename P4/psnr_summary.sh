#!/bin/bash

# Script para analizar y resumir los resultados PSNR

VIDEOS_DIR="${1:-$(pwd)/videos}"

# Convertir rutas relativas a absolutas
if [[ "$VIDEOS_DIR" != /* ]]; then
    VIDEOS_DIR="$(cd "$VIDEOS_DIR" 2>/dev/null && pwd)" || {
        echo "[-] Error: No se puede acceder a $VIDEOS_DIR"
        exit 1
    }
fi

if [ ! -d "$VIDEOS_DIR" ]; then
    echo "[-] Error: Directorio no existe: $VIDEOS_DIR"
    exit 1
fi

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║              RESUMEN DE RESULTADOS PSNR                       ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Array de configuraciones
configs=("100k" "200k" "22qp" "28qp")
config_names=("Bitrate: 100 kbps" "Bitrate: 200 kbps" "QP: 22 (Alta calidad)" "QP: 28 (Baja calidad)")

for i in "${!configs[@]}"; do
    config="${configs[$i]}"
    name="${config_names[$i]}"
    config_dir="$VIDEOS_DIR/$config"
    psnr_file="$config_dir/psnr_mobile_cif_${config}_rec.txt"
    
    if [ -f "$psnr_file" ]; then
        echo "[$i] $name"
        echo "    Archivo: videos/$config/psnr_mobile_cif_${config}_rec.txt"
        
        # Extraer la primera línea con estadísticas
        first_line=$(head -1 "$psnr_file")
        echo "    Resumen: $first_line"
        
        # Contar líneas de datos
        data_lines=$(grep -c "^0\." "$psnr_file" 2>/dev/null || echo 0)
        echo "    Frames analizados: $data_lines"
        
        # Calcular promedio, min, max
        avg=$(grep "^0\." "$psnr_file" 2>/dev/null | awk '{sum+=$1; count++} END {if(count>0) printf "%.6f", sum/count}')
        min=$(grep "^0\." "$psnr_file" 2>/dev/null | sort -n | head -1)
        max=$(grep "^0\." "$psnr_file" 2>/dev/null | sort -n | tail -1)
        
        echo "    PSNR Promedio: $avg dB"
        echo "    PSNR Mínimo: $min dB"
        echo "    PSNR Máximo: $max dB"
    else
        echo "[$i] $name"
        echo "    [-] Archivo PSNR no encontrado: $psnr_file"
    fi
    
    echo ""
done

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                    COMPARATIVA PSNR                           ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
printf "%-20s %-15s %-15s %-15s\n" "Configuración" "Promedio" "Mínimo" "Máximo"
printf "%-20s %-15s %-15s %-15s\n" "------" "--------" "-------" "-------"

for i in "${!configs[@]}"; do
    config="${configs[$i]}"
    config_dir="$VIDEOS_DIR/$config"
    psnr_file="$config_dir/psnr_mobile_cif_${config}_rec.txt"
    
    if [ -f "$psnr_file" ]; then
        avg=$(grep "^0\." "$psnr_file" 2>/dev/null | awk '{sum+=$1; count++} END {if(count>0) printf "%.6f", sum/count}')
        min=$(grep "^0\." "$psnr_file" 2>/dev/null | sort -n | head -1)
        max=$(grep "^0\." "$psnr_file" 2>/dev/null | sort -n | tail -1)
        
        printf "%-20s %-15s %-15s %-15s\n" "$config" "$avg" "$min" "$max"
    fi
done

echo ""
