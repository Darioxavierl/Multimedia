# Configuración Cliente WiFi - Rx

## Descripción

Este directorio contiene los scripts para conectarse a un hotspot WiFi y sincronizar la hora mediante Chrony:

- **connect_hotspot.sh** - Conecta al hotspot y sincroniza con el servidor Tx
- **disconnect.sh** - Desconecta del hotspot y detiene Chrony
- **.env** - Configuración del cliente (editable)
- **config/chrony_rx.conf** - Configuración de Chrony como cliente

## 🔧 Requisitos previos

```bash
sudo apt update
sudo apt install chrony network-manager
```

## Configuración (.env)

Todos los parámetros de conexión están en el archivo `.env`:

```env
# Interfaz y red
WIFI_INTERFACE=wlan0
HOTSPOT_SSID=evalvid_lab
HOTSPOT_PASSWORD=12345678

# Servidor Tx
TX_SERVER_IP=192.168.12.1

# Timeouts (segundos)
DHCP_TIMEOUT=15
CHRONY_START_TIMEOUT=10
PING_ATTEMPTS=3
```

### Personalizar la configuración

Simplemente edita `.env`:

```bash
# Cambiar interfaz WiFi
WIFI_INTERFACE=wlan1

# Cambiar servidor Tx
TX_SERVER_IP=10.0.0.1

# Aumentar timeout de DHCP
DHCP_TIMEOUT=30
```

## Uso

### Opción 1: Con configuración desde .env (recomendado)

```bash
sudo ./connect_hotspot.sh
```

### Opción 2: Override de parámetros

```bash
sudo ./connect_hotspot.sh wlan1 mi_red 12345678 10.0.0.1
```

### Desconectar

```bash
sudo ./disconnect.sh
```

## Flujo de ejecución

1. **Carga configuración** desde `.env`
2. **Desconecta** conexiones previas
3. **Conecta** al hotspot WiFi
4. **Espera IP** del servidor DHCP
5. **Verifica reachability** del servidor Tx
6. **Genera configuración** de Chrony dinámicamente
7. **Inicia Chrony** como cliente
8. **Valida sincronización** con el servidor

## Verificación

```bash
# Ver estado de la conexión
nmcli device show wlan0

# Ver sincronización Chrony
chronyc tracking
chronyc sources -v

# Ver logs de sincronización
tail -f /tmp/chrony_rx_logs/measurements.log
```

## Parámetros avanzados

En `.env` puedes ajustar estos timeouts según tus necesidades:

| Variable | Valor por defecto | Descripción |
|----------|------------------|-------------|
| `DHCP_TIMEOUT` | 15s | Tiempo máximo para obtener IP |
| `CHRONY_START_TIMEOUT` | 10s | Tiempo para que inicie Chrony |
| `PING_ATTEMPTS` | 3 | Intentos de ping al servidor |
| `CONNECT_TIMEOUT` | 30s | Tiempo máximo para conectar |
| `RETRY_WAIT` | 2s | Espera entre reintentos |

## Estructura

```
Rx/
├── connect_hotspot.sh         # Script de conexión
├── disconnect.sh              # Script de desconexión
├── .env                       # Configuración (producción)
├── .env.example               # Plantilla de configuración
├── config/
│   └── chrony_rx.conf         # Configuración de Chrony cliente
└── README.md                  # Esta documentación
```

## Troubleshooting

**No se conecta al hotspot:**
- Verifica que el SSID es correcto en `.env`
- Comprueba que tienes cobertura WiFi
- Asegúrate de tener permisos de sudo

**No obtiene IP (timeout DHCP):**
- Aumenta `DHCP_TIMEOUT` en `.env` a 30s
- Verifica que el servidor Tx está activo
- Comprueba que dnsmasq está corriendo en Tx

**Chrony no sincroniza:**
- Verifica que `TX_SERVER_IP` es correcto
- Prueba `chronyc sources -v` para ver el estado
- Incrementa `CHRONY_START_TIMEOUT` en `.env`

**Interfaz WiFi no existe:**
- Lista interfaces: `nmcli device`
- Actualiza `WIFI_INTERFACE` en `.env`
