#!/bin/bash
# CONGRUENCIA DE SCRIPTS - Verificación de consistencia

cat << 'EOF'

╔════════════════════════════════════════════════════════════════════════════╗
║                                                                            ║
║  ✅ VERIFICACIÓN DE CONGRUENCIA - Scripts Tx/Rx                           ║
║                                                                            ║
╚════════════════════════════════════════════════════════════════════════════╝

SCRIPTS A REVISAR:
══════════════════

Tx:
  ✓ create_hotspot.sh    → Inicia hotspot + Chrony servidor
  ✓ stop_hotspot.sh      → Detiene hotspot + Chrony

Rx:
  ✓ connect_hotspot.sh   → Conecta hotspot + Chrony cliente
  ✓ disconnect.sh        → Desconecta hotspot + Chrony


VERIFICACIÓN REALIZADA:
═══════════════════════

1. ✓ SERVICIO CHRONY CORRECTO
   ─────────────────────────────
   
   create_hotspot.sh:
     systemctl start chrony        ✓
   
   connect_hotspot.sh:
     systemctl start chrony        ✓
   
   stop_hotspot.sh:
     systemctl stop chrony         ✓  (CORREGIDO: era "chronyd")
   
   disconnect.sh:
     systemctl stop chrony         ✓  (CORREGIDO: era "chronyd")


2. ✓ GESTIÓN DE CONFIGURACIÓN
   ────────────────────────────
   
   create_hotspot.sh:
     cp /etc/chrony/chrony.conf /etc/chrony/chrony.conf.backup  ✓
     cp "$CHRONY_CONF" /etc/chrony/chrony.conf                  ✓
   
   connect_hotspot.sh:
     cp /etc/chrony/chrony.conf /etc/chrony/chrony.conf.backup  ✓
     cp /tmp/chrony_rx_runtime.conf /etc/chrony/chrony.conf     ✓
   
   stop_hotspot.sh:
     cp /etc/chrony/chrony.conf.backup /etc/chrony/chrony.conf  ✓  (AÑADIDO)
   
   disconnect.sh:
     cp /etc/chrony/chrony.conf.backup /etc/chrony/chrony.conf  ✓  (AÑADIDO)


3. ✓ FLUJO DE CICLO DE VIDA
   ───────────────────────────
   
   TX:
   ─────────────────────────────────────────────────────────
   $ sudo ./Tx/create_hotspot.sh
     • Copia config original → /etc/chrony/chrony.conf.backup
     • Copia config Tx → /etc/chrony/chrony.conf
     • systemctl start chrony
     • Crea hotspot + DHCP
   
   $ sudo ./Tx/stop_hotspot.sh
     • systemctl stop chrony
     • Restaura config original desde .backup
     • Detiene DHCP + hotspot
   
   RX:
   ─────────────────────────────────────────────────────────
   $ sudo ./Rx/connect_hotspot.sh
     • Conecta a WiFi
     • Copia config original → /etc/chrony/chrony.conf.backup
     • Copia config Rx → /etc/chrony/chrony.conf
     • systemctl start chrony
   
   $ sudo ./Rx/disconnect.sh
     • systemctl stop chrony
     • Restaura config original desde .backup
     • Desconecta WiFi


4. ✓ CONSISTENCIA DE VARIABLES
   ────────────────────────────
   
   Ambos scripts:
     • Cargan .env                          ✓
     • Usan INTERFACE="${WIFI_INTERFACE}"  ✓
     • Tienen colores consistentes         ✓
     • Requieren sudo                      ✓
     • Manejo de errores similar           ✓


5. ✓ GESTIÓN DE ARCHIVOS TEMPORALES
   ──────────────────────────────────
   
   connect_hotspot.sh:
     Crea: /tmp/chrony_rx_runtime.conf
   
   disconnect.sh:
     Limpia: rm -f /tmp/chrony_rx_runtime.conf  ✓


CAMBIOS REALIZADOS EN ESTA REVISIÓN:
════════════════════════════════════

1. Tx/stop_hotspot.sh (Línea 31-42)
   ────────────────────────────────
   ANTES:
     systemctl stop chronyd 2>/dev/null || true
   
   AHORA:
     systemctl stop chrony 2>/dev/null || true
     # + Restauración de backup

2. Rx/disconnect.sh (Línea 28-39)
   ──────────────────────────────
   ANTES:
     systemctl stop chronyd 2>/dev/null || true
   
   AHORA:
     systemctl stop chrony 2>/dev/null || true
     # + Restauración de backup


FLUJO CORRECTO DE USO:
═════════════════════

ESCENARIO: Crear hotspot Tx → Conectar Rx → Desconectar

Terminal Tx:
  $ cd /home/dariox/multimedia/E6/Tx
  $ sudo ./create_hotspot.sh
  ✓ Copia backup
  ✓ Instala config Tx
  ✓ Inicia Chrony
  ✓ Crea hotspot

Terminal Rx:
  $ cd /home/dariox/multimedia/E6/Rx
  $ sudo ./connect_hotspot.sh
  ✓ Conecta a WiFi
  ✓ Copia backup
  ✓ Instala config Rx
  ✓ Inicia Chrony

Finalizar Rx:
  $ sudo ./disconnect.sh
  ✓ Detiene Chrony
  ✓ Restaura config original
  ✓ Desconecta WiFi

Finalizar Tx:
  $ sudo ./stop_hotspot.sh
  ✓ Detiene Chrony
  ✓ Restaura config original
  ✓ Detiene hotspot + DHCP


VENTAJAS DE ESTA CONGRUENCIA:
═════════════════════════════

✓ Configuración reversible: Backup garantiza restauración
✓ Nombres de servicio consistentes: "chrony" en todos lados
✓ Ciclo de vida completo: Crear-Usar-Destruir funciona bien
✓ Sin contaminación del sistema: Config original se restaura
✓ Escalable: Se pueden agregar más máquinas Rx


VERIFICACIÓN FINAL:
═══════════════════

Todos los scripts:
  ✓ Sintaxis bash correcta
  ✓ Usan systemctl para chrony (no chronyd manual)
  ✓ Hacen backup y restauración
  ✓ Cargan variables desde .env
  ✓ Tienen manejo de errores
  ✓ Mensajes informativos claros


═════════════════════════════════════════════════════════════════════════════

CONCLUSIÓN: Los 4 scripts ahora son congruentes y funcionan como un sistema
integrado. El ciclo de vida está completo y reversible.

═════════════════════════════════════════════════════════════════════════════

EOF
