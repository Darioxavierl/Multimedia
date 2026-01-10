// stream-controller.js - Controlador de transmisión FFmpeg
export class StreamController {
    constructor(uiController) {
        this.uiController = uiController;
        this.isStreaming = false;
        this.apiBaseUrl = '/api'; // Aquí se conectará con el backend
    }

    async startStream() {
        if (this.isStreaming) {
            throw new Error('La transmisión ya está activa');
        }

        try {
            // Hacer petición al servidor para iniciar FFmpeg
            const response = await fetch(`${this.apiBaseUrl}/stream/start`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                }
            });

            if (!response.ok) {
                throw new Error(`Error del servidor: ${response.status}`);
            }

            const data = await response.json();
            
            if (data.success) {
                this.isStreaming = true;
                console.log('Transmisión iniciada:', data);
                return data;
            } else {
                throw new Error(data.message || 'Error al iniciar transmisión');
            }
        } catch (error) {
            console.error('Error en startStream:', error);
            throw error;
        }
    }

    async stopStream() {
        if (!this.isStreaming) {
            throw new Error('No hay transmisión activa');
        }

        try {
            // Hacer petición al servidor para detener FFmpeg
            const response = await fetch(`${this.apiBaseUrl}/stream/stop`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                }
            });

            if (!response.ok) {
                throw new Error(`Error del servidor: ${response.status}`);
            }

            const data = await response.json();
            
            if (data.success) {
                this.isStreaming = false;
                console.log('Transmisión detenida:', data);
                return data;
            } else {
                throw new Error(data.message || 'Error al detener transmisión');
            }
        } catch (error) {
            console.error('Error en stopStream:', error);
            throw error;
        }
    }

    async getStreamStatus() {
        try {
            const response = await fetch(`${this.apiBaseUrl}/stream/status`);
            
            if (!response.ok) {
                throw new Error(`Error del servidor: ${response.status}`);
            }

            return await response.json();
        } catch (error) {
            console.error('Error al obtener estado:', error);
            throw error;
        }
    }
}
