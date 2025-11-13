# VideoConferencia P2P con FFmpeg

## Requisitos

```bash
sudo apt update
sudo apt install python3-pyqt6 ffmpeg
```

## Instalación

```bash
# Instalar PyQt6 si no está instalado
pip install PyQt6
```

## Configuración de Red Ad-Hoc
- Nota: Primero identificar interfaz inalambrica, para ejemplo (wlan0) 

Para conectar dos dispositivos Ubuntu en modo ad-hoc:

### Configuracion automatica
```bash
# Utilizar setup_bash.sh
./setup_bash.sh IP_ADRESS INTERFACE
```

### Dispositivo 1 (servidor):
```bash
# Desactivar NetworkManager en la interfaz
sudo nmcli device set wlan0 managed no

# Configurar ad-hoc
sudo ip link set wlan0 down
sudo iwconfig wlan0 mode ad-hoc
sudo iwconfig wlan0 essid "videoconf"
sudo iwconfig wlan0 channel 6
sudo ip link set wlan0 up
sudo ip addr add 192.168.1.1/24 dev wlan0
```

### Dispositivo 2 (cliente):
```bash
sudo nmcli device set wlan0 managed no
sudo ip link set wlan0 down
sudo iwconfig wlan0 mode ad-hoc
sudo iwconfig wlan0 essid "videoconf"
sudo iwconfig wlan0 channel 6
sudo ip link set wlan0 up
sudo ip addr add 192.168.1.2/24 dev wlan0
```

### Verificar conectividad:
```bash
ping 192.168.1.1  # desde dispositivo 2
ping 192.168.1.2  # desde dispositivo 1
```
### Restaurar interfaz:
```bash
sudo nmcli device set wlan0 managed yes
sudo systemctl restart NetworkManager
```

## Configuración de la Aplicación

### Direcciones para Ad-Hoc:

**Dispositivo 1 (192.168.1.1):**
- Dirección TX: `udp://192.168.1.2:39400` (envía al otro)
- Dirección RX: `udp://@:39400` (recibe en su puerto)

**Dispositivo 2 (192.168.1.2):**
- Dirección TX: `udp://192.168.1.1:39400` (envía al otro)
- Dirección RX: `udp://@:39400` (recibe en su puerto)

## Perfiles Incluidos

### Cercano (Alta Calidad)
- Resolución: 1920x1080
- FPS: 30
- Bitrate Video: 8000 kbps
- Bitrate Audio: 128 kbps
- **Uso**: Conexión ad-hoc directa, distancia corta

### Medio (Calidad Balanceada)
- Resolución: 1280x720
- FPS: 25
- Bitrate Video: 4000 kbps
- Bitrate Audio: 96 kbps
- **Uso**: Conexión con distancia moderada

### Lejano (Baja Latencia)
- Resolución: 854x480
- FPS: 15
- Bitrate Video: 1500 kbps
- Bitrate Audio: 64 kbps
- **Uso**: Conexión con señal débil o limitada

## Identificar Dispositivos

### Dispositivos de Video:
```bash
v4l2-ctl --list-devices
ls -l /dev/video*
```

### Dispositivos de Audio:
```bash
arecord -l
# Salida ejemplo: card 1: Device [USB Audio Device], device 0
# Usar como: hw:1,0
```


## Solución de Problemas

### Video no se muestra:
1. Verificar que ffplay esté instalado
2. Comprobar permisos en `/dev/video0`
3. Probar primero con: `ffplay udp://@:39400`

### Audio no funciona:
1. Verificar dispositivo: `arecord -l`
2. Probar con: `arecord -D hw:1,0 -d 5 test.wav`
3. Ajustar permisos del usuario en grupo `audio`

### Sin conexión en ad-hoc:
1. Verificar que ambos usen el mismo ESSID y canal
2. Desactivar firewall temporalmente: `sudo ufw disable`
3. Comprobar con `iwconfig` que el modo es ad-hoc

## Guardar Configuración Personalizada

Los perfiles se guardan automáticamente en:
```
~/.videoconf_profiles.json
```

Puedes editarse manualmente o usar el botón "Guardar Perfil" en la aplicación.

## Ejecución

```bash
python main.py
```

## Licencia

GPL v3