# Configuración Tx - Servidor WiFi Hotspot + Chrony

##  Descripción

Este directorio contiene los scripts y configuración para iniciar un servidor:
- **Hotspot WiFi** con pool DHCP configurable
- **Chrony** como servidor NTP (sincronización horaria)

## 🔧 Requisitos previos

```bash
sudo apt update
sudo apt install chrony dnsmasq network-manager
```

##  Configuración (.env)

El archivo `.env` contiene todas las variables de configuración:

```env
# Red WiFi
WIFI_INTERFACE=wlan0
HOTSPOT_SSID=evalvid_lab
HOTSPOT_PASSWORD=12345678

# Pool DHCP
GATEWAY_IP=192.168.12.1       # IP del servidor Tx
NETWORK_MASK=24                # /24 = 255.255.255.0
DHCP_START=192.168.12.2        # Primera IP del cliente
DHCP_END=192.168.12.254        # Última IP del cliente
DHCP_LEASE=3600                # Duración del lease en segundos
```

### Personalizar la configuración

Para cambiar el pool de direcciones o cualquier otra opción:

1. Edita el archivo `.env`
2. Modifica los valores según necesites
3. Ejecuta el script - cargará automáticamente la nueva configuración

**Ejemplo: usar red 10.0.0.0/24**
```env
GATEWAY_IP=10.0.0.1
NETWORK_MASK=24
DHCP_START=10.0.0.2
DHCP_END=10.0.0.254
```

## Uso

### Opción 1: Con configuración desde .env (recomendado)

```bash
sudo ./create_hotspot.sh
```

El script cargará automáticamente todas las variables desde `.env`.

### Opción 2: Override de parámetros

```bash
sudo ./create_hotspot.sh wlan1 mi_red 12345678
```

Nota: El pool DHCP seguirá siendo el del `.env`.

## Flujo de ejecución

1. **Carga de configuración** desde `.env`
2. **Inicia Chrony** como servidor NTP
3. **Crea el hotspot WiFi** con nmcli
4. **Configura IP estática** (GATEWAY_IP)
5. **Inicia DHCP** con dnsmasq
6. **Valida** que todo esté operativo

## Verificación

Después de ejecutar el script:

```bash
# Ver estado del hotspot
nmcli device show wlan0

# Ver DHCP activo
ps aux | grep dnsmasq

# Ver Chrony operativo
chronyc tracking
chronyc sources -v
```

## Conectar desde Rx

Para que el cliente Rx se conecte y sincronice:

```bash
cd ../Rx
sudo ./connect_hotspot.sh wlan0 evalvid_lab 12345678 192.168.12.1
```

Donde `192.168.12.1` es el `GATEWAY_IP` del Tx.

## Estructura

```
Tx/
├── create_hotspot.sh        # Script principal
├── .env                     # Configuración (copia de producción)
├── .env.example             # Plantilla de configuración
├── config/
│   └── chrony_tx.conf       # Configuración de Chrony servidor
└── README.md                # Esta documentación
```

## Notas importantes

- El script requiere **sudo** para ejecutarse
- Si **dnsmasq** no está instalado, el hotspot se creará pero sin DHCP
- El archivo `.env` es local a cada máquina (no versionado en git)
- Se pueden editar los valores en `.env` en cualquier momento entre ejecuciones

## Troubleshooting

**El hotspot no se crea:**
- Verifica que la interfaz WiFi existe: `nmcli device`
- Asegúrate de tener permisos de sudo

**El DHCP no funciona:**
- Instala dnsmasq: `sudo apt install dnsmasq`
- Verifica: `sudo systemctl status dnsmasq`

**Chrony no inicia:**
- Verifica que el puerto 323 no está en uso: `sudo lsof -i :323`
- Revisa el archivo de configuración: `cat config/chrony_tx.conf`
