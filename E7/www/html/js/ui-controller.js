// ui-controller.js - Controlador de interfaz de usuario
export class UIController {
    constructor() {
        this.elements = {
            startBtn: document.getElementById('startStreamBtn'),
            stopBtn: document.getElementById('stopStreamBtn'),
            streamStatus: document.getElementById('streamStatus'),
            qualityInfo: document.getElementById('qualityInfo'),
            bufferInfo: document.getElementById('bufferInfo'),
            errorDisplay: document.getElementById('errorDisplay'),
            successDisplay: document.getElementById('successDisplay')
        };
    }

    setButtonsState(startEnabled, stopEnabled) {
        this.elements.startBtn.disabled = !startEnabled;
        this.elements.stopBtn.disabled = !stopEnabled;
    }

    updateStatus(status) {
        this.elements.streamStatus.textContent = status;
    }

    updateQuality(quality) {
        this.elements.qualityInfo.textContent = quality;
    }

    updateBuffer(buffer) {
        this.elements.bufferInfo.textContent = buffer;
    }

    showError(message) {
        this.elements.errorDisplay.textContent = '[+] Error ' + message;
        this.elements.errorDisplay.style.display = 'block';
        this.elements.successDisplay.style.display = 'none';
    }

    showSuccess(message) {
        this.elements.successDisplay.textContent = '[+] Éxito ' + message;
        this.elements.successDisplay.style.display = 'block';
        this.elements.errorDisplay.style.display = 'none';
    }

    clearMessages() {
        this.elements.errorDisplay.textContent = '';
        this.elements.errorDisplay.style.display = 'none';
        this.elements.successDisplay.textContent = '';
        this.elements.successDisplay.style.display = 'none';
    }
}
