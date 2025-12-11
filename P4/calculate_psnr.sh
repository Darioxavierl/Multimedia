#!/bin/bash

# Script para calcular PSNR de todos los videos reconstruidos
# Ejecuta psnr_video.sh para cada configuración
# Los nombres de configuración se extraen dinámicamente de los directorios
# Uso: ./calculate_psnr.sh [videos_dir]

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VIDEOS_DIR="${1:-$SCRIPT_DIR/videos}"
PSNR_SCRIPT="$SCRIPT_DIR/psnr_video.sh"

# Convertir rutas relativas a absolutas
if [[ "$VIDEOS_DIR" != /* ]]; then
    VIDEOS_DIR="$(cd "$VIDEOS_DIR" 2>/dev/null && pwd)" || {
        echo "[-] Error: No se puede acceder a $VIDEOS_DIR"
        exit 1
    }
fi

# Validar directorios
if [ ! -d "$VIDEOS_DIR" ]; then
    echo "[-] Error: Directorio de videos no existe: $VIDEOS_DIR"
    exit 1
fi

if [ ! -f "$PSNR_SCRIPT" ]; then
    echo "[-] Error: Script psnr_video.sh no encontrado: $PSNR_SCRIPT"
    exit 1
fi

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║      CÁLCULO DE PSNR - VIDEOS RECONSTRUIDOS EN CARPETAS       ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Obtener dinámicamente los directorios de configuración usando array
mapfile -t CONFIG_DIRS < <(find "$VIDEOS_DIR" -mindepth 1 -maxdepth 1 -type d | sort)

if [ ${#CONFIG_DIRS[@]} -eq 0 ]; then
    echo "[-] Error: No se encontraron directorios en $VIDEOS_DIR"
    exit 1
fi

# Contar total de configuraciones
TOTAL=${#CONFIG_DIRS[@]}

# Contadores
total=0
success=0
failed=0

echo "[+] Directorio de videos: $VIDEOS_DIR"
echo "[+] Script PSNR: $PSNR_SCRIPT"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "PROCESANDO CÁLCULOS DE PSNR"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

CURRENT=0

for config_dir in "${CONFIG_DIRS[@]}"; do
    CURRENT=$((CURRENT + 1))
    config=$(basename "$config_dir")
    
    echo "[$CURRENT/$TOTAL] Procesando: $config"
    
    # Validar que el directorio existe
    if [ ! -d "$config_dir" ]; then
        echo "  [-] Error: Directorio no encontrado: $config_dir"
        failed=$((failed + 1))
        total=$((total + 1))
        continue
    fi
    
    # Buscar dinámicamente los archivos MP4 en el directorio
    # Buscar archivo original (sin _rec)
    orig_mp4=$(find "$config_dir" -maxdepth 1 -name "mobile_cif_*.mp4" -type f | grep -v "_rec" | head -1)
    rec_mp4=$(find "$config_dir" -maxdepth 1 -name "mobile_cif_*_rec.mp4" -type f | head -1)
    
    if [ -z "$orig_mp4" ] || [ -z "$rec_mp4" ]; then
        echo "  [-] Error: No se encontraron archivos MP4 en $config_dir"
        echo "      Original: $orig_mp4"
        echo "      Reconstruido: $rec_mp4"
        failed=$((failed + 1))
        total=$((total + 1))
        continue
    fi
    
    # Extraer nombres sin extensión
    orig_video=$(basename "$orig_mp4" .mp4)
    rec_video=$(basename "$rec_mp4" .mp4)
    
    echo "  [*] Directorio: $config_dir"
    echo "  [*] Original:     $(basename $orig_mp4)"
    echo "  [*] Reconstruido: $(basename $rec_mp4)"
    echo "  [*] Ejecutando psnr_video.sh..."
    echo ""
    
    # Ejecutar psnr_video.sh
    # Parámetros: directorio de trabajo, video reconstruido (sin extensión), video original (sin extensión)
    if "$PSNR_SCRIPT" "$config_dir" "$rec_video" "$orig_video" 2>&1; then
        
        # Verificar que se generó el archivo PSNR
        psnr_file="$config_dir/psnr_${rec_video}.txt"
        if [ -f "$psnr_file" ]; then
            lines=$(wc -l < "$psnr_file")
            echo ""
            echo "  [+] ✓ PSNR calculado exitosamente"
            echo "      Archivo: psnr_${rec_video}.txt ($lines líneas)"
            echo ""
            success=$((success + 1))
        else
            echo ""
            echo "  [-] Error: No se generó el archivo PSNR"
            echo ""
            failed=$((failed + 1))
        fi
    else
        echo ""
        echo "  [-] Error: psnr_video.sh falló"
        echo ""
        failed=$((failed + 1))
    fi
    
    total=$((total + 1))
    
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "RESUMEN"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Total procesados: $total"
echo "Exitosos:        $success"
echo "Fallidos:        $failed"
echo ""

if [ $success -gt 0 ]; then
    echo "✓ Archivos PSNR generados:"
    while IFS= read -r config_dir; do
        config=$(basename "$config_dir")
        psnr_file="$config_dir/psnr_mobile_cif_${config}_rec.txt"
        if [ -f "$psnr_file" ]; then
            lines=$(wc -l < "$psnr_file")
            echo "  ✓ $config/psnr_mobile_cif_${config}_rec.txt ($lines líneas)"
        fi
    done <<< "$CONFIG_DIRS"
fi

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
if [ $failed -eq 0 ] && [ $success -gt 0 ]; then
    echo "║         TODOS LOS CÁLCULOS COMPLETADOS EXITOSAMENTE      ║"
else
    echo "║          CÁLCULO COMPLETADO CON ALGUNOS ERRORES         ║"
fi
echo "╚════════════════════════════════════════════════════════════════╝"
