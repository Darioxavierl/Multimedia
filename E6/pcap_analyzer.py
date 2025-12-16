#!/usr/bin/env python3
"""
Analizador de PCAP para EvalVid
Extrae paquetes UDP, valida sincronización y genera dump files
Ejecución:
    python3 pcap_analyzer.py <tx.pcap> <rx.pcap> <tx_ip> <rx_ip> <tx_dump_ruta_salida> <rx_dump_ruta_salida> -p <udp_port>
    python3 pcap_analyzer.py Tx/PCAP/tx.pcapng Rx/PCAP/rx.pcapng 10.42.0.245 10.42.0.1 ./Tx/tx_dump ./Rx/rx_dump -p 5000
"""

import sys
import argparse
from scapy.all import rdpcap, IP, UDP
from pathlib import Path
from collections import defaultdict


class PCAPAnalyzer:
    def __init__(self, pcap_tx, pcap_rx, ip_src, ip_dst, dump_tx="tx_dump", dump_rx="rx_dump", udp_port=5000):
        self.pcap_tx = pcap_tx
        self.pcap_rx = pcap_rx
        self.ip_src = ip_src
        self.ip_dst = ip_dst
        self.udp_port = udp_port
        self.dump_tx = Path(dump_tx)
        self.dump_rx = Path(dump_rx)
        
        # Crear directorios de salida si no existen
        self.dump_tx.parent.mkdir(parents=True, exist_ok=True)
        self.dump_rx.parent.mkdir(parents=True, exist_ok=True)
        
        self.packets_tx = []
        self.packets_rx = []
        
    def extract_packets(self, pcap_file, direction="tx"):
        """Extrae paquetes UDP del PCAP"""
        packets = []
        try:
            cap = rdpcap(pcap_file)
            print(f"✓ Cargado {pcap_file}: {len(cap)} paquetes totales")
        except Exception as e:
            print(f"✗ Error al cargar {pcap_file}: {e}")
            return packets
        
        for pkt in cap:
            if IP in pkt and UDP in pkt:
                # Validar que sea el tráfico correcto
                if (pkt[IP].src == self.ip_src and pkt[IP].dst == self.ip_dst and 
                    pkt[UDP].dport == self.udp_port):
                    
                    packets.append({
                        'timestamp': float(pkt.time),
                        'ip_id': pkt[IP].id,
                        'size': len(pkt[UDP].payload),
                        'packet': pkt
                    })
        
        # Ordenar por timestamp (orden cronológico real)
        packets.sort(key=lambda x: x['timestamp'])
        
        print(f"  → Paquetes UDP filtrados ({direction}): {len(packets)}")
        if packets:
            print(f"    Primer paquete (ts=orden): IP.id={packets[0]['ip_id']}, "
                  f"size={packets[0]['size']}, ts={packets[0]['timestamp']:.4f}")
        
        return packets
    
    def find_matching_packet_rx(self, tx_packet):
        """Busca el paquete Tx en Rx por tamaño de payload"""
        target_size = tx_packet['size']
        target_id = tx_packet['ip_id']
        
        # Buscar paquete con mismo tamaño en Rx
        for idx, rx_pkt in enumerate(self.packets_rx):
            if rx_pkt['size'] == target_size:
                print(f"✓ Paquete Tx encontrado en Rx:")
                print(f"  Tx: IP.id={target_id}, size={target_size}, ts={tx_packet['timestamp']:.4f}")
                print(f"  Rx: IP.id={rx_pkt['ip_id']}, size={rx_pkt['size']}, ts={rx_pkt['timestamp']:.4f}")
                print(f"  Diferencia de timestamps: {(rx_pkt['timestamp'] - tx_packet['timestamp']) * 1000:.2f} ms")
                return idx, rx_pkt
        
        print(f"⚠ Primer paquete Tx no encontrado en Rx (size={target_size})")
        return None, None
    
    def map_packets(self, packets, reference_id=None):
        """
        Mapea IPs IDs a secuencia 1,2,3...
        Asume que todos los paquetes están presentes (para Tx)
        """
        if not packets:
            return []
        
        # Ordena por timestamp (orden cronológico real)
        packets_sorted = sorted(packets, key=lambda x: x['timestamp'])
        
        print(f"  Primeros 15 paquetes (ordenados por timestamp):")
        
        mapped = []
        
        for i, pkt in enumerate(packets_sorted[:15]):
            print(f"    {i}: ts={pkt['timestamp']:.4f}, IP.id={pkt['ip_id']}, size={pkt['size']}")
        
        # Mostrar primeros 100 IPs IDs
        print(f"\n  Primeros 100 IP.ids (en orden cronológico):")
        ip_ids_list = [pkt['ip_id'] for pkt in packets_sorted[:100]]
        print(f"    {ip_ids_list}\n")
        
        # Mapear secuencialmente (sin detectar pérdidas)
        for seq_id, pkt in enumerate(packets_sorted, 1):
            mapped.append({
                'timestamp': pkt['timestamp'],
                'seq_id': seq_id,
                'ip_id': pkt['ip_id'],
                'size': pkt['size']
            })
        
        return mapped
    
    def map_packets_rx_with_tx_reference(self, packets_rx, mapped_tx):
        """
        Mapea paquetes Rx iterando sobre Tx
        Para cada IP.id en Tx:
        - ¿Existe en Rx? SÍ → agregar con mismo seq_id
        - ¿NO existe? → omitir (pérdida)
        """
        if not packets_rx:
            return []
        
        # Ordena Rx por timestamp
        packets_rx_sorted = sorted(packets_rx, key=lambda x: x['timestamp'])
        
        # Crear diccionario Rx: IP.id → paquete completo
        rx_map = {pkt['ip_id']: pkt for pkt in packets_rx_sorted}
        rx_ip_ids = set(rx_map.keys())
        
        print(f"  IPs IDs en Tx: {len(mapped_tx)}")
        print(f"  IPs IDs en Rx: {len(rx_ip_ids)}")
        print(f"  Primeros 15 paquetes Rx (ordenados por timestamp):")
        
        for i, pkt in enumerate(packets_rx_sorted[:15]):
            in_tx = "✓" if pkt['ip_id'] in {p['ip_id'] for p in mapped_tx} else "✗ ERROR"
            print(f"    {i}: ts={pkt['timestamp']:.4f}, IP.id={pkt['ip_id']}, size={pkt['size']} {in_tx}")
        
        # Mostrar primeros 100 IPs IDs de Rx
        print(f"\n  Primeros 100 IP.ids en Rx (en orden cronológico):")
        ip_ids_rx_list = [pkt['ip_id'] for pkt in packets_rx_sorted[:100]]
        print(f"    {ip_ids_rx_list}\n")
        
        # Iterar sobre Tx (en orden) y verificar si existen en Rx
        mapped = []
        lost_in_transit = []
        
        for tx_pkt in mapped_tx:
            ip_id = tx_pkt['ip_id']
            seq_id = tx_pkt['seq_id']
            
            if ip_id in rx_map:
                # Existe en Rx, agregar con el mismo seq_id de Tx
                rx_pkt = rx_map[ip_id]
                mapped.append({
                    'timestamp': rx_pkt['timestamp'],
                    'seq_id': seq_id,
                    'ip_id': ip_id,
                    'size': rx_pkt['size']
                })
            else:
                # NO existe en Rx, marcar como perdido
                lost_in_transit.append(ip_id)
        
        return mapped, lost_in_transit
    
    def generate_dump(self, mapped_packets, filepath):
        """Genera archivo dump en formato EvalVid"""
        filepath = Path(filepath)
        with open(filepath, 'w') as f:
            for pkt in mapped_packets:
                # Formato: timestamp id XXXXX protocol size
                line = f"{pkt['timestamp']:<12.4f} id {pkt['seq_id']:<6} udp {pkt['size']}\n"
                f.write(line)
        
        print(f"✓ Dump generado: {filepath}")
    
    def analyze(self):
        """Ejecuta análisis completo"""
        print("=" * 70)
        print("PCAP ANALYZER - EvalVid")
        print("=" * 70)
        print(f"Parámetros:")
        print(f"  Tx PCAP: {self.pcap_tx}")
        print(f"  Rx PCAP: {self.pcap_rx}")
        print(f"  IP origen: {self.ip_src}")
        print(f"  IP destino: {self.ip_dst}")
        print(f"  Puerto UDP: {self.udp_port}")
        print("")
        
        # Extraer paquetes
        print("Extrayendo paquetes...")
        self.packets_tx = self.extract_packets(self.pcap_tx, "tx")
        self.packets_rx = self.extract_packets(self.pcap_rx, "rx")
        
        if not self.packets_tx:
            print("✗ No hay paquetes UDP en Tx")
            return False
        
        if not self.packets_rx:
            print("✗ No hay paquetes UDP en Rx")
            return False
        
        print("")
        
        # Validar primer paquete
        print("Validando sincronización...")
        rx_idx, matching_rx = self.find_matching_packet_rx(self.packets_tx[0])
        
        if matching_rx is None:
            print("⚠ Usando primer paquete de Rx como referencia")
            reference_rx_id = self.packets_rx[0]['ip_id']
        else:
            reference_rx_id = matching_rx['ip_id']
        
        print("")
        
        # Mapear paquetes
        print("Mapeando secuencias...")
        mapped_tx = self.map_packets(self.packets_tx)
        
        # Para Rx, usar comparación con Tx (detecta pérdidas en transmisión)
        mapped_rx, lost_in_transit = self.map_packets_rx_with_tx_reference(self.packets_rx, mapped_tx)
        
        print(f"✓ Tx: {len(mapped_tx)} paquetes (todos presentes)")
        
        print(f"✓ Rx: {len(mapped_rx)} paquetes recibidos")
        print(f"  Paquetes perdidos en transmisión (Tx→Rx): {len(lost_in_transit)}")
        if lost_in_transit:
            print(f"    IPs IDs perdidos: {lost_in_transit[:20]}{'...' if len(lost_in_transit) > 20 else ''}")
        
        print("")
        print("=" * 70)
        
        # Generar dumps
        print("Generando dump files...")
        self.generate_dump(mapped_tx, self.dump_tx)
        self.generate_dump(mapped_rx, self.dump_rx)
        
        # Estadísticas
        print("")
        print("=" * 70)
        print("ESTADÍSTICAS")
        print("=" * 70)
        print(f"Tx total: {len(mapped_tx)} paquetes")
        print(f"Rx total: {len(mapped_rx)} paquetes")
        print(f"Pérdida en transmisión: {len(lost_in_transit)}/{len(mapped_tx)} ({100*len(lost_in_transit)/len(mapped_tx):.2f}%)")
        
        return True

def main():
    parser = argparse.ArgumentParser(
        description='Analiza PCAP de Tx y Rx para generar dump files EvalVid'
    )
    parser.add_argument('pcap_tx', help='Archivo PCAP de transmisión (Tx)')
    parser.add_argument('pcap_rx', help='Archivo PCAP de recepción (Rx)')
    parser.add_argument('ip_src', help='IP origen (Tx)')
    parser.add_argument('ip_dst', help='IP destino (Rx)')
    parser.add_argument('dump_tx', help='Ruta de salida para dump de Tx')
    parser.add_argument('dump_rx', help='Ruta de salida para dump de Rx')
    parser.add_argument('-p', '--port', type=int, default=5000,
                       help='Puerto UDP (default: 5000)')
    
    args = parser.parse_args()
    
    # Validar archivos
    if not Path(args.pcap_tx).exists():
        print(f"✗ Archivo no encontrado: {args.pcap_tx}")
        sys.exit(1)
    
    if not Path(args.pcap_rx).exists():
        print(f"✗ Archivo no encontrado: {args.pcap_rx}")
        sys.exit(1)
    
    # Ejecutar análisis
    analyzer = PCAPAnalyzer(args.pcap_tx, args.pcap_rx, args.ip_src, args.ip_dst, 
                           args.dump_tx, args.dump_rx, args.port)
    success = analyzer.analyze()
    
    sys.exit(0 if success else 1)
    sys.exit(0 if success else 1)


if __name__ == '__main__':
    main()
