/*__________________________________________________________________________________________

  ARCHIVO DE CONFIGURACIÓN PARA PARÁMETROS DE RED AD-HOC
  
  1. CONFIGURACIÓN POR DEFECTO (en ad-hoc.cc):
     WifiCardConfiguration wifiConfig;      // Usa valores por defecto 
     EnvironmentConfiguration envConfig;    // Distancia 50m, LogDistance
  
  ___________________________________________________________________________________________
*/

#ifndef WIFI_CONFIG_H
#define WIFI_CONFIG_H

#include <string>
#include "ns3/core-module.h"

namespace ns3 {

/*__________________________________________________________________________________________

                 PARÁMETROS DE TARJETA WiFi
  ___________________________________________________________________________________________
*/
struct WifiCardConfiguration {
    
    // ===== PARÁMETROS BÁSICOS =====
    std::string standard = "802.11n";           
    std::string phyMode = "HtMcs7";             // MCS Index:
                                                // HtMcs0 = 6.5 Mbps (20MHz)
                                                // HtMcs1 = 13 Mbps
                                                // HtMcs2 = 19.5 Mbps
                                                // HtMcs3 = 26 Mbps
                                                // HtMcs4 = 39 Mbps
                                                // HtMcs5 = 52 Mbps
                                                // HtMcs6 = 58.5 Mbps
                                                // HtMcs7 = 65 Mbps (máx para 20MHz)
    
    // ===== CANAL Y FRECUENCIA =====
    uint32_t channelWidth = 20;                 // 20 MHz o 40 MHz
    uint32_t channelNumber = 6;                 // Canales 2.4GHz: 1-13 (Europa), 1-11 (USA)
                                                // Canal 1: 2412 MHz
                                                // Canal 6: 2437 MHz
                                                // Canal 11: 2462 MHz
    double frequency = 2.4e9;                   // 2.4 GHz o 5 GHz
    
    // ===== POTENCIA DE TRANSMISIÓN =====
    double txPowerStart = 30.0;                 // Potencia Tx en dBm
    double txPowerEnd = 30.0;                   
    uint32_t txPowerLevels = 1;                 
    
    // ===== GANANCIAS DE ANTENA =====
    double txGain = 2.0;                        // Ganancia antena Tx (dBi)
                                                // Antena integrada típica: 2-5 dBi
                                                // Antena externa: 5-15 dBi
    double rxGain = 2.0;                        // Ganancia antena Rx (dBi)
    
    // ===== SENSIBILIDAD DEL RECEPTOR =====
    double rxSensitivity = -65.0;               // Sensibilidad Rx en dBm
                                                // Valores típicos 802.11n @ 2.4GHz:
                                                // MCS0: -82 dBm
                                                // MCS7: -65 dBm (spec, pero optimista)
                                                // -75 dBm es más realista para simulación
    
    double ccaThreshold = -55.0;                // Umbral Clear Channel Assessment
                                                // Típico: rxSensitivity + 10 dB
    
    // ===== CONFIGURACIÓN AVANZADA =====
    std::string antennaType = "Isotropic";      // Isotropic, Parabolic, etc.
    bool shortGuardInterval = false;            // SGI: aumenta throughput ~10%
    uint32_t maxAmpduSize = 65535;              // Tamaño máximo A-MPDU (bytes)
    
    // Control de tasa adaptativo
    std::string rateControl = "ns3::MinstrelHtWifiManager";  
    // ===== MÉTODOS DE AYUDA =====
    void PrintConfiguration() const {
        std::cout << "\n╔════════════════════════════════════════════════╗\n";
        std::cout << "║     CONFIGURACIÓN DE TARJETA WiFi              ║\n";
        std::cout << "╠════════════════════════════════════════════════╣\n";
        std::cout << "║ Estándar: " << standard << "                              ║\n";
        std::cout << "║ PHY Mode: " << phyMode << "                              ║\n";
        std::cout << "║ Ancho de canal: " << channelWidth << " MHz                      ║\n";
        std::cout << "║ Canal: " << channelNumber << "                                   ║\n";
        std::cout << "║ Frecuencia: " << frequency/1e9 << " GHz                   ║\n";
        std::cout << "║ Potencia Tx: " << txPowerStart << " dBm                      ║\n";
        std::cout << "║ Ganancia Tx: " << txGain << " dBi                        ║\n";
        std::cout << "║ Ganancia Rx: " << rxGain << " dBi                        ║\n";
        std::cout << "║ Sensibilidad Rx: " << rxSensitivity << " dBm                 ║\n";
        std::cout << "╚════════════════════════════════════════════════╝\n";
    }
    
    // ===== MÉTODOS PARA OVERRIDES DE PARÁMETROS =====
    WifiCardConfiguration& SetPhyMode(const std::string& mode) {
        phyMode = mode;
        return *this;
    }
    
    WifiCardConfiguration& SetChannelWidth(uint32_t width) {
        channelWidth = width;
        return *this;
    }
    
    WifiCardConfiguration& SetChannelNumber(uint32_t channel) {
        channelNumber = channel;
        return *this;
    }
    
    WifiCardConfiguration& SetTxPower(double power) {
        txPowerStart = power;
        txPowerEnd = power;
        return *this;
    }
    
    WifiCardConfiguration& SetGains(double tx, double rx) {
        txGain = tx;
        rxGain = rx;
        return *this;
    }
    
    WifiCardConfiguration& SetRxSensitivity(double sens) {
        rxSensitivity = sens;
        ccaThreshold = sens + 10.0;
        return *this;
    }
    
    WifiCardConfiguration& SetRateControl(const std::string& algo) {
        rateControl = algo;
        return *this;
    }
};

/*__________________________________________________________________________________________

                 PARÁMETROS DE PROPAGACIÓN Y ENTORNO
  ___________________________________________________________________________________________
*/
struct EnvironmentConfiguration {
    
    // ===== DISTANCIA =====
    double nodeDistance = 50.0;                 // Distancia entre nodos (metros)
    
    // ===== MODELO DE PROPAGACIÓN =====
    std::string propagationModel = "LogDistance"; 
                                                // Opciones:
                                                // - "LogDistance" (recomendado)
                                                // - "TwoRayGround" (outdoor)
                                                // - "Nakagami" (fading)
                                                // - "Friis" (línea de vista)
    
    // ===== PARÁMETROS LOG DISTANCE =====
    double pathLossExponent = 3.0;              // Exponente de pérdida:
                                                // 2.0 = espacio libre
                                                // 2.7-3.5 = urbano
                                                // 3.0-4.0 = indoor oficina
                                                // 4.0-6.0 = indoor denso
    double referenceDistance = 1.0;             // Distancia de referencia (m)
    double referenceLoss = 40.0;                // Pérdida a distancia de referencia (dB)
    
    // ===== PARÁMETROS SHADOWING (opcional) =====
    bool enableShadowing = true;               
    double shadowingStdDev = 4.0;               // Desviación estándar shadowing (dB)
                                                // Típico: 3-10 dB
    
    // ===== PARÁMETROS NAKAGAMI (fading) =====
    double nakagamiM0 = 1.5;                    // Factor m (distancia corta)
    double nakagamiM1 = 0.75;                   // Factor m (distancia media)
    double nakagamiM2 = 0.75;                   // Factor m (distancia larga)
    
    // ===== PÉRDIDAS DEL SISTEMA =====
    double systemLoss = 1.0;                    // Factor de pérdidas (lineal)
    
    // ===== TIPO DE ENTORNO =====
    enum EnvironmentType {
        FREE_SPACE,
        URBAN_OUTDOOR,
        INDOOR_OFFICE,
        INDOOR_DENSE
    };
    
    // ===== MÉTODOS DE AYUDA =====
    EnvironmentConfiguration& SetNodeDistance(double distance) {
        nodeDistance = distance;
        return *this;
    }
    
    EnvironmentConfiguration& SetPropagationModel(const std::string& model) {
        propagationModel = model;
        return *this;
    }
    
    EnvironmentConfiguration& SetPathLossExponent(double exponent) {
        pathLossExponent = exponent;
        return *this;
    }
    
    // Configuraciones predefinidas
    EnvironmentConfiguration& SetEnvironment(EnvironmentType type) {
        switch(type) {
            case FREE_SPACE:
                propagationModel = "Friis";
                pathLossExponent = 2.0;
                break;
            case URBAN_OUTDOOR:
                propagationModel = "LogDistance";
                pathLossExponent = 3.5;
                enableShadowing = true;
                shadowingStdDev = 6.0;
                break;
            case INDOOR_OFFICE:
                propagationModel = "LogDistance";
                pathLossExponent = 3.5;
                enableShadowing = true;
                shadowingStdDev = 4.0;
                break;
            case INDOOR_DENSE:
                propagationModel = "LogDistance";
                pathLossExponent = 4.5;
                enableShadowing = true;
                shadowingStdDev = 8.0;
                break;
        }
        return *this;
    }
    
    void PrintConfiguration() const {
        std::cout << "\n╔════════════════════════════════════════════════╗\n";
        std::cout << "║     CONFIGURACIÓN DE ENTORNO                   ║\n";
        std::cout << "╠════════════════════════════════════════════════╣\n";
        std::cout << "║ Distancia: " << nodeDistance << " metros                     ║\n";
        std::cout << "║ Modelo: " << propagationModel << "                  ║\n";
        std::cout << "║ Exponente de pérdida: " << pathLossExponent << "               ║\n";
        std::cout << "║ Shadowing: " << (enableShadowing ? "Sí" : "No") << "                             ║\n";
        std::cout << "╚════════════════════════════════════════════════╝\n";
    }
};



} 

#endif // WIFI_CONFIG_H
