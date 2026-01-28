#!/usr/bin/env python3
import os
import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
from pathlib import Path
import multiprocessing

# Directorios
CPU_LOGS_DIR = "cpu_logs"
OUTPUT_DIR = "img"
os.makedirs(OUTPUT_DIR, exist_ok=True)

# Obtener número de CPUs para normalización
NUM_CPUS = multiprocessing.cpu_count()
print(f"Número de CPUs detectadas: {NUM_CPUS}")

def read_cpu_csv(csv_path):
    """
    Lee el CSV de CPU y normaliza los valores
    """
    try:
        df = pd.read_csv(csv_path)
        
        # Normalizar CPU (de 0-N*100 a 0-100)
        df['cpu_normalized'] = df['cpu_percent'] / NUM_CPUS
        
        # Crear eje temporal en segundos (desde 0)
        df['time_seconds'] = (pd.to_datetime(df['timestamp']) - pd.to_datetime(df['timestamp'].iloc[0])).dt.total_seconds()
        
        return df
    except Exception as e:
        print(f"Error leyendo {csv_path}: {e}")
        return None

def get_video_names():
    """
    Obtiene lista de nombres base de videos únicos
    """
    video_names = set()
    
    # Buscar en cpu_logs/h264/BR/
    br_path = Path(CPU_LOGS_DIR) / "h264" / "BR"
    if br_path.exists():
        for csv_file in br_path.glob("*_cpu.csv"):
            # Extraer nombre base (quitar _BR_cpu.csv)
            name = csv_file.stem.replace('_BR_cpu', '')
            video_names.add(name)
    
    return sorted(video_names)

def get_cpu_data(video_base_name):
    """
    Recopila datos de CPU para un video desde todas las configuraciones
    """
    data = {}
    
    configs = [
        ('h264', 'BR', 'h264_br', f'{video_base_name}_BR_cpu.csv'),
        ('h264', 'QP', 'h264_qp', f'{video_base_name}_QP_cpu.csv'),
        ('VP8', 'BR', 'vp8_br', f'{video_base_name}_BR_cpu.csv'),
        ('VP8', 'QP', 'vp8_qp', f'{video_base_name}_QP_cpu.csv'),
    ]
    
    for codec, mode, key, filename in configs:
        csv_path = Path(CPU_LOGS_DIR) / codec / mode / filename
        if csv_path.exists():
            df = read_cpu_csv(csv_path)
            if df is not None and not df.empty:
                data[key] = df
                print(f"  {codec}/{mode}: {len(df)} muestras, duración: {df['time_seconds'].max():.2f}s")
            else:
                print(f"  {codec}/{mode}: Error al leer datos")
        else:
            print(f"  {codec}/{mode}: Archivo no encontrado")
    
    return data

def plot_cpu_comparison(video_name, data):
    """
    Crea figura con 2 subplots (BR y QP) comparando H264 vs VP8
    """
    # Verificar que tenemos datos
    if not data:
        print(f"  ⚠ No hay datos de CPU para {video_name}")
        return
    
    # Crear figura con 2 subplots verticales
    fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(14, 10))
    fig.suptitle(f'Comparación Uso de CPU: {video_name}', fontsize=16, fontweight='bold', y=0.995)
    
    # Colores
    color_h264 = '#2E86AB'
    color_vp8 = '#A23B72'
    
    # ==================== SUBPLOT 1: BITRATE ====================
    ax1.set_title('Modo Bitrate', fontsize=13, fontweight='bold', pad=10)
    
    # H264 BR
    if 'h264_br' in data:
        df = data['h264_br']
        ax1.plot(df['time_seconds'], df['cpu_normalized'], 
                color=color_h264, alpha=0.7, linewidth=1, label='H.264')
        mean_h264_br = df['cpu_normalized'].mean()
        ax1.axhline(y=mean_h264_br, color=color_h264, linestyle='--', 
                   linewidth=2, alpha=0.9, label=f'H.264 Media: {mean_h264_br:.2f}%')
    
    # VP8 BR
    if 'vp8_br' in data:
        df = data['vp8_br']
        ax1.plot(df['time_seconds'], df['cpu_normalized'], 
                color=color_vp8, alpha=0.7, linewidth=1, label='VP8')
        mean_vp8_br = df['cpu_normalized'].mean()
        ax1.axhline(y=mean_vp8_br, color=color_vp8, linestyle='--', 
                   linewidth=2, alpha=0.9, label=f'VP8 Media: {mean_vp8_br:.2f}%')
    
    ax1.set_xlabel('Tiempo (segundos)', fontsize=11, fontweight='bold')
    ax1.set_ylabel('Uso de CPU Normalizado (%)', fontsize=11, fontweight='bold')
    ax1.legend(loc='upper right', fontsize=10)
    ax1.grid(True, alpha=0.3)
    ax1.set_ylim(bottom=0)
    
    # ==================== SUBPLOT 2: QP ====================
    ax2.set_title('Modo QP', fontsize=13, fontweight='bold', pad=10)
    
    # H264 QP
    if 'h264_qp' in data:
        df = data['h264_qp']
        ax2.plot(df['time_seconds'], df['cpu_normalized'], 
                color=color_h264, alpha=0.7, linewidth=1, label='H.264')
        mean_h264_qp = df['cpu_normalized'].mean()
        ax2.axhline(y=mean_h264_qp, color=color_h264, linestyle='--', 
                   linewidth=2, alpha=0.9, label=f'H.264 Media: {mean_h264_qp:.2f}%')
    
    # VP8 QP
    if 'vp8_qp' in data:
        df = data['vp8_qp']
        ax2.plot(df['time_seconds'], df['cpu_normalized'], 
                color=color_vp8, alpha=0.7, linewidth=1, label='VP8')
        mean_vp8_qp = df['cpu_normalized'].mean()
        ax2.axhline(y=mean_vp8_qp, color=color_vp8, linestyle='--', 
                   linewidth=2, alpha=0.9, label=f'VP8 Media: {mean_vp8_qp:.2f}%')
    
    ax2.set_xlabel('Tiempo (segundos)', fontsize=11, fontweight='bold')
    ax2.set_ylabel('Uso de CPU Normalizado (%)', fontsize=11, fontweight='bold')
    ax2.legend(loc='upper right', fontsize=10)
    ax2.grid(True, alpha=0.3)
    ax2.set_ylim(bottom=0)
    
    # Ajustar layout
    plt.tight_layout()
    
    # Guardar figura
    output_path = Path(OUTPUT_DIR) / f'{video_name}_cpu_comparison.png'
    plt.savefig(output_path, dpi=300, bbox_inches='tight')
    plt.close()
    
    print(f"  ✓ Gráfica guardada: {output_path}")

def main():
    print("=" * 60)
    print("Análisis y Graficación de Uso de CPU")
    print("=" * 60)
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
        
        # Obtener datos de CPU
        data = get_cpu_data(video_name)
        
        # Crear gráfica
        plot_cpu_comparison(video_name, data)
        print()
    
    print("=" * 60)
    print(f"Proceso completado. Gráficas guardadas en: {OUTPUT_DIR}/")
    print("=" * 60)

if __name__ == "__main__":
    main()
