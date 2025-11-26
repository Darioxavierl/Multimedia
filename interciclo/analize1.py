#!/usr/bin/env python3
import sys
import numpy as np
import matplotlib.pyplot as plt
from scapy.all import rdpcap, UDP


# ---------------------------------------------------------------
# CARGA PCAP Y EXTRAE TIMESTAMPS Y TAMAÑOS DE PAQUETES UDP
# ---------------------------------------------------------------
def load_pcap(filename):
    packets = rdpcap(filename)
    timestamps = []
    sizes = []

    for p in packets:
        if UDP in p:
            timestamps.append(float(p.time))
            sizes.append(len(p))

    return np.array(timestamps), np.array(sizes)


# ---------------------------------------------------------------
# ESTIMAR OFFSET ENTRE RELOJES (A → B)
# ---------------------------------------------------------------
def estimate_offset(tsA, tsB, max_delay=1.0):
    """
    Busca para cada timestamp en A un timestamp cercano en B,
    calcula diferencias B - A y toma la mediana como offset.

    max_delay: filtra diferencias imposibles (ej. >1 s)
    """
    print("Estimando offset entre relojes...")

    diffs = []

    j = 0
    for t in tsA:
        # avanzar en B hasta estar "cerca"
        while j < len(tsB) - 1 and tsB[j] < t:
            j += 1

        candidates = []
        if j > 0:
            candidates.append(tsB[j - 1])
        candidates.append(tsB[j])

        for c in candidates:
            diffs.append(c - t)

    diffs = np.array(diffs)

    # filtrar valores imposibles
    diffs = diffs[np.abs(diffs) < max_delay]

    if len(diffs) == 0:
        print("⚠ No se pudo estimar offset. Se usará 0.")
        return 0.0

    offset = np.median(diffs)
    print(f"✔ Offset estimado: {offset:.6f} segundos")

    return offset


# ---------------------------------------------------------------
# CALCULA THROUGHPUT EN VENTANAS DE 1 SEGUNDO
# ---------------------------------------------------------------
def compute_throughput(timestamps, sizes, window=1.0):
    if len(timestamps) == 0:
        return np.array([]), np.array([])

    start = timestamps[0]
    end = timestamps[-1]

    bins = np.arange(start, end, window)
    throughput = []

    for i in range(len(bins)-1):
        t0 = bins[i]
        t1 = bins[i+1]
        mask = (timestamps >= t0) & (timestamps < t1)
        total_bytes = sizes[mask].sum()
        throughput.append(total_bytes * 8 / window)  # bits/s

    return bins[:-1], np.array(throughput)


# ---------------------------------------------------------------
# PROCESO PRINCIPAL
# ---------------------------------------------------------------
def analyze(pcapA, pcapB):
    print("Cargando PCAP A...")
    tsA, sizeA = load_pcap(pcapA)

    print("Cargando PCAP B...")
    tsB, sizeB = load_pcap(pcapB)

    if len(tsA) == 0 or len(tsB) == 0:
        print("ERROR: Uno de los pcaps no tiene paquetes UDP.")
        return

    # ------ 1) Estimar offset ------
    offset = estimate_offset(tsA, tsB)

    # ------ 2) Corregir reloj de B ------
    tsB_corr = tsB - offset

    # ------ 3) Normalización conjunta ------
    t0 = min(tsA[0], tsB_corr[0])
    tsA_norm = tsA - t0
    tsB_norm = tsB_corr - t0

    # ------ 4) Calcular delays ------
    delays = []

    j = 0
    for tA in tsA_norm:
        while j < len(tsB_norm) - 1 and tsB_norm[j] < tA:
            j += 1

        candidates = []
        if j > 0:
            candidates.append(tsB_norm[j - 1])
        candidates.append(tsB_norm[j])

        best = min(candidates, key=lambda x: abs(x - tA))
        delays.append(best - tA)

    delays = np.array(delays)

    # ------ 5) Filtrar delays imposibles ------
    delays = delays[np.abs(delays) < 1.0]  # 1 segundo max
    print(f"✔ Delays válidos: {len(delays)}")

    # ------ 6) Throughput ------
    tA, thrA = compute_throughput(tsA_norm, sizeA)
    tB, thrB = compute_throughput(tsB_norm, sizeB)

    # ---------------------------------------------------
    # GRÁFICAS
    # ---------------------------------------------------
    plt.figure(figsize=(12, 6))
    plt.plot(tsA_norm[:len(delays)], delays * 1000)
    plt.title("Delay aproximado (ms)")
    plt.xlabel("Tiempo (s)")
    plt.ylabel("Delay (ms)")
    plt.grid()

    plt.figure(figsize=(12, 6))
    plt.plot(tA, thrA / 1e6, label="A → B (Mbps)")
    plt.plot(tB, thrB / 1e6, label="B → A (Mbps)")
    plt.title("Throughput (Mbps)")
    plt.xlabel("Tiempo (s)")
    plt.ylabel("Mbps")
    plt.grid()
    plt.legend()

    plt.show()


# ---------------------------------------------------------------
# MAIN
# ---------------------------------------------------------------
if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Uso: python3 analyze_v2.py <pcap_emisor> <pcap_receptor>")
        sys.exit(1)

    analyze(sys.argv[1], sys.argv[2])
