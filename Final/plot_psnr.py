#!/usr/bin/env python3
import os
import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
from scipy import stats
from pathlib import Path
from dotenv import load_dotenv

# Cargar variables de entorno
load_dotenv()
BITRATE = os.getenv('BITRATE', '300k')
QP = os.getenv('QP', '28')

# Directorios
PSNR_DIR = "PSNR"
OUTPUT_DIR = "img"
os.makedirs(OUTPUT_DIR, exist_ok=True)

def parse_psnr_csv(csv_path):
    """
    Lee el CSV generado por ffmpeg psnr filter y extrae valores PSNR
    El formato típico es: n:1 mse_avg:0.52 mse_y:0.50 mse_u:0.56 mse_v:0.58 psnr_avg:50.98 psnr_y:51.14 psnr_u:50.62 psnr_v:50.48
    """
    psnr_values = []
    
    try:
        with open(csv_path, 'r') as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith('#'):
                    continue
                
                # Buscar psnr_avg en la línea
                if 'psnr_avg:' in line:
                    parts = line.split()
                    for part in parts:
                        if part.startswith('psnr_avg:'):
                            try:
                                psnr = float(part.split(':')[1])
                                psnr_values.append(psnr)
                            except:
                                continue
    except Exception as e:
        print(f"Error leyendo {csv_path}: {e}")
        return []
    
    return psnr_values

def calculate_mean_ci(values, confidence=0.95):
    """
    Calcula la media y el intervalo de confianza
    """
    if len(values) == 0:
        return 0, 0, 0
    
    mean = np.mean(values)
    
    if len(values) == 1:
        return mean, 0, 0
    
    # Calcular intervalo de confianza usando t-student
    sem = stats.sem(values)  # Error estándar de la media
    ci = sem * stats.t.ppf((1 + confidence) / 2., len(values) - 1)
    
    return mean, ci, sem

def get_video_names():
    """
    Obtiene lista de nombres base de videos únicos
    """
    video_names = set()
    
    # Buscar en PSNR/h264/BR/
    br_path = Path(PSNR_DIR) / "h264" / "BR"
    if br_path.exists():
        for csv_file in br_path.glob("*_psnr.csv"):
            # Extraer nombre base (quitar _BR_psnr.csv)
            name = csv_file.stem.replace('_BR_psnr', '')
            video_names.add(name)
    
    return sorted(video_names)

def get_psnr_data(video_base_name):
    """
    Recopila datos PSNR para un video desde todas las configuraciones
    """
    data = {
        'h264_br': [],
        'h264_qp': [],
        'vp8_br': [],
        'vp8_qp': []
    }
    
    configs = [
        ('h264', 'BR', 'h264_br', f'{video_base_name}_BR_psnr.csv'),
        ('h264', 'QP', 'h264_qp', f'{video_base_name}_QP_psnr.csv'),
        ('vp8', 'BR', 'vp8_br', f'{video_base_name}_BR_psnr.csv'),
        ('vp8', 'QP', 'vp8_qp', f'{video_base_name}_QP_psnr.csv'),
    ]
    
    for codec, mode, key, filename in configs:
        csv_path = Path(PSNR_DIR) / codec / mode / filename
        if csv_path.exists():
            psnr_values = parse_psnr_csv(csv_path)
            data[key] = psnr_values
            print(f"  {codec}/{mode}: {len(psnr_values)} frames, PSNR promedio: {np.mean(psnr_values) if psnr_values else 0:.2f} dB")
        else:
            print(f"  {codec}/{mode}: Archivo no encontrado")
    
    return data

def plot_video_comparison(video_name, data):
    """
    Crea gráfica de barras agrupadas con intervalos de confianza
    """
    # Calcular medias e intervalos de confianza
    stats_data = {}
    for key, values in data.items():
        mean, ci, sem = calculate_mean_ci(values)
        stats_data[key] = {'mean': mean, 'ci': ci, 'sem': sem}
    
    # Configurar datos para la gráfica
    x_labels = [f'Bitrate\n({BITRATE})', f'QP\n({QP})']
    x = np.arange(len(x_labels))
    width = 0.35
    
    # Extraer datos
    h264_means = [stats_data['h264_br']['mean'], stats_data['h264_qp']['mean']]
    h264_ci = [stats_data['h264_br']['ci'], stats_data['h264_qp']['ci']]
    
    vp8_means = [stats_data['vp8_br']['mean'], stats_data['vp8_qp']['mean']]
    vp8_ci = [stats_data['vp8_br']['ci'], stats_data['vp8_qp']['ci']]
    
    # Crear figura
    fig, ax = plt.subplots(figsize=(10, 6))
    
    # Crear barras
    bars1 = ax.bar(x - width/2, h264_means, width, yerr=h264_ci, 
                   label='H.264', capsize=5, color='#2E86AB', alpha=0.8)
    bars2 = ax.bar(x + width/2, vp8_means, width, yerr=vp8_ci,
                   label='VP8', capsize=5, color='#A23B72', alpha=0.8)
    
    # Añadir valores encima de las barras
    for i, (bar, mean, ci) in enumerate(zip(bars1, h264_means, h264_ci)):
        height = bar.get_height()
        ax.text(bar.get_x() + bar.get_width()/2., height + ci,
                f'{mean:.2f}±{ci:.2f}',
                ha='center', va='bottom', fontsize=9, fontweight='bold')
    
    for i, (bar, mean, ci) in enumerate(zip(bars2, vp8_means, vp8_ci)):
        height = bar.get_height()
        ax.text(bar.get_x() + bar.get_width()/2., height + ci,
                f'{mean:.2f}±{ci:.2f}',
                ha='center', va='bottom', fontsize=9, fontweight='bold')
    
    # Configurar ejes y título
    ax.set_ylabel('PSNR (dB)', fontsize=12, fontweight='bold')
    ax.set_xlabel('Modo de Control de Tasa', fontsize=12, fontweight='bold')
    ax.set_title(f'Comparación PSNR: {video_name}', fontsize=14, fontweight='bold', pad=20)
    ax.set_xticks(x)
    ax.set_xticklabels(x_labels)
    ax.legend(fontsize=11, loc='lower right')
    ax.grid(True, alpha=0.3, axis='y')
    
    # Ajustar layout
    plt.tight_layout()
    
    # Guardar figura
    output_path = Path(OUTPUT_DIR) / f'{video_name}_psnr_comparison.png'
    plt.savefig(output_path, dpi=300, bbox_inches='tight')
    plt.close()
    
    print(f"  ✓ Gráfica guardada: {output_path}")

def main():
    print("=" * 50)
    print("Análisis y Graficación de PSNR")
    print("=" * 50)
    print(f"Bitrate: {BITRATE}")
    print(f"QP: {QP}")
    print()
    
    # Obtener lista de videos
    video_names = get_video_names()
    
    if not video_names:
        print("No se encontraron videos para procesar")
        return
    
    print(f"Videos encontrados: {len(video_names)}")
    print()
    
    # Procesar cada video
    for i, video_name in enumerate(video_names, 1):
        print(f"[{i}/{len(video_names)}] Procesando: {video_name}")
        
        # Obtener datos PSNR
        data = get_psnr_data(video_name)
        
        # Verificar que hay datos
        has_data = any(len(values) > 0 for values in data.values())
        if not has_data:
            print(f"  ⚠ No hay datos PSNR para {video_name}")
            continue
        
        # Crear gráfica
        plot_video_comparison(video_name, data)
        print()
    
    print("=" * 50)
    print(f"Proceso completado. Gráficas guardadas en: {OUTPUT_DIR}/")
    print("=" * 50)

if __name__ == "__main__":
    main()
