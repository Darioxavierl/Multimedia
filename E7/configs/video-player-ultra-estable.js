    configurePlayer() {
        this.player.configure({
            streaming: {
                bufferingGoal: 6,              //  ULTRA ESTABLE: 6 segundos
                rebufferingGoal: 3,            //  3 segundos antes de rebuffer
                bufferBehind: 10,              // Más memoria buffer
                lowLatencyMode: true,
                inaccurateManifestTolerance: 0,
                retryParameters: {
                    timeout: 8000,             //  Más tiempo para reintentos
                    maxAttempts: 5,            //  Más intentos
                    baseDelay: 1000,
                    backoffFactor: 2,
                    fuzzFactor: 0.3
                },
                stallEnabled: true,
                stallThreshold: 2,             //  Más tolerante a paradas
                stallSkip: 0.1
            },
            abr: {
                enabled: true,
                defaultBandwidthEstimate: 1000000,
                switchInterval: 6,             // Cambia calidad menos frecuente
                bandwidthUpgradeTarget: 0.8,   // Más conservador
                bandwidthDowngradeTarget: 0.95
            },
            manifest: {
                dash: {
                    ignoreMinBufferTime: true,
                    autoCorrectDrift: true
                }
            }
        });
    }
