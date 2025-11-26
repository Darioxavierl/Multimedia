#!/usr/bin/env python3
import os
import numpy as np
import matplotlib.pyplot as plt
from scapy.all import rdpcap, UDP
from scipy.stats import t

# ---------------------------------------------------------------
# CONFIG
# ---------------------------------------------------------------
BASE_DIR = "mediciones"   # Ruta base donde están userA/ y userB/
PROFILES = ["cercano", "medio", "lejano"]
PORT = 39400   # Cambia si necesario


# ---------------------------------------------------------------
# CARGA PCAP Y FILTRA POR UDP
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
# INTER-ARRIVAL TIME (Delay capturado)
# ---------------------------------------------------------------
def compute_iat(ts, discard_seconds=1.0):
    if len(ts) < 2:
        return np.array([])

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
        t0, t1 = bins[i], bins[i+1]
        mask = (ts >= t0) & (ts < t1)
        total_bytes = sizes[mask].sum()
        throughput.append(total_bytes * 8 / window)

    return bins[:-1], np.array(throughput)


# ---------------------------------------------------------------
# INTERVALO DE CONFIANZA 90%
# ---------------------------------------------------------------
def confidence_interval(data, confidence=0.90):
    if len(data) < 2:
        return 0, 0

    mean = np.mean(data)
    sem = np.std(data, ddof=1) / np.sqrt(len(data))
    t_val = t.ppf((1 + confidence) / 2, df=len(data)-1)
    return mean, t_val * sem


# ---------------------------------------------------------------
# GRAFICAR PROMEDIOS CON LÍNEA Y TEXTO
# ---------------------------------------------------------------
def plot_with_mean(ax, x, y, title, ylabel,xlabel):
    ax.plot(x, y, alpha=0.7)
    ax.set_title(title)
    ax.set_ylabel(ylabel)
    ax.set_xlabel(xlabel)
    ax.grid()

    if len(y) > 0:
        m = np.mean(y)
        ax.axhline(m, color='r', linestyle='--', linewidth=1.3)
        ax.text(x[len(x)//2], m, f"{m:.3f}", color='r')


# ---------------------------------------------------------------
# PROCESAR UN PERFIL ('cercano', 'medio', 'lejano')
# ---------------------------------------------------------------
def process_profile(profile):

    results = {}  # Para recopilar promedios globales

    for user in ["userA", "userB"]:

        pcap_path = os.path.join(BASE_DIR, user, profile, f"{profile}.pcap")
        ts, size = load_pcap(pcap_path, PORT)

        # Normalizar tiempo
        ts_norm = ts - ts[0]

        # Delay
        iat = compute_iat(ts_norm)
        iat_ms = iat * 1000

        # Throughput
        t_thr, thr = compute_throughput(ts_norm, size)

        results[user] = {
            "iat": iat_ms,
            "thr": thr/1e6,   # Mbps
        }

    return results


# ---------------------------------------------------------------
# MAIN
# ---------------------------------------------------------------
def main():
    profile_stats_thr = {}
    profile_stats_iat = {}

    for profile in PROFILES:
        print(f"\nProcesando perfil: {profile}")

        results = process_profile(profile)

        # -------------------------
        # FIGURA THROUGHPUT
        # -------------------------
        fig, ax = plt.subplots(1, 2, figsize=(14, 6))
        fig.suptitle(f"Throughput – Perfil: {profile}")

        plot_with_mean(ax[0], np.arange(len(results["userA"]["thr"])),
                       results["userA"]["thr"],
                       "User A", "Mbps","Tiempo")

        plot_with_mean(ax[1], np.arange(len(results["userB"]["thr"])),
                       results["userB"]["thr"],
                       "User B", "Mbps", "Tiempo")
        
        plt.tight_layout()
        plt.show()

        # -------------------------
        # FIGURA DELAY (IAT)
        # -------------------------
        fig, ax = plt.subplots(1, 2, figsize=(14, 6))
        fig.suptitle(f"Delay (IAT) – Perfil: {profile}")

        plot_with_mean(ax[0], np.arange(len(results["userA"]["iat"])),
                       results["userA"]["iat"],
                       "User A", "ms", "No. Paquetes")

        plot_with_mean(ax[1], np.arange(len(results["userB"]["iat"])),
                       results["userB"]["iat"],
                       "User B", "ms", "No. Paquetes")
    
        plt.tight_layout()
        plt.show()

        # -----------------------------------------------------
        # GUARDAR ESTADÍSTICAS PARA BARRAS + CI
        # -----------------------------------------------------
        thr_means = []
        thr_cis = []
        iat_means = []
        iat_cis = []

        for user in ["userA", "userB"]:
            m, ci = confidence_interval(results[user]["thr"])
            thr_means.append(m)
            thr_cis.append(ci)

            m2, ci2 = confidence_interval(results[user]["iat"])
            iat_means.append(m2)
            iat_cis.append(ci2)

        profile_stats_thr[profile] = (thr_means, thr_cis)
        profile_stats_iat[profile] = (iat_means, iat_cis)

    # ===========================================================
    # GRÁFICAS DE BARRAS + CI  (THROUGHPUT)
    # ===========================================================
    labels = PROFILES
    x = np.arange(len(labels))

    userA_means = [profile_stats_thr[p][0][0] for p in PROFILES]
    userA_err = [profile_stats_thr[p][1][0] for p in PROFILES]

    userB_means = [profile_stats_thr[p][0][1] for p in PROFILES]
    userB_err = [profile_stats_thr[p][1][1] for p in PROFILES]

    width = 0.35

    fig, ax = plt.subplots(figsize=(10, 6))
    ax.bar(x - width/2, userA_means, width, yerr=userA_err, label="User A", capsize=6)
    ax.bar(x + width/2, userB_means, width, yerr=userB_err, label="User B", capsize=6)

    ax.set_ylabel("Throughput (Mbps)")
    ax.set_title("Promedio + Intervalo de Confianza (90%) – Throughput")
    ax.set_xticks(x)
    ax.set_xticklabels(labels)
    ax.grid(axis='y')
    ax.legend()
    plt.show()

    # ===========================================================
    # GRÁFICAS DE BARRAS + CI  (DELAY)
    # ===========================================================
    userA_means = [profile_stats_iat[p][0][0] for p in PROFILES]
    userA_err = [profile_stats_iat[p][1][0] for p in PROFILES]

    userB_means = [profile_stats_iat[p][0][1] for p in PROFILES]
    userB_err = [profile_stats_iat[p][1][1] for p in PROFILES]

    fig, ax = plt.subplots(figsize=(10, 6))
    ax.bar(x - width/2, userA_means, width, yerr=userA_err, label="User A", capsize=6)
    ax.bar(x + width/2, userB_means, width, yerr=userB_err, label="User B", capsize=6)

    ax.set_ylabel("Delay (ms)")
    ax.set_title("Promedio + Intervalo de Confianza (90%) – Delay (IAT)")
    ax.set_xticks(x)
    ax.set_xticklabels(labels)
    ax.grid(axis='y')
    ax.legend()
    plt.show()


if __name__ == "__main__":
    main()
