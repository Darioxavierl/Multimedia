#!/usr/bin/env python3
"""
Script para analizar y visualizar PSNR de diferentes configuraciones de video
"""

import os
import sys
import glob
import numpy as np
import matplotlib.pyplot as plt
from pathlib import Path

# Configuración de matplotlib
plt.style.use('seaborn-v0_8-darkgrid')
plt.rcParams['figure.figsize'] = (14, 8)
plt.rcParams['font.size'] = 11


def extract_psnr_from_file(filepath):
    """
    Extrae valores de PSNR desde el archivo generado por psnr_video.sh
    
    El formato es:
    psnr: 300 frames (CPU: 0 s) mean: 15.37 stdv: 4.33
    valor1
    valor2
    ...
    """
    try:
        with open(filepath, 'r') as f:
            lines = f.readlines()
        
        if not lines:
            print(f"  [-] Archivo vacío: {filepath}")
            return None
        
        # Primera línea contiene el resumen
        header = lines[0].strip()
        
        # Extraer mean del header
        if 'mean:' in header:
            mean_str = header.split('mean:')[1].split()[0]
            mean_psnr = float(mean_str)
            return mean_psnr
        else:
            print(f"  [-] Formato inválido en: {filepath}")
            return None
            
    except Exception as e:
        print(f"  [-] Error al procesar {filepath}: {e}")
        return None


def collect_psnr_data(videos_dir):
    """
    Recorre la carpeta videos/ y recopila datos PSNR de cada configuración
    """
    configs = {}
    
    # Buscar todas las subcarpetas en videos/
    config_dirs = sorted([d for d in Path(videos_dir).iterdir() if d.is_dir()])
    
    if not config_dirs:
        print(f"[-] No se encontraron directorios en {videos_dir}")
        return None
    
    print(f"[+] Analizando {len(config_dirs)} configuración(es)...\n")
    
    for config_dir in config_dirs:
        config_name = config_dir.name
        print(f"[*] Procesando: {config_name}")
        
        # Buscar archivo PSNR en esta carpeta
        psnr_files = list(config_dir.glob('psnr_*.txt'))
        
        if not psnr_files:
            print(f"  [-] No se encontró archivo PSNR en {config_name}")
            continue
        
        psnr_file = psnr_files[0]  # Tomar el primero si hay múltiples
        print(f"  [*] Archivo: {psnr_file.name}")
        
        # Extraer PSNR
        mean_psnr = extract_psnr_from_file(psnr_file)
        
        if mean_psnr is not None:
            configs[config_name] = mean_psnr
            print(f"  [+] PSNR Mean: {mean_psnr:.2f} dB")
        
        print()
    
    if not configs:
        print("[-] No se recopilaron datos PSNR")
        return None
    
    return configs


def create_bar_chart(configs, output_file='psnr_comparison.png'):
    """
    Crea un gráfico de barras comparativo con los datos PSNR
    """
    # Ordenar por valor PSNR descendente
    sorted_configs = sorted(configs.items(), key=lambda x: x[1], reverse=True)
    names = [item[0] for item in sorted_configs]
    values = [item[1] for item in sorted_configs]
    
    # Crear figura y eje
    fig, ax = plt.subplots(figsize=(12, 7))
    
    # Colores según el tipo de configuración
    colors = []
    for name in names:
        if 'qp' in name.lower():
            colors.append('#FF6B6B')  # Rojo para QP
        else:
            colors.append('#4ECDC4')  # Verde azulado para bitrate
    
    # Crear barras
    bars = ax.bar(names, values, color=colors, edgecolor='black', linewidth=1.5, alpha=0.8)
    
    # Añadir valores en las barras
    for bar in bars:
        height = bar.get_height()
        ax.text(bar.get_x() + bar.get_width()/2., height,
                f'{height:.2f}',
                ha='center', va='bottom', fontsize=11, fontweight='bold')
    
    # Configurar ejes
    ax.set_xlabel('Configuración', fontsize=12, fontweight='bold')
    ax.set_ylabel('PSNR Mean (dB)', fontsize=12, fontweight='bold')
    ax.set_title('Comparativa de PSNR por Configuración de Video', fontsize=14, fontweight='bold')
    ax.set_ylim(0, max(values) * 1.15)
    ax.grid(axis='y', alpha=0.3)
    
    # Leyenda
    from matplotlib.patches import Patch
    legend_elements = [
        Patch(facecolor='#FF6B6B', edgecolor='black', label='QP (Calidad)'),
        Patch(facecolor='#4ECDC4', edgecolor='black', label='Bitrate (kbps)')
    ]
    ax.legend(handles=legend_elements, loc='upper right', fontsize=10)
    
    # Mejorar layout
    plt.tight_layout()
    
    # Guardar figura
    plt.savefig(output_file, dpi=300, bbox_inches='tight')
    print(f"[+] Gráfico guardado: {output_file}")
    
    # Mostrar figura
    plt.show()


def create_statistics_table(configs):
    """
    Imprime una tabla de estadísticas
    """
    if not configs:
        return
    
    print("\n" + "="*60)
    print("ESTADÍSTICAS PSNR")
    print("="*60)
    
    values = list(configs.values())
    names = list(configs.keys())
    
    print(f"{'Configuración':<15} {'PSNR (dB)':<15}")
    print("-"*30)
    
    for name, psnr in sorted(configs.items(), key=lambda x: x[1], reverse=True):
        print(f"{name:<15} {psnr:<15.2f}")
    
    print("-"*30)
    print(f"{'Máximo':<15} {max(values):<15.2f}")
    print(f"{'Mínimo':<15} {min(values):<15.2f}")
    print(f"{'Promedio':<15} {np.mean(values):<15.2f}")
    print(f"{'Desv. Estándar':<15} {np.std(values):<15.2f}")
    print("="*60 + "\n")


def main():
    """
    Función principal
    """
    # Determinar directorio de videos
    if len(sys.argv) > 1:
        videos_dir = sys.argv[1]
    else:
        videos_dir = './videos'
    
    # Validar que la carpeta existe
    if not os.path.isdir(videos_dir):
        print(f"[-] Error: El directorio '{videos_dir}' no existe")
        sys.exit(1)
    
    print("╔════════════════════════════════════════════════════════════════╗")
    print("║         ANÁLISIS COMPARATIVO DE PSNR - VIDEO CODECS           ║")
    print("╚════════════════════════════════════════════════════════════════╝")
    print()
    
    # Recopilar datos PSNR
    configs = collect_psnr_data(videos_dir)
    
    if not configs:
        print("[-] No se pudieron recopilar datos PSNR")
        sys.exit(1)
    
    # Mostrar estadísticas
    create_statistics_table(configs)
    
    # Crear gráfico de barras
    output_file = os.path.join(videos_dir, '../psnr_comparison.png')
    create_bar_chart(configs, output_file)
    
    print("[+] ¡Análisis completado!")


if __name__ == '__main__':
    main()
