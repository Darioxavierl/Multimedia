#!/bin/bash


INPUT_DIR="$1"
# Archivo temporal
LOG_DIR="$2"

shopt -s nullglob
FILES=("$INPUT_DIR"/*.mp4)
if [ ${#FILES[@]} -eq 0 ]; then
  echo "No se encontraron archivos .mp4 en $INPUT_DIR"
  exit 1
fi

# Encabezado resumen
printf "\n%-25s %-10s %-10s %-10s %-10s\n" "Video" "GOP_Len_Prom" "I_Frames" "P_Frames" "B_Frames"
printf "%0.s-" {1..65}; echo


mkdir -p "$LOG_DIR"

for f in "${FILES[@]}"; do
  filename=$(basename -- "$f")
  log_file="$LOG_DIR/${filename%.mp4}_frames.log"

  echo -e "\n[+] Analizando GOP de: $filename"
  echo "   → Extrayendo tipos de frames con ffprobe..."

  # Guardar tipos de cuadros (I, P, B) en un log
  ffprobe -v error -select_streams v:0 -show_frames -show_entries frame=pict_type \
    -of csv=p=0 "$f" > "$log_file"

  if [ ! -s "$log_file" ]; then
    echo "   ✖ No se pudo obtener información de cuadros para $filename"
    continue
  fi

  # Contar total y tipos de frames
  total_frames=$(wc -l < "$log_file")
  count_I=$(grep -c "^I" "$log_file")
  count_P=$(grep -c "^P" "$log_file")
  count_B=$(grep -c "^B" "$log_file")

  echo "   → Total frames: $total_frames"
  echo "   → I: $count_I | P: $count_P | B: $count_B"

  # Calcular longitudes de GOP
  gop_lengths=()
  current_gop=0
  avg_gop_len=0
  gop_count=0

  # Leer línea por línea con grep y awk
  while read -r type; do
    ((current_gop++))
    if [ "$type" == "I" ]; then
      if [ $current_gop -gt 1 ]; then
        gop_lengths+=($((current_gop - 1)))
        ((gop_count++))
        current_gop=1
      fi
    fi
  done < "$log_file"

  # Añadir último GOP
  gop_lengths+=($current_gop)
  ((gop_count++))

  # Sumar y calcular promedio
  total_len=0
  for len in "${gop_lengths[@]}"; do
    ((total_len += len))
  done

  if [ $gop_count -gt 0 ]; then
    avg_gop_len=$(awk -v s="$total_len" -v n="$gop_count" 'BEGIN {printf "%.1f", s/n}')
  else
    avg_gop_len="N/A"
  fi

  echo "   → Promedio longitud GOP: $avg_gop_len"

  # Guardar en arreglo para resumen
  echo "$filename,$avg_gop_len,$count_I,$count_P,$count_B" >> "$LOG_DIR/summary_tmp.csv"
done

# Mostrar tabla resumen final
echo -e "\nResumen final:"
printf "%-25s %-10s %-10s %-10s %-10s\n" "Video" "GOP_Len" "I_Frames" "P_Frames" "B_Frames"
printf "%0.s-" {1..65}; echo

while IFS=',' read -r name gop i p b; do
  printf "%-25s %-10s %-10s %-10s %-10s\n" "$name" "$gop" "$i" "$p" "$b"
done < "$LOG_DIR/summary_tmp.csv"

# Exportar CSV final ordenado
sort "$LOG_DIR/summary_tmp.csv" > "$LOG_DIR/gop_summary.csv"
rm -f "$LOG_DIR/summary_tmp.csv"

echo -e "\n✔ Tabla exportada a: $LOG_DIR/gop_summary.csv"