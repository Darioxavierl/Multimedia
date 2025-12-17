#!/usr/bin/env python3
"""Debug script to analyze PCAP structure"""

import sys
from scapy.all import rdpcap, IP, UDP, ARP, ICMP
from collections import defaultdict

if len(sys.argv) < 2:
    print("Usage: python3 debug_pcap.py <pcap_file>")
    sys.exit(1)

pcap_file = sys.argv[1]

try:
    cap = rdpcap(pcap_file)
    print(f"Total packets: {len(cap)}\n")
    
    # Estadísticas por protocolo
    protocols = defaultdict(int)
    ips = defaultdict(int)
    udp_ports = defaultdict(int)
    
    for pkt in cap:
        if IP in pkt:
            protocols['IP'] += 1
            ips[f"{pkt[IP].src} -> {pkt[IP].dst}"] += 1
            
            if UDP in pkt:
                protocols['UDP'] += 1
                udp_ports[f"{pkt[IP].src}:{pkt[UDP].sport} -> {pkt[IP].dst}:{pkt[UDP].dport}"] += 1
            elif ICMP in pkt:
                protocols['ICMP'] += 1
        elif ARP in pkt:
            protocols['ARP'] += 1
    
    print("=" * 70)
    print("PROTOCOLOS ENCONTRADOS:")
    print("=" * 70)
    for proto, count in sorted(protocols.items(), key=lambda x: x[1], reverse=True):
        print(f"  {proto}: {count}")
    
    print("\n" + "=" * 70)
    print("FLUJOS IP (primeros 10):")
    print("=" * 70)
    for flow, count in sorted(ips.items(), key=lambda x: x[1], reverse=True)[:10]:
        print(f"  {flow}: {count} paquetes")
    
    print("\n" + "=" * 70)
    print("FLUJOS UDP (primeros 10):")
    print("=" * 70)
    for flow, count in sorted(udp_ports.items(), key=lambda x: x[1], reverse=True)[:10]:
        print(f"  {flow}: {count} paquetes")
    
    print("\n" + "=" * 70)
    print("PRIMEROS 5 PAQUETES DETALLADOS:")
    print("=" * 70)
    for i, pkt in enumerate(cap[:5]):
        print(f"\nPaquete {i}:")
        pkt.show()
        
except Exception as e:
    print(f"Error: {e}")
    sys.exit(1)
