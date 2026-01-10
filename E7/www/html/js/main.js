// main.js - Punto de entrada principal
import { VideoPlayer } from './video-player.js';
import { StreamController } from './stream-controller.js';
import { UIController } from './ui-controller.js';

class App {
    constructor() {
        this.videoPlayer = null;
        this.streamController = null;
        this.uiController = null;
        this.init();
    }

    init() {
        // Esperar a que el DOM esté completamente cargado
        if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', () => this.setup());
        } else {
            this.setup();
        }
    }

    setup() {
        // Inicializar controladores
        this.uiController = new UIController();
        this.videoPlayer = new VideoPlayer('video', this.uiController);
        this.streamController = new StreamController(this.uiController);

        // Configurar event listeners
        this.setupEventListeners();

        this.uiController.updateStatus('Aplicación lista');
    }

    setupEventListeners() {
        const startBtn = document.getElementById('startStreamBtn');
        const stopBtn = document.getElementById('stopStreamBtn');

        startBtn.addEventListener('click', () => this.handleStartStream());
        stopBtn.addEventListener('click', () => this.handleStopStream());
    }

    async handleStartStream() {
        try {
            this.uiController.setButtonsState(false, false);
            this.uiController.updateStatus('Iniciando transmisión...');
            this.uiController.clearMessages();
            
            // Iniciar FFmpeg en el backend
            await this.streamController.startStream();
            
            // Esperar a que el archivo MPD esté disponible
            this.uiController.updateStatus('Esperando segmentos...');
            const mpdAvailable = await this.waitForMPD('/segmentos/video0.mpd', 20000);
            
            if (!mpdAvailable) {
                throw new Error('Timeout esperando el archivo MPD');
            }
            
            this.uiController.updateStatus('Cargando reproductor...');
            console.log('MPD disponible, cargando en reproductor...');
            
            // Cargar el video en el reproductor
            await this.videoPlayer.loadManifest('/segmentos/video0.mpd');
            
            this.uiController.setButtonsState(false, true);
            this.uiController.updateStatus('Transmitiendo');
            this.uiController.showSuccess('Transmisión iniciada correctamente');
        } catch (error) {
            console.error('Error completo:', error);
            this.uiController.showError('Error al iniciar transmisión: ' + error.message);
            this.uiController.updateStatus('Error');
            this.uiController.setButtonsState(true, false);
        }
    }

    async waitForMPD(url, timeout = 10000) {
        console.log('Esperando MPD en:', url);
        const startTime = Date.now();
        let attempts = 0;
        
        while (Date.now() - startTime < timeout) {
            attempts++;
            try {
                const response = await fetch(url, { method: 'HEAD' });
                console.log(`Intento ${attempts}: ${response.status}`);
                
                if (response.ok) {
                    console.log('MPD encontrado! Esperando 4 segundos más para asegurar segmentos...');
                    // Esperar más tiempo para asegurar que hay segmentos suficientes
                    await new Promise(resolve => setTimeout(resolve, 4000));
                    
                    // Verificar una vez más
                    const finalCheck = await fetch(url, { method: 'HEAD' });
                    if (finalCheck.ok) {
                        console.log('MPD confirmado disponible');
                        return true;
                    }
                }
            } catch (error) {
                console.log(`Intento ${attempts} falló:`, error.message);
            }
            await new Promise(resolve => setTimeout(resolve, 500));
        }
        
        console.error('Timeout esperando MPD después de', attempts, 'intentos');
        return false;
    }

    async handleStopStream() {
        try {
            this.uiController.setButtonsState(false, false);
            this.uiController.updateStatus('Deteniendo transmisión...');
            this.uiController.clearMessages();
            
            // Detener el reproductor
            this.videoPlayer.unload();
            
            // Detener FFmpeg en el backend
            await this.streamController.stopStream();
            
            this.uiController.setButtonsState(true, false);
            this.uiController.updateStatus('Detenido');
            this.uiController.updateQuality('-');
            this.uiController.updateBuffer('-');
            this.uiController.showSuccess('Transmisión detenida');
        } catch (error) {
            this.uiController.showError('Error al detener transmisión: ' + error.message);
            this.uiController.setButtonsState(false, true);
        }
    }
}

// Inicializar la aplicación
new App();
