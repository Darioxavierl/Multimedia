import os
import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
import re
from math import sqrt

# ====================
# CONFIGURACIONES
# ====================

CARPETA_BASE = "./res"   # carpeta que contiene subcarpetas (cada una = una repetición)
PAQUETES_ENVIADOS = 2000        # según tu experimento
Z_90 = 1.645                     # valor Z para intervalo de confianza del 90%

# ====================
# FUNCIONES
# ====================

def extraer_distancia(nombre):
    """Extrae la distancia numérica desde un archivo como distancia_10.csv."""
    m = re.search(r"(\d+)", nombre)
    return int(m.group(1)) if m else None


def leer_csv_distancia(ruta):
    """Devuelve cuántos paquetes hay en el CSV."""
    try:
        df = pd.read_csv(ruta)
        return len(df)
    except:
        return 0


# ====================
# RECORRER TODAS LAS SUBCARPETAS
# ====================

# dict: distancia → lista de paquetes recibidos en cada repetición
datos_distancias = {}

subcarpetas = [os.path.join(CARPETA_BASE, d) for d in os.listdir(CARPETA_BASE)
               if os.path.isdir(os.path.join(CARPETA_BASE, d))]

print(f"Se encontraron {len(subcarpetas)} repeticiones:\n")

for carpeta in subcarpetas:
    print(f"--- Leyendo repetición: {carpeta}")
    for archivo in os.listdir(carpeta):
        if archivo.endswith(".csv"):

            distancia = extraer_distancia(archivo)
            if distancia is None:
                continue

            ruta_csv = os.path.join(carpeta, archivo)
            recibidos = leer_csv_distancia(ruta_csv)

            if distancia not in datos_distancias:
                datos_distancias[distancia] = []

            datos_distancias[distancia].append(recibidos)

            print(f"  {archivo}: {recibidos} paquetes")

    print("")


# ====================
# PROCESAR RESULTADOS
# ====================

distancias = sorted(datos_distancias.keys())

medias_paquetes = []
ic_paquetes = []

medias_porcentaje = []
ic_porcentaje = []

for d in distancias:
    muestras = np.array(datos_distancias[d])
    n = len(muestras)

    media = np.mean(muestras)
    std = np.std(muestras, ddof=1)

    # Intervalo de confianza 90%
    margen = Z_90 * (std / sqrt(n))

    # Guardar resultados paquetes
    medias_paquetes.append(media)
    ic_paquetes.append(margen)

    # Convertir a porcentaje
    porcentaje = (media / PAQUETES_ENVIADOS) * 100
    margen_pct = (margen / PAQUETES_ENVIADOS) * 100

    medias_porcentaje.append(porcentaje)
    ic_porcentaje.append(margen_pct)

    print(f"Distancia {d}m → media={media:.1f}, IC90=±{margen:.1f} paquetes")


# ====================
# GRÁFICA 1 — Porcentaje de Recepción vs Distancia
# ====================

plt.figure(figsize=(9, 5))
plt.errorbar(distancias[:-1], medias_porcentaje[:-1], yerr=ic_porcentaje[:-1],
             fmt="o-", capsize=5, linewidth=2)

plt.xlabel("Distancia [m]")
plt.ylabel("Recepción de Paquetes [%]")
plt.title("% Promedio de Paquetes Recibidos vs Distancia (IC 90%)")
plt.grid(True)
plt.tight_layout()



plt.show()

