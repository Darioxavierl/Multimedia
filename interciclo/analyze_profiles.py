#!/usr/bin/env python3
import os
import numpy as np
import matplotlib.pyplot as plt
from scapy.all import rdpcap, UDP
from scipy.stats import t

# ---------------------------------------------------------------
# CONFIG
# ---------------------------------------------------------------
BASE_DIR = "mediciones"
PROFILES = ["cercano", "medio", "lejano"]
PORT = 39400


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
# COMPUTE IAT (delay)
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
def plot_with_mean(ax, x, y, title, ylabel, xlabel):
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
# ANOTACIÓN DE BOXPLOTS (Mediana, Q1, Q3, bigotes)
# ---------------------------------------------------------------
def annotate_boxplot(ax, bp):
    """
    Añade anotaciones:
    - Mediana
    - Q1 y Q3
    - Bigotes inferior y superior
    """

    # Medianas
    for median in bp['medians']:
        x, y = median.get_xydata()[1]
        ax.text(x, y, f"{y:.3f}", ha='center', va='bottom', color='blue')

    # Boxes: contienen Q1 y Q3
    for box in bp['boxes']:
        # Q1
        x_q1, y_q1 = box.get_xydata()[0]
        ax.text(x_q1, y_q1, f"Q1={y_q1:.3f}", ha='right', va='top', color='green')

        # Q3
        x_q3, y_q3 = box.get_xydata()[3]
        ax.text(x_q3, y_q3, f"Q3={y_q3:.3f}", ha='left', va='bottom', color='purple')

    # Bigotes
    whiskers = bp['whiskers']
    for i in range(0, len(whiskers), 2):
        # Whisker inferior
        w_low = whiskers[i]
        x_low, y_low = w_low.get_xydata()[1]
        ax.text(x_low, y_low, f"{y_low:.3f}", ha='center', va='top', color='cyan')

        # Whisker superior
        w_high = whiskers[i+1]
        x_high, y_high = w_high.get_xydata()[1]
        ax.text(x_high, y_high, f"{y_high:.3f}", ha='center', va='bottom', color='red')


# ---------------------------------------------------------------
# PROCESAR PERFIL
# ---------------------------------------------------------------
def process_profile(profile):
    results = {}
    for user in ["userA", "userB"]:
        pcap_path = os.path.join(BASE_DIR, user, profile, f"{profile}.pcap")
        ts, size = load_pcap(pcap_path, PORT)

        ts_norm = ts - ts[0]

        iat = compute_iat(ts_norm)
        iat_ms = iat * 1000

        t_thr, thr = compute_throughput(ts_norm, size)

        results[user] = {
            "iat": iat_ms,
            "thr": thr / 1e6,
        }

    return results


# ---------------------------------------------------------------
# MAIN
# ---------------------------------------------------------------
def main():
    profile_stats_thr = {}
    all_iat_A = []
    all_iat_B = []

    for profile in PROFILES:
        print(f"\nProcesando perfil: {profile}")
        results = process_profile(profile)

        # -------------------------
        # THROUGHPUT
        # -------------------------
        fig, ax = plt.subplots(1, 2, figsize=(14, 6))
        fig.suptitle(f"Throughput – Perfil: {profile}")

        plot_with_mean(ax[0], np.arange(len(results["userA"]["thr"])),
                       results["userA"]["thr"],
                       "User A", "Mbps", "Tiempo")

        plot_with_mean(ax[1], np.arange(len(results["userB"]["thr"])),
                       results["userB"]["thr"],
                       "User B", "Mbps", "Tiempo")

        plt.tight_layout()
        plt.show()

        # -------------------------
        # DELAY (IAT)
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

        all_iat_A.append(results["userA"]["iat"])
        all_iat_B.append(results["userB"]["iat"])

        # Estadísticas throughput
        thr_means, thr_cis = [], []
        for user in ["userA", "userB"]:
            m, ci = confidence_interval(results[user]["thr"])
            thr_means.append(m)
            thr_cis.append(ci)

        profile_stats_thr[profile] = (thr_means, thr_cis)

    # ===========================================================
    # BOXPLOTS DEL DELAY + ANOTACIONES
    # ===========================================================
    fig, ax = plt.subplots(1, 2, figsize=(14, 7))
    fig.suptitle("Distribución del Delay (IAT) – Boxplots por Perfil")

    # --- User A ---
    bpA = ax[0].boxplot(all_iat_A, tick_labels=PROFILES, showfliers=True)
    ax[0].set_title("User A")
    ax[0].set_ylabel("Delay (ms)")
    ax[0].set_yscale('log')
    ax[0].grid(axis='y')
    annotate_boxplot(ax[0], bpA)

    # --- User B ---
    bpB = ax[1].boxplot(all_iat_B, tick_labels=PROFILES, showfliers=True)
    ax[1].set_title("User B")
    ax[1].set_ylabel("Delay (ms)")
    ax[1].set_yscale('log')
    ax[1].grid(axis='y')
    annotate_boxplot(ax[1], bpB)

    plt.tight_layout()
    plt.show()


if __name__ == "__main__":
    main()
