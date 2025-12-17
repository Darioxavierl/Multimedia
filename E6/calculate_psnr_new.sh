#!/bin/bash

# Script para calcular PSNR entre videos originales (Tx) y reconstruidos
# Estructura: 
#   Tx/videos/subcarpeta/*.mp4 (originales)
#   <RECON_DIR>/videos/subcarpeta/*.mp4 (reconstruidos)
# Uso: ./calculate_psnr_new.sh [directorio_reconstruidos]
# Ejemplo: ./calculate_psnr_new.sh 40m

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RECON_DIR="${1:-.}"
PSNR_SCRIPT="$SCRIPT_DIR/psnr_video.sh"

# Convertir rutas relativas a absolutas
if [[ "$RECON_DIR" != /* ]]; then
    RECON_DIR="$SCRIPT_DIR/$RECON_DIR"
fi

# Validar directorios
if [ ! -d "$SCRIPT_DIR/Tx/videos" ]; then
    echo "[-] Error: Directorio de videos originales no existe: $SCRIPT_DIR/Tx/videos"
    exit 1
fi

if [ ! -d "$RECON_DIR/videos" ]; then
    echo "[-] Error: Directorio de videos reconstruidos no existe: $RECON_DIR/videos"
    exit 1
fi

if [ ! -f "$PSNR_SCRIPT" ]; then
    echo "[-] Error: Script psnr_video.sh no encontrado: $PSNR_SCRIPT"
    exit 1
fi

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║      CÁLCULO DE PSNR - ORIGINAL vs RECONSTRUIDO               ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "[+] Directorio original:     $SCRIPT_DIR/Tx/videos"
echo "[+] Directorio reconstruido: $RECON_DIR/videos"
echo "[+] Script PSNR:             $PSNR_SCRIPT"
echo ""

# Obtener subdirectorios de configuración del directorio original
mapfile -t CONFIG_DIRS < <(find "$SCRIPT_DIR/Tx/videos" -mindepth 1 -maxdepth 1 -type d | sort)

if [ ${#CONFIG_DIRS[@]} -eq 0 ]; then
    echo "[-] Error: No se encontraron subdirectorios en $SCRIPT_DIR/Tx/videos"
    exit 1
fi

# Contadores
total=0
success=0
failed=0

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "PROCESANDO CÁLCULOS DE PSNR"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

CURRENT=0

for tx_dir in "${CONFIG_DIRS[@]}"; do
    CURRENT=$((CURRENT + 1))
    config=$(basename "$tx_dir")
    
    echo "[$CURRENT/${#CONFIG_DIRS[@]}] Procesando: $config"
    
    # Construir ruta del directorio reconstruido
    recon_dir="$RECON_DIR/videos/$config"
    
    # Validar que el directorio reconstruido existe
    if [ ! -d "$recon_dir" ]; then
        echo "  [-] Error: Directorio reconstruido no encontrado: $recon_dir"
        failed=$((failed + 1))
        total=$((total + 1))
        continue
    fi
    
    # Buscar video original (sin sufijo _rec)
    orig_mp4=$(find "$tx_dir" -maxdepth 1 -name "*.mp4" -type f | grep -v "_rec" | head -1)
    
    # Buscar video reconstruido (_rec)
    rec_mp4=$(find "$recon_dir" -maxdepth 1 -name "*_rec.mp4" -type f | head -1)
    
    if [ -z "$orig_mp4" ]; then
        echo "  [-] Error: No se encontró video original en $tx_dir"
        failed=$((failed + 1))
        total=$((total + 1))
        continue
    fi
    
    if [ -z "$rec_mp4" ]; then
        echo "  [-] Error: No se encontró video reconstruido en $recon_dir"
        failed=$((failed + 1))
        total=$((total + 1))
        continue
    fi
    
    # Extraer nombres sin extensión
    orig_name=$(basename "$orig_mp4" .mp4)
    rec_name=$(basename "$rec_mp4" .mp4)
    
    echo "  [*] Original:     $orig_name.mp4"
    echo "  [*] Reconstruido: $rec_name.mp4"
    echo "  [*] Directorio trabajo: $recon_dir"
    echo "  [*] Ejecutando psnr_video.sh..."
    echo ""
    
    # Crear directorio de trabajo temporal si no existe
    mkdir -p "$recon_dir/psnr_work" 2>/dev/null
    
    # Copiar video original al directorio de trabajo (si no está)
    if [ ! -f "$recon_dir/$orig_name.mp4" ]; then
        echo "  [*] Copiando video original..."
        cp "$orig_mp4" "$recon_dir/$orig_name.mp4" 2>/dev/null || {
            echo "  [-] Error: No se pudo copiar video original"
            failed=$((failed + 1))
            total=$((total + 1))
            continue
        }
    fi
    
    # Ejecutar psnr_video.sh
    # Parámetros: directorio de trabajo, nombre_video_reconstruido, nombre_video_original
    if "$PSNR_SCRIPT" "$recon_dir" "$rec_name" "$orig_name" 2>&1; then
        
        # Verificar que se generó el archivo PSNR
        psnr_file="$recon_dir/psnr_${rec_name}.txt"
        if [ -f "$psnr_file" ]; then
            lines=$(wc -l < "$psnr_file")
            echo ""
            echo "  [+] ✓ PSNR calculado exitosamente"
            echo "      Archivo: psnr_${rec_name}.txt ($lines líneas)"
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
    echo ""
    
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
    for tx_dir in "${CONFIG_DIRS[@]}"; do
        config=$(basename "$tx_dir")
        recon_dir="$RECON_DIR/videos/$config"
        psnr_file="$recon_dir/psnr_"*".txt"
        for pf in $psnr_file; do
            if [ -f "$pf" ]; then
                lines=$(wc -l < "$pf")
                echo "  ✓ $config/$(basename $pf) ($lines líneas)"
            fi
        done
    done
fi

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
if [ $failed -eq 0 ] && [ $success -gt 0 ]; then
    echo "║         TODOS LOS CÁLCULOS COMPLETADOS EXITOSAMENTE      ║"
else
    echo "║          CÁLCULO COMPLETADO CON ALGUNOS ERRORES         ║"
fi
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "Próximo paso: python3 psnr_new.py $RECON_DIR"
