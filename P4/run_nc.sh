#!/bin/bash

# Cargar variables del archivo .env
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
else
    echo "Archivo .env no encontrado"
    exit 1
fi

# Verificar que la variable este definida
if [ -z "$UDP_PORT" ]; then
    echo "La variable UDP_PORT no está definida en .env"
    exit 1
fi

echo "Escuchando UDP en el puerto $UDP_PORT ..."
nc -4 -l -u -d "$UDP_PORT"
