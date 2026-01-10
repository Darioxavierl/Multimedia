#!/bin/bash

# Script para cambiar el tema de colores
# Uso: ./change-theme.sh [default|green|red|dark]

THEME=${1:-default}
HTML_FILE="www/html/index.html"

echo "[+] Cambiando tema a: $THEME"
echo ""

case $THEME in
  "default")
    echo "[+] Aplicando tema por defecto (Morado/Azul)"
    sed -i 's/data-theme="[^"]*"//' "$HTML_FILE"
    sed -i 's/<body /<body /' "$HTML_FILE"
    ;;
    
  "green")
    echo "[+]Aplicando tema Verde"
    if grep -q 'data-theme=' "$HTML_FILE"; then
      sed -i 's/data-theme="[^"]*"/data-theme="green"/' "$HTML_FILE"
    else
      sed -i 's/<body>/<body data-theme="green">/' "$HTML_FILE"
    fi
    ;;
    
  "red")
    echo "[+] Aplicando tema Rojo"
    if grep -q 'data-theme=' "$HTML_FILE"; then
      sed -i 's/data-theme="[^"]*"/data-theme="red"/' "$HTML_FILE"
    else
      sed -i 's/<body>/<body data-theme="red">/' "$HTML_FILE"
    fi
    ;;
    
  "dark")
    echo "[+] Aplicando modo Oscuro"
    if grep -q 'data-theme=' "$HTML_FILE"; then
      sed -i 's/data-theme="[^"]*"/data-theme="dark"/' "$HTML_FILE"
    else
      sed -i 's/<body>/<body data-theme="dark">/' "$HTML_FILE"
    fi
    ;;
    
  *)
    echo "[+] Tema no válido"
    echo ""
    echo "Uso: ./change-theme.sh [default|green|red|dark]"
    echo ""
    echo "Temas disponibles:"
    echo "  default - Tema por defecto (Morado/Azul)"
    echo "  green   - Tema Verde"
    echo "  red     - Tema Rojo"
    echo "  dark    - Modo Oscuro"
    exit 1
    ;;
esac

echo ""
echo "[+] Tema aplicado!"
echo "[+] Recarga la página (Ctrl+F5) para ver los cambios"
echo ""
echo "[+] Para personalizar colores: edita www/html/css/variables.css"
