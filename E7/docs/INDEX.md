# Índice de Documentación

**Sistema de Streaming Adaptativo DASH**  
**Universidad de Cuenca - Ingeniería en Telecomunicaciones**

## Documentos Disponibles

### Documentación Principal

#### [README.md](../README.md)
Documento principal del proyecto que incluye:
- Descripción general del sistema
- Arquitectura y componentes
- Guía de inicio rápido
- API Backend
- Resumen de configuración y temas
- Resolución de problemas básicos
- Información académica del proyecto

**Audiencia**: Usuarios generales, instructores, evaluadores  
**Complejidad**: Básica a intermedia

---

### Documentación Técnica Detallada

#### [docs/README.md](README.md)
Documentación técnica completa y exhaustiva:
- Arquitectura del sistema en profundidad
- Descripción detallada de cada componente
- Instalación paso a paso
- Configuración avanzada
- Uso completo de la interfaz
- Troubleshooting extensivo
- Referencias técnicas

**Audiencia**: Desarrolladores, administradores de sistemas  
**Complejidad**: Intermedia a avanzada

---

### Guías Especializadas

#### [docs/CONFIGURACION.md](CONFIGURACION.md)
Guía integral de configuración y ajuste:

**Contenido**:
1. Parámetros de FFmpeg (codificación, bitrate, DASH)
2. Parámetros de Shaka Player (buffering, streaming, ABR)
3. Optimización de latencia (ultra rápida, balanceada, ultra estable)
4. Solución de cortes (diagnóstico, orden de ajustes, casos específicos)
5. Configuraciones predefinidas (características, uso)
6. Procedimiento de ajuste (metodología, pasos detallados)
7. Monitoreo y métricas

**Audiencia**: Desarrolladores, ingenieros de optimización  
**Complejidad**: Avanzada  
**Uso**: Cuando se necesita ajustar rendimiento, resolver problemas de cortes, o personalizar latencia

---

#### [docs/TEMAS.md](TEMAS.md)
Sistema de temas y personalización visual:

**Contenido**:
1. Arquitectura del sistema de temas
2. Variables CSS disponibles (colores, espaciado, sombras, etc.)
3. Temas predefinidos (Default, Green, Red, Dark)
4. Uso del sistema (manual, script, dinámico)
5. Personalización de temas existentes
6. Creación de nuevos temas (paso a paso, ejemplos completos)
7. Integración con UI
8. Troubleshooting de temas

**Audiencia**: Diseñadores, desarrolladores frontend  
**Complejidad**: Intermedia  
**Uso**: Cuando se necesita personalizar apariencia, crear temas corporativos, o modificar UI

---

## Navegación Rápida por Temas

### Para Iniciar el Sistema
- [Inicio Rápido](../README.md#inicio-rápido) → README principal
- [Instalación](README.md#instalación) → docs/README.md

### Para Entender la Arquitectura
- [Arquitectura del Sistema](../README.md#arquitectura-del-sistema) → README principal (resumen)
- [Arquitectura Técnica](README.md#arquitectura-técnica) → docs/README.md (detallada)

### Para Configurar y Optimizar
- [Configuración y Ajuste](../README.md#configuración-y-ajuste) → README principal (resumen)
- [Parámetros FFmpeg](CONFIGURACION.md#parámetros-de-ffmpeg) → docs/CONFIGURACION.md
- [Parámetros Shaka](CONFIGURACION.md#parámetros-de-shaka-player) → docs/CONFIGURACION.md
- [Optimización de Latencia](CONFIGURACION.md#optimización-de-latencia) → docs/CONFIGURACION.md
- [Solución de Cortes](CONFIGURACION.md#solución-de-cortes) → docs/CONFIGURACION.md

### Para Personalizar Apariencia
- [Sistema de Temas](../README.md#sistema-de-temas) → README principal (resumen)
- [Variables CSS](TEMAS.md#variables-css-disponibles) → docs/TEMAS.md
- [Temas Predefinidos](TEMAS.md#temas-predefinidos) → docs/TEMAS.md
- [Crear Nuevos Temas](TEMAS.md#creación-de-nuevos-temas) → docs/TEMAS.md

### Para Resolver Problemas
- [Resolución de Problemas](../README.md#resolución-de-problemas) → README principal
- [Troubleshooting](README.md#troubleshooting) → docs/README.md
- [Solución de Cortes](CONFIGURACION.md#solución-de-cortes) → docs/CONFIGURACION.md
- [Troubleshooting Temas](TEMAS.md#troubleshooting) → docs/TEMAS.md

### Para API y Desarrollo
- [API Backend](../README.md#api-backend) → README principal
- [API Reference](README.md#api-reference) → docs/README.md
- [Desarrollo](README.md#desarrollo) → docs/README.md

---

## Flujo de Lectura Recomendado

### Para Nuevos Usuarios
1. [README.md](../README.md) → Entender el proyecto
2. [Inicio Rápido](../README.md#inicio-rápido) → Levantar el sistema
3. [Resolución de Problemas](../README.md#resolución-de-problemas) → Si hay issues

### Para Desarrolladores
1. [README.md](../README.md) → Visión general
2. [docs/README.md](README.md) → Arquitectura técnica completa
3. [docs/CONFIGURACION.md](CONFIGURACION.md) → Optimización y ajuste
4. [docs/TEMAS.md](TEMAS.md) → Personalización UI

### Para Optimización de Rendimiento
1. [Arquitectura del Sistema](../README.md#arquitectura-del-sistema) → Entender flujo
2. [Configuración y Ajuste](CONFIGURACION.md) → Leer completo
3. [Procedimiento de Ajuste](CONFIGURACION.md#procedimiento-de-ajuste) → Seguir metodología

### Para Personalización Visual
1. [Sistema de Temas](../README.md#sistema-de-temas) → Entender sistema
2. [docs/TEMAS.md](TEMAS.md) → Leer completo
3. [Creación de Nuevos Temas](TEMAS.md#creación-de-nuevos-temas) → Implementar

---

## Comandos y Scripts

### Scripts Disponibles

| Script | Descripción | Documento de Referencia |
|--------|-------------|-------------------------|
| `./rebuild.sh` | Reconstruir backend | [README.md](../README.md#scripts-útiles) |
| `./change-theme.sh [tema]` | Cambiar tema | [TEMAS.md](TEMAS.md#cambio-con-script) |
| `./test-config.sh [config]` | Ver configuración | [CONFIGURACION.md](CONFIGURACION.md#configuraciones-predefinidas) |

### Comandos Docker

| Comando | Descripción | Documento de Referencia |
|---------|-------------|-------------------------|
| `sudo docker compose up -d --build` | Iniciar sistema | [README.md](../README.md#inicio-rápido) |
| `sudo docker compose down` | Detener sistema | [README.md](../README.md#inicio-rápido) |
| `sudo docker compose logs -f backend` | Ver logs backend | [README.md](../README.md#inicio-rápido) |
| `sudo docker stats` | Monitorear recursos | [README.md](../README.md#monitoreo-del-sistema) |

---

## Archivos de Configuración

| Archivo | Propósito | Documento de Referencia |
|---------|-----------|-------------------------|
| `configs/ffmpeg-ultra-estable.txt` | Configuración FFmpeg estable | [CONFIGURACION.md](CONFIGURACION.md#ultra-estable) |
| `configs/ffmpeg-ultra-rapido.txt` | Configuración FFmpeg rápida | [CONFIGURACION.md](CONFIGURACION.md#ultra-rápida) |
| `configs/video-player-ultra-estable.js` | Configuración Shaka estable | [CONFIGURACION.md](CONFIGURACION.md#ultra-estable) |
| `configs/video-player-ultra-rapido.js` | Configuración Shaka rápida | [CONFIGURACION.md](CONFIGURACION.md#ultra-rápida) |
| `www/html/css/variables.css` | Variables CSS y temas | [TEMAS.md](TEMAS.md#arquitectura-del-sistema-de-temas) |

---

## Glosario de Términos

| Término | Significado | Documento de Referencia |
|---------|-------------|-------------------------|
| DASH | Dynamic Adaptive Streaming over HTTP | [README.md](README.md) |
| MPD | Media Presentation Description (manifiesto DASH) | [CONFIGURACION.md](CONFIGURACION.md) |
| ABR | Adaptive Bitrate (bitrate adaptativo) | [CONFIGURACION.md](CONFIGURACION.md#parámetros-abr-adaptive-bitrate) |
| GOP | Group of Pictures (grupo de fotogramas) | [CONFIGURACION.md](CONFIGURACION.md#g-gop-size) |
| CBR | Constant Bitrate (bitrate constante) | [CONFIGURACION.md](CONFIGURACION.md#bv-bitrate) |
| VBV | Video Buffering Verifier | [CONFIGURACION.md](CONFIGURACION.md#bufsize) |
| CSS Variables | CSS Custom Properties | [TEMAS.md](TEMAS.md#variables-css-disponibles) |

---

## Referencias Externas

### Documentación Oficial
- **FFmpeg DASH**: https://ffmpeg.org/ffmpeg-formats.html#dash-2
- **Shaka Player**: https://shaka-player-demo.appspot.com/docs/api/
- **DASH Specification**: https://dashif.org/
- **FastAPI**: https://fastapi.tiangolo.com/
- **Docker Compose**: https://docs.docker.com/compose/

### Herramientas
- **DASH Validator**: https://conformance.dashif.org/
- **Bitrate Calculator**: https://toolstud.io/video/bitrate.php
- **Color Palette Generator**: https://coolors.co/
- **Contrast Checker**: https://webaim.org/resources/contrastchecker/

---

## Información del Proyecto

**Curso**: Comunicaciones Multimedia - Capítulo 7  
**Programa**: Ingeniería en Telecomunicaciones  
**Institución**: Universidad de Cuenca  
**Autor**: Dario Portilla  
**Año**: 2026

---

## Estructura de Documentación

```
docs/
├── INDEX.md                    # Este archivo (navegación)
├── README.md                   # Documentación técnica completa
├── CONFIGURACION.md            # Guía de configuración y ajuste
└── TEMAS.md                    # Sistema de temas CSS

../
├── README.md                   # Documento principal del proyecto
├── GUIA_AJUSTE.md.old         # Backup (con emojis)
├── TABLA_AJUSTE.txt.old       # Backup (con emojis)
└── TEMAS.txt.old              # Backup (con emojis)
```

---

**Última actualización**: Enero 2026

Para consultas o información adicional, consultar el documento correspondiente según el tema de interés.
