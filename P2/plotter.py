import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import scipy.stats as stats
from pathlib import Path

# ===========================
# CONFIGURACIÓN
# ===========================
CSV_DIR = Path("output/data")  # Carpeta donde están los CSVs
OUTPUT_PLOT = "psnr_bars.png"  # Archivo de salida de la gráfica

# ===========================
# LEER CSVs
# ===========================
csv_files = list(CSV_DIR.glob("*_psnr.csv"))
if not csv_files:
    raise ValueError(f"No se encontraron CSV en {CSV_DIR}")

video_names = []
means = []
ci95 = []

for csv_file in csv_files:
    df = pd.read_csv(csv_file, names=["frame", "psnry", "psnru", "psnrv"])
    psnrY_values = df["psnry"].values
    psnrU_values = df["psnru"].values
    psnrV_values = df["psnrv"].values

    # Media
    mean_psnr = np.mean(psnrY_values)
    name = csv_file.stem.replace("_psnr", "").split(".")[0]+"_QP"
    video_names.append(name)  # solo el nombre base

    # Intervalo de confianza 95%
    n = len(psnrY_values)
    sem = stats.sem(psnrY_values)  # error estándar de la media
    h = sem * stats.t.ppf((1 + 0.95) / 2, n-1)  # intervalo t-student
    means.append(mean_psnr)
    ci95.append(h)

# ===========================
# ORDENAR POR BITRATE ASCENDENTE
# ===========================
bitrates = []
for name in video_names:
    # Suponiendo formato "..._<bitrate>k"
    try:
        num = int(name.split("_")[-2])
    except ValueError:
        num = 0
    bitrates.append(num)

sorted_idx = np.argsort(bitrates)

video_names = [video_names[i] for i in sorted_idx]
means       = [means[i]       for i in sorted_idx]
ci95        = [ci95[i]        for i in sorted_idx]

# ===========================
# GRAFICA DE BARRAS
# ===========================
plt.figure(figsize=(10,6))
plt.bar(video_names, means, yerr=ci95, capsize=5, color='skyblue')
plt.ylabel("PSNR (dB)")
plt.xlabel("Video")
plt.title("PSNR promedio con IC 95% por video")
plt.xticks(rotation=45, ha='right')
plt.tight_layout()
plt.grid(axis='y', linestyle='--', alpha=0.7)

plt.savefig(OUTPUT_PLOT, dpi=300)
plt.show()
