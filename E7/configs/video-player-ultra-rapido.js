    configurePlayer() {
        this.player.configure({
            streaming: {
                bufferingGoal: 2.5,            //  RÁPIDO: 2.5 segundos
                rebufferingGoal: 1,            //  Recuperación rápida
                bufferBehind: 3,
                lowLatencyMode: true,
                inaccurateManifestTolerance: 0,
                retryParameters: {
                    timeout: 3000,             //  Timeout corto
                    maxAttempts: 3,
                    baseDelay: 300,
                    backoffFactor: 1.3,
                    fuzzFactor: 0.2
                },
                stallEnabled: true,
                stallThreshold: 0.5,           //  Detecta paradas rápido
                stallSkip: 0.2
            },
            abr: {
                enabled: true,
                defaultBandwidthEstimate: 1000000,
                switchInterval: 3,
                bandwidthUpgradeTarget: 0.9,
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
