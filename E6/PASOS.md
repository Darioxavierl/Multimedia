# 1. PASOS DE TRANSMISION

## TRANSMISOR
1. Levantar el Docker con Samba para poder compartir los archivos entre nodos.
```
bash
sudo docker compose -f docker-compose.yml up -d
```
2. En la carpeta ```Tx/```, levantar el punto de acceso:
```
bash
./create_hotspot.sh
``` 
3. Esperar a que el Receptor se conecte, y este listo para recibir. Una vez este listo:
```
bash
./send_video.sh ./videos/100k/mobile_cif_100k.mp4 10.42.0.48 5000
```
4. Cuando se acaba la transmision, se guarda los PCAP, en el directorio ```./PCAP```
5. Esperar a aue el Receptor envie los archivos, poniendolos en el directorio con samba. Para prceder a obtener los dump files.

## RECEPTOR
1. En la carpeta ```Rx/```, conectarse al punto de acceso:
```
bash
./connect_hotspot.sh
```
2. Una vez conectado, prepararse para la recepcion:
```
bash
./receive_video.sh 100k 5000
```
3. Cuando se acaba la transmision, se guarda los PCAP, en el directorio ```./PCAP```
4. Copiar los PCAP al directorio usando el samba.

# 2. PASOS PARA OBTENER LOS DUMP FILE

1. Se ejecuta el script de Python que devuelve los dump file luego de analizar los PCAP.
```
bash
python3 pcap_analyzer.py Tx/PCAP/mobile_cif_100k.pcap Rx/PCAP/100k.pcap 10.42.0.1 10.42.0.48 ./Tx/dumps/100k_Tx_dump ./Rx/dumps/100k_Rx_dump -p 5000
```
Nota: los dump files se especifica la salida.

# 3. PASOS PARA RECONTRUIR LOS VIDEOS

1. Se ejecuta el script de reconstuccion:
```
bash
./rec_video.sh f ./Tx/dumps/100k_Tx_dump ./Rx/dumps/100k_Rx_dump ./Tx/trazas/mobile_cif_100k.f ./Tx/videos/100k/mobile_cif_100k ./Rx/videos_reconstruidos/mobile_cif_100k_rec
```

# 4. Analisis de PSNR

1. Se copia todos los archivos siguiendo la estructura de 40m/ 76m/, especialmente los videos recontruidos.
2. Se ejecuta el Script de bash para calcular PSNR.
```
bash
./calculate_psnr_new.sh 40m
```
3. Se ejecuta el script de Python para graficar el PSNR.
```
bash
 python3 ./psnr_new.py 40m
```

# 5. Reproduccion de videos
1. Para reproducir los videos:
```
bash
./play_videos.sh ./76m/videos/100k
``` 
