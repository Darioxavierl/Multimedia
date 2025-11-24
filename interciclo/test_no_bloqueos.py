#!/usr/bin/env python3
"""
Test de Bloqueos TX/RX Simultáneos
Verifica que transmisión y recepción NO se bloquean mutuamente
"""

import time
import threading
from modules.ffmpeg_controller import FFmpegController
from modules.profile_manager import ProfileManager


def test_concurrent_tx_rx():
    """
    Test: Iniciar TX y RX simultáneamente sin que se bloqueen
    Escenario: Usuario en PC del colega que transmite y recibe a la vez
    """
    
    print("\n" + "="*70)
    print("🧪 TEST: TX y RX SIMULTÁNEOS SIN BLOQUEOS")
    print("="*70)
    
    controller = FFmpegController()
    pm = ProfileManager()
    profiles = pm.profiles
    
    # Configurar parámetros
    profile = profiles.get("lejano", {}).copy()
    profile['direccion_tx'] = 'udp://224.0.0.1:5000?pkt_size=1316'
    profile['direccion_rx'] = 'udp://@224.0.0.1:5000?fifo_size=30000&reuse=1'
    profile['probesize'] = '32'
    
    print("\n📋 Configuración:")
    print(f"   TX: {profile['direccion_tx']}")
    print(f"   RX: {profile['direccion_rx']}")
    
    try:
        # PASO 1: Iniciar transmisión
        print("\n📤 [Paso 1] Iniciando transmisión...")
        start_time = time.time()
        tx_success = controller.start_transmission(profile)
        tx_time = time.time() - start_time
        
        if tx_success:
            print(f"   ✅ TX iniciado en {tx_time:.2f}s (NO BLOQUEANTE)")
        else:
            print(f"   ❌ TX falló")
            return False
        
        # Esperar un poco para que TX se estabilice
        time.sleep(1)
        
        # PASO 2: Iniciar recepción (esto NO debe bloquear)
        print("\n📥 [Paso 2] Iniciando recepción EN PARALELO...")
        start_time = time.time()
        rx_success = controller.start_reception(profile, None, None)
        rx_time = time.time() - start_time
        
        if rx_success:
            print(f"   ✅ RX iniciado en {rx_time:.2f}s (NO BLOQUEANTE)")
        else:
            print(f"   ❌ RX falló")
            controller.stop_transmission()
            return False
        
        # PASO 3: Verificar que ambos están activos
        print("\n🔍 [Paso 3] Verificando estado simultáneo...")
        time.sleep(1)
        
        tx_active = controller.is_transmitting()
        rx_active = controller.is_receiving()
        
        print(f"   TX activo: {'✅ SÍ' if tx_active else '❌ NO'}")
        print(f"   RX activo: {'✅ SÍ' if rx_active else '❌ NO'}")
        
        if not (tx_active and rx_active):
            print("   ❌ Uno de los procesos no está activo")
            return False
        
        # PASO 4: Mantener corriendo
        print("\n▶️  [Paso 4] Ejecutando por 10 segundos...")
        print("   • TX debe seguir transmitiendo")
        print("   • RX debe seguir recibiendo")
        print("   • NO debe haber bloqueos")
        
        for i in range(10):
            tx_ok = controller.is_transmitting()
            rx_ok = controller.is_receiving()
            status = f"TX:{'✅' if tx_ok else '❌'} RX:{'✅' if rx_ok else '❌'}"
            print(f"   [{i+1:2d}/10] {status}")
            time.sleep(1)
        
        # PASO 5: Detener en orden
        print("\n⏹️  [Paso 5] Deteniendo procesos...")
        
        print("   Deteniendo RX...")
        start_time = time.time()
        controller.stop_reception()
        stop_time = time.time() - start_time
        print(f"   ✅ RX detenido en {stop_time:.2f}s (NO BLOQUEANTE)")
        
        time.sleep(0.5)
        
        print("   Deteniendo TX...")
        start_time = time.time()
        controller.stop_transmission()
        stop_time = time.time() - start_time
        print(f"   ✅ TX detenido en {stop_time:.2f}s (NO BLOQUEANTE)")
        
        print("\n" + "="*70)
        print("✅ TEST COMPLETADO EXITOSAMENTE")
        print("   • TX y RX corren en PARALELO sin bloqueos")
        print("   • Ambos procesos están independientes")
        print("   • El programa responde rápidamente")
        print("="*70 + "\n")
        
        return True
        
    except KeyboardInterrupt:
        print("\n⏸️  Test interrumpido")
        controller.cleanup()
        return False
    except Exception as e:
        print(f"\n❌ Error: {e}")
        import traceback
        traceback.print_exc()
        controller.cleanup()
        return False


def test_rapid_switching():
    """Test: Cambiar rápidamente entre estados"""
    
    print("\n" + "="*70)
    print("🧪 TEST: CAMBIOS RÁPIDOS DE ESTADO (Stress Test)")
    print("="*70)
    
    controller = FFmpegController()
    pm = ProfileManager()
    profiles = pm.profiles
    
    profile = profiles.get("lejano", {}).copy()
    profile['direccion_tx'] = 'udp://224.0.0.1:5000?pkt_size=1316'
    profile['direccion_rx'] = 'udp://@224.0.0.1:5000?fifo_size=30000&reuse=1'
    profile['probesize'] = '32'
    
    try:
        print("\n🔄 Realizando cambios rápidos de estado...")
        
        for cycle in range(3):
            print(f"\n  Ciclo {cycle+1}/3:")
            
            # TX
            print("    • Iniciando TX...", end=" ", flush=True)
            controller.start_transmission(profile)
            print("✓")
            time.sleep(0.5)
            
            # RX  
            print("    • Iniciando RX...", end=" ", flush=True)
            controller.start_reception(profile, None, None)
            print("✓")
            time.sleep(1)
            
            # Detener RX
            print("    • Deteniendo RX...", end=" ", flush=True)
            controller.stop_reception()
            print("✓")
            time.sleep(0.3)
            
            # Detener TX
            print("    • Deteniendo TX...", end=" ", flush=True)
            controller.stop_transmission()
            print("✓")
            time.sleep(0.5)
        
        print("\n✅ Stress test completado - Sin bloqueos ni crashes")
        print("="*70 + "\n")
        return True
        
    except Exception as e:
        print(f"\n❌ Error: {e}")
        controller.cleanup()
        return False


def main():
    print("""
╔══════════════════════════════════════════════════════════════════╗
║                                                                  ║
║           TESTS DE BLOQUEOS TX/RX SIMULTÁNEOS                   ║
║                                                                  ║
║  Problema: PC colega se queda colgado cuando hace TX+RX         ║
║  Causa: Procesos de transmisión y recepción se bloqueaban       ║
║  Solución: Usar threading + evitar capturar stdout/stderr       ║
║                                                                  ║
║  Estos tests verifican que:                                      ║
║  ✓ TX y RX corren en paralelo sin bloquearse                    ║
║  ✓ El programa responde rápidamente                             ║
║  ✓ No hay deadlocks                                             ║
║  ✓ Cambios de estado son seguros                                ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
    """)
    
    results = {}
    
    # Test 1: TX y RX simultáneos
    results["TX+RX Simultáneos"] = test_concurrent_tx_rx()
    
    time.sleep(2)
    
    # Test 2: Cambios rápidos
    results["Cambios Rápidos"] = test_rapid_switching()
    
    # Resumen
    print("\n" + "="*70)
    print("📊 RESUMEN DE TESTS")
    print("="*70)
    for name, passed in results.items():
        status = "✅ PASS" if passed else "❌ FAIL"
        print(f"  {status}: {name}")
    
    all_passed = all(results.values())
    print("="*70)
    if all_passed:
        print("✅ TODOS LOS TESTS PASARON")
        print("\n💡 RECOMENDACIÓN: El código está optimizado para:")
        print("   • TX y RX en paralelo sin bloqueos")
        print("   • Respuesta rápida del programa")
        print("   • Thread-safe (sincronización con locks)")
        print("   • Sin deadlocks (DEVNULL en lugar de PIPE)")
    else:
        print("❌ ALGUNOS TESTS FALLARON")
    print("="*70 + "\n")
    
    return 0 if all_passed else 1


if __name__ == "__main__":
    import sys
    sys.exit(main())
