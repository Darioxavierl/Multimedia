#!/bin/bash

# Cargar variables del archivo .env
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
else
    echo "Archivo .env no encontrado"
    exit 1
fi

# Validar variables necesarias
for v in TRACE_MODE DEST_IP UDP_PORT VIDEO_FILE OUTPUT_FILE; do
    if [ -z "${!v}" ]; then
        echo "La variable $v no está definida en .env"
        exit 1
    fi
done

# Ejecutar mp4trace con los parámetros desde .env
CMD="$HOME/evalvid/mp4trace $TRACE_MODE -s $DEST_IP $UDP_PORT $VIDEO_FILE"

echo "Ejecutando:"
echo "$CMD > $OUTPUT_FILE"
echo

$CMD > "$OUTPUT_FILE"

echo "Traza generada: $OUTPUT_FILE"
