// video-player.js - Controlador del reproductor Shaka
export class VideoPlayer {
    constructor(videoElementId, uiController) {
        this.video = document.getElementById(videoElementId);
        this.player = null;
        this.uiController = uiController;
        this.init();
    }

    init() {
        // Verificar soporte del navegador
        if (!shaka.Player.isBrowserSupported()) {
            console.error('El navegador no soporta Shaka Player');
            this.uiController.showError('Tu navegador no es compatible con este reproductor');
            return;
        }

        // Instalar polyfills
        shaka.polyfill.installAll();

        // Crear instancia del reproductor
        this.player = new shaka.Player(this.video);

        // Configurar el reproductor
        this.configurePlayer();

        // Registrar event listeners
        this.setupEventListeners();
    }

    configurePlayer() {
        this.player.configure({
            streaming: {
                bufferingGoal: 4,              // Aumentado a 4 seg (era 3) para más estabilidad
                rebufferingGoal: 2,            // Aumentado a 2 seg (era 1) para evitar cortes
                bufferBehind: 5,               // Mantener buffer detrás mínimo
                lowLatencyMode: true,          // Modo baja latencia
                inaccurateManifestTolerance: 0,
                retryParameters: {
                    timeout: 5000,             
                    maxAttempts: 4,            // Más intentos para mayor estabilidad
                    baseDelay: 500,
                    backoffFactor: 1.5,
                    fuzzFactor: 0.3
                },
                stallEnabled: true,            // Detección de paradas habilitada
                stallThreshold: 1,             // Umbral de parada en 1 segundo
                stallSkip: 0.1                 // Saltar 0.1 seg si se detecta parada
            },
            abr: {
                enabled: true,
                defaultBandwidthEstimate: 1000000,
                switchInterval: 4,             // Evaluar calidad cada 4 segundos
                bandwidthUpgradeTarget: 0.85,  // Usar 85% del ancho de banda
                bandwidthDowngradeTarget: 0.95 // Cambiar a menor calidad al 95%
            },
            manifest: {
                dash: {
                    ignoreMinBufferTime: true,
                    autoCorrectDrift: true     // Corregir automáticamente desviaciones
                }
            }
        });
    }

    setupEventListeners() {
        // Listener para errores
        this.player.addEventListener('error', (event) => {
            this.onError(event);
        });

        // Listener para cambios de adaptación
        this.player.addEventListener('adaptation', () => {
            this.updateQualityInfo();
        });

        // Listener para cambios de buffering
        this.player.addEventListener('buffering', (event) => {
            if (event.buffering) {
                this.uiController.updateStatus('Buffering...');
            } else {
                this.uiController.updateStatus('Reproduciendo');
            }
        });

        // Listener para detección de paradas (stalls)
        this.player.addEventListener('stalldetected', () => {
            console.log('Parada detectada, intentando recuperar...');
        });

        // Listener para cuando el reproductor está esperando datos
        this.video.addEventListener('waiting', () => {
            console.log('Video en espera de datos...');
        });

        // Listener para cuando el video puede reproducirse nuevamente
        this.video.addEventListener('canplay', () => {
            if (this.video.paused && this.video.readyState >= 3) {
                // Intentar reanudar si se pausó por falta de datos
                this.video.play().catch(e => console.log('No se pudo reanudar:', e));
            }
        });

        // Actualizar información de buffer periódicamente
        this.video.addEventListener('timeupdate', () => {
            this.updateBufferInfo();
        });
    }

    async loadManifest(manifestUri) {
        try {
            // Log para debugging
            console.log('Intentando cargar manifest:', manifestUri);
            console.log('Base URL:', window.location.origin);
            console.log('Full URL:', new URL(manifestUri, window.location.origin).href);
            
            // Cargar el manifiesto
            await this.player.load(manifestUri);
            console.log('Video cargado exitosamente');
            this.updateQualityInfo();
        } catch (error) {
            console.error('Error al cargar manifest:', error);
            console.error('Error code:', error.code);
            console.error('Error category:', error.category);
            console.error('Error data:', error.data);
            this.onError(error);
            throw error;
        }
    }

    unload() {
        if (this.player) {
            this.player.unload();
        }
    }

    updateQualityInfo() {
        if (!this.player) return;

        const tracks = this.player.getVariantTracks();
        const activeTrack = tracks.find(t => t.active);

        if (activeTrack) {
            const width = activeTrack.width || 'N/A';
            const height = activeTrack.height || 'N/A';
            const bandwidth = activeTrack.bandwidth 
                ? Math.round(activeTrack.bandwidth / 1000) + ' kbps'
                : 'N/A';
            
            this.uiController.updateQuality(`${width}x${height} @ ${bandwidth}`);
        }
    }

    updateBufferInfo() {
        if (!this.player || !this.video.buffered.length) return;

        const currentTime = this.video.currentTime;
        const bufferedEnd = this.video.buffered.end(this.video.buffered.length - 1);
        const bufferLength = bufferedEnd - currentTime;

        this.uiController.updateBuffer(bufferLength.toFixed(1) + 's');
    }

    onError(error) {
        console.error('Error del reproductor:', error);
        const errorDetail = error.detail || error;
        this.uiController.showError('Error del reproductor: ' + (errorDetail.message || 'Error desconocido'));
    }

    destroy() {
        if (this.player) {
            this.player.destroy();
        }
    }
}
