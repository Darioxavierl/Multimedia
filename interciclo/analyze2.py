#!/usr/bin/env python3
import sys
import numpy as np
import matplotlib.pyplot as plt
from scapy.all import rdpcap, UDP

# ---------------------------------------------------------------
# CARGA PCAP Y FILTRA POR PUERTO (solo paquetes UDP)
# ---------------------------------------------------------------
def load_pcap(filename, port):
    packets = rdpcap(filename)
    timestamps = []
    sizes = []

    for p in packets:
        if UDP in p:
            if p[UDP].sport == port or p[UDP].dport == port:
                timestamps.append(float(p.time))
                sizes.append(len(p))

    return np.array(timestamps), np.array(sizes)


# ---------------------------------------------------------------
# CALCULAR IAT = Inter-arrival time (delay a nivel captura)
# ---------------------------------------------------------------
def compute_iat(ts, discard_seconds=1.0):
    """
    Calcula IAT eliminando el tramo inicial para evitar picos
    por diferencias entre inicios de captura.
    """
    if len(ts) < 2:
        return np.array([])

    # descartar tramo inicial
    t0 = ts[0] + discard_seconds
    ts = ts[ts >= t0]

    if len(ts) < 2:
        return np.array([])

    return np.diff(ts)


# ---------------------------------------------------------------
# THROUGHPUT EN VENTANAS DE 1s
# ---------------------------------------------------------------
def compute_throughput(ts, sizes, window=1.0):
    if len(ts) == 0:
        return np.array([]), np.array([])

    start = ts[0]
    end = ts[-1]
    bins = np.arange(start, end, window)
    throughput = []

    for i in range(len(bins)-1):
        t0 = bins[i]
        t1 = bins[i+1]
        mask = (ts >= t0) & (ts < t1)
        total_bytes = sizes[mask].sum()
        throughput.append(total_bytes * 8 / window)

    return bins[:-1], np.array(throughput)


# ---------------------------------------------------------------
# ANÁLISIS GENERAL
# ---------------------------------------------------------------
def analyze(pcapA, pcapB, port):
    print("Cargando PCAP A...")
    tsA, sizeA = load_pcap(pcapA, port)

    print("Cargando PCAP B...")
    tsB, sizeB = load_pcap(pcapB, port)

    if len(tsA) == 0 or len(tsB) == 0:
        print("ERROR: Uno de los PCAP no tiene paquetes UDP en ese puerto.")
        return

    # Normalizar tiempos para gráfica
    t0 = min(tsA[0], tsB[0])
    tsA_norm = tsA - t0
    tsB_norm = tsB - t0

    # ----------------------------
    # IAT
    # ----------------------------
    iatA = compute_iat(tsA_norm)
    iatB = compute_iat(tsB_norm)

    print(f"IAT A: {len(iatA)} muestras")
    print(f"IAT B: {len(iatB)} muestras")

    # ----------------------------
    # THROUGHPUT
    # ----------------------------
    tA, thrA = compute_throughput(tsA_norm, sizeA)
    tB, thrB = compute_throughput(tsB_norm, sizeB)

    # ---------------------------------------------------
    # GRÁFICAS
    # ---------------------------------------------------

    # ----------- IAT (delay capturado) ----------------
    plt.figure(figsize=(12, 6))
    plt.plot(iatA * 1000, label="IAT A (ms)", alpha=0.7)
    plt.plot(iatB * 1000, label="IAT B (ms)", alpha=0.7)
    plt.title("Delay a nivel de captura (IAT)")
    plt.xlabel("N° de paquete")
    plt.ylabel("IAT (ms)")
    plt.grid()
    plt.legend()

    # ----------- THROUGHPUT ---------------------------
    plt.figure(figsize=(12, 6))
    plt.plot(tA, thrA/1e6, label="Throughput A (Mbps)")
    plt.plot(tB, thrB/1e6, label="Throughput B (Mbps)")
    plt.title("Throughput")
    plt.xlabel("Tiempo (s)")
    plt.ylabel("Mbps")
    plt.grid()
    plt.legend()

    plt.show()


# ---------------------------------------------------------------
# MAIN
# ---------------------------------------------------------------
if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("Uso: python3 analyze_iat.py <pcap_A> <pcap_B> <puerto>")
        sys.exit(1)

    analyze(sys.argv[1], sys.argv[2], int(sys.argv[3]))
