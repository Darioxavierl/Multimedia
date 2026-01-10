#!/bin/bash

# Script para reconstruir el contenedor backend
# Uso: ./rebuild.sh

set -e  # Salir si hay errores

echo "[+] Reconstruyendo contenedor backend..."
echo ""

# Ir al directorio del proyecto
cd "$(dirname "$0")"

# Detener el contenedor backend
echo "[+] Deteniendo contenedor backend..."
sudo docker compose stop backend

# Reconstruir y levantar el backend
echo "[+]Reconstruyendo imagen..."
sudo docker compose up -d --build backend

# Verificar estado
echo ""
echo "[+]Verificando estado..."
sudo docker compose ps backend

echo ""
echo "[+] ¡Backend reconstruido exitosamente!"
echo ""
echo "[+] Ver logs: sudo docker compose logs -f backend"
echo "[+] Ver todos los contenedores: sudo docker compose ps"
