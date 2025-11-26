#!/usr/bin/env python3
import sys
from scapy.all import rdpcap, UDP
import matplotlib.pyplot as plt
from collections import defaultdict
import numpy as np

# -------------------------------------------------
#  Helper: Extract timestamps and sizes from PCAP
# -------------------------------------------------
def extract_flows(pcap_file, port):
    pkts = rdpcap(pcap_file)
    flows = []
    for p in pkts:
        if UDP in p and p[UDP].dport == port or p[UDP].sport == port:
            ts = float(p.time)
            size = len(p)
            flows.append((ts, size))
    return sorted(flows, key=lambda x: x[0])

# -------------------------------------------------
#  Throughput: bits/s por ventanas de 1 segundo
# -------------------------------------------------
def compute_throughput(flow):
    # Agrupar por segundo
    throughput = defaultdict(int)
    for ts, size in flow:
        sec = int(ts)
        throughput[sec] += size * 8  # bits
    # Ordenar salida
    times = sorted(throughput.keys())
    values = [throughput[t] for t in times]
    return times, values

# -------------------------------------------------
#  Delay relativo: Matching por timestamps cercanos
# -------------------------------------------------
def compute_delay(flowA, flowB, max_gap=0.050):
    """
    Para cada paquete enviado por A, busca el paquete más cercano en B.
    max_gap = 50 ms tolerancia
    """
    delays = []
    idxB = 0
    for tsA, sizeA in flowA:
        # avanzar B
        while idxB + 1 < len(flowB) and abs(flowB[idxB + 1][0] - tsA) < abs(flowB[idxB][0] - tsA):
            idxB += 1
        
        tsB, sizeB = flowB[idxB]
        diff = tsB - tsA

        if abs(diff) <= max_gap:  # solo aceptamos si es plausible delay
            delays.append(diff)

    return delays

# -------------------------------------------------
#  Main
# -------------------------------------------------
if __name__ == "__main__":
    if len(sys.argv) < 4:
        print("Uso: python analyze_vc.py captura_A.pcap captura_B.pcap PUERTO")
        sys.exit(1)

    pcapA = sys.argv[1]
    pcapB = sys.argv[2]
    port = int(sys.argv[3])

    print(f"[i] Cargando PCAPs…")
    flowA = extract_flows(pcapA, port)
    flowB = extract_flows(pcapB, port)

    print(f"[i] Calculando throughput…")
    tA, thrA = compute_throughput(flowA)

    print(f"[i] Calculando delay relativo…")
    delays = compute_delay(flowA, flowB)

    # -------------------------------
    #   Graficar resultados
    # -------------------------------
    plt.figure(figsize=(12,4))
    plt.plot(tA, thrA)
    plt.title("Throughput usuario A (bits/s)")
    plt.xlabel("Tiempo (s)")
    plt.ylabel("Throughput (bits/s)")
    plt.grid(True)
    plt.tight_layout()
    plt.show()

    plt.figure(figsize=(12,4))
    plt.plot(delays)
    plt.title("Delay relativo A → B (segundos)")
    plt.xlabel("Índice de paquete")
    plt.ylabel("Delay (s)")
    plt.grid(True)
    plt.tight_layout()
    plt.show()

    print(f"[OK] Análisis completado.")
    print(f"   → Paquetes analizados A: {len(flowA)}")
    print(f"   → Paquetes analizados B: {len(flowB)}")
    print(f"   → Muestras de delay: {len(delays)}")
