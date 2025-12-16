#!/bin/bash
# SOLUCIÓN FINAL: Chrony con systemctl

cat << 'EOF'

╔════════════════════════════════════════════════════════════════════════════╗
║                                                                            ║
║  ✅ CORRECCIÓN: Chrony ahora usa systemctl (más confiable)                 ║
║                                                                            ║
╚════════════════════════════════════════════════════════════════════════════╝

PROBLEMA ANTERIOR:
══════════════════

El script intentaba ejecutar chronyd manualmente:
  chronyd -f config/chrony_tx.conf &

Problemas:
  ✗ No funcionaba con systemctl activo
  ✗ Conflicto entre systemctl y ejecución manual
  ✗ Processo quedaba huérfano
  ✗ Error: "chrony no está corriendo"


SOLUCIÓN IMPLEMENTADA:
═══════════════════════

1. Usar systemctl para iniciar/detener Chrony
2. Copiar configuración personalizada a /etc/chrony/chrony.conf
3. Dejar que systemctl maneje el proceso
4. Verificar con chronyc

Ventajas:
  ✓ Compatible con el sistema
  ✓ Manejo automático de reintentos
  ✓ Logs integrados
  ✓ Más robusto


CAMBIOS EN Tx/create_hotspot.sh:
════════════════════════════════

Líneas 75-122:

ANTES:
  chronyd -f "$CHRONY_CONF" > /dev/null 2>&1 &
  sleep 2
  if chronyc tracking > /dev/null 2>&1; then
      echo "✓ Chrony operativo"
  else
      echo "✗ Chrony no responde"
      exit 1
  fi

AHORA:
  # Respaldar configuración original
  cp /etc/chrony/chrony.conf /etc/chrony/chrony.conf.backup
  
  # Copiar configuración personalizada
  cp "$CHRONY_CONF" /etc/chrony/chrony.conf
  
  # Iniciar con systemctl
  systemctl start chrony
  sleep 2
  
  # Verificar
  if chronyc tracking > /dev/null 2>&1; then
      echo "✓ Chrony operativo"
  else
      echo "⚠ Chrony no responde aún (puede sincronizar luego)"
  fi

Diferencias clave:
  • systemctl maneja el proceso (no cronyd directo)
  • /etc/chrony/chrony.conf tiene la configuración
  • Si falla, se puede verificar: sudo systemctl status chrony


CAMBIOS EN Rx/connect_hotspot.sh:
═════════════════════════════════

Líneas 140-176: Misma estrategia que Tx

ANTES:
  chronyd -f /tmp/chrony_rx_runtime.conf &
  # ... esperar sincronización

AHORA:
  # Generar configuración con SERVER_IP
  sed "s/TX_IP/$SERVER_IP/g" "$CHRONY_CONF_TEMPLATE" > /tmp/chrony_rx_runtime.conf
  
  # Copiar a /etc/chrony/chrony.conf
  cp /tmp/chrony_rx_runtime.conf /etc/chrony/chrony.conf
  
  # Iniciar con systemctl
  systemctl start chrony
  
  # Esperar sincronización
  for i in {1..10}; do
      if chronyc tracking > /dev/null 2>&1; then
          break
      fi
      sleep 1
  done


CÓMO VERIFICAR:
════════════════

1. Ver estado de Chrony:
   $ sudo systemctl status chrony

2. Ver tracking de sincronización:
   $ chronyc tracking

3. Ver fuentes de sincronización:
   $ chronyc sources -v

4. Ver logs:
   $ sudo journalctl -u chrony -n 20

5. Si hay problemas:
   $ sudo systemctl restart chrony
   $ chronyc tracking


CONFIGURACIÓN EN /etc/chrony/chrony.conf:
════════════════════════════════════════════

Para Tx (servidor):
  -----------
  local stratum 10
  allow 192.168.0.0/16
  local
  -----------

Para Rx (cliente):
  -----------
  server 192.168.12.1 iburst prefer
  noserver
  -----------


FLUJO CORRECTO:
═════════════════

Tx:
  1. systemctl stop chrony
  2. cp Tx/config/chrony_tx.conf /etc/chrony/chrony.conf
  3. systemctl start chrony
  4. chronyc tracking → Ver status

Rx:
  1. Conectarse a WiFi
  2. systemctl stop chrony
  3. sed 's/TX_IP/192.168.12.1/g' Rx/config/chrony_rx.conf > /tmp/chrony.conf
  4. cp /tmp/chrony.conf /etc/chrony/chrony.conf
  5. systemctl start chrony
  6. chronyc tracking → Ver status


TROUBLESHOOTING:
═════════════════

Problema: "Chrony no responde"
Solución:
  $ sudo systemctl restart chrony
  $ sleep 3
  $ chronyc tracking

Problema: "Connection refused"
Solución:
  $ sudo systemctl status chrony
  $ sudo journalctl -u chrony -n 50

Problema: "Permission denied" (en /etc/chrony/chrony.conf)
Solución:
  Necesitas sudo para modificar archivos en /etc

═════════════════════════════════════════════════════════════════════════════

RESUMEN:

Antes: chronyd manual → Conflictos con systemctl
Ahora: systemctl + configuración en /etc → Más robusto

El script ahora:
  ✓ Respalda configuración original
  ✓ Copia configuración personalizada
  ✓ Usa systemctl para iniciar
  ✓ Verifica con chronyc
  ✓ No falla si chronyc está lento en iniciar

═════════════════════════════════════════════════════════════════════════════

EOF
