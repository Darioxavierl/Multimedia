/*__________________________________________________________________________________________

  Red Ad Hoc 802.11n con parámetros configurables y modelo de propagación realista
  Transmisión desde el nodo 1 (Tx) al nodo 0 (Rx)

          O <------------------- O
       Node0 (Rx)             Node1 (Tx)
  ___________________________________________________________________________________________
*/

#include "ns3/core-module.h"
#include "ns3/network-module.h"
#include "ns3/mobility-module.h"
#include "ns3/config-store-module.h"
#include "ns3/wifi-module.h"
#include "ns3/internet-module.h"
#include "ns3/olsr-helper.h"
#include "ns3/ipv4-static-routing-helper.h"
#include "ns3/ipv4-list-routing-helper.h"
#include "ns3/netanim-module.h"
#include "ns3/energy-module.h"
#include "ns3/propagation-module.h"

#include "wifi-config.h"

#include <iostream>
#include <fstream>
#include <vector>
#include <string>

NS_LOG_COMPONENT_DEFINE("AD_HOC_NETWORK_CONFIGURABLE");

using namespace ns3;

/*__________________________________________________________________________________________

                 Variables globales
  ___________________________________________________________________________________________
*/
int packetnumber = 0;
WifiCardConfiguration wifiConfig;
EnvironmentConfiguration envConfig;

/*__________________________________________________________________________________________

                 Función: Información Transmisión - Recepción de Paquetes
  ___________________________________________________________________________________________
*/
std::string PrintReceivedPacket(Address &from)
{
    packetnumber = packetnumber + 1;
    InetSocketAddress iaddr = InetSocketAddress::ConvertFrom(from);

    std::ostringstream oss;
    oss << "--\nReceived packet number->" << packetnumber << "  "
        << "from:" << iaddr.GetIpv4()
        << " port: " << iaddr.GetPort()
        << " at time = " << Simulator::Now().GetSeconds()
        << "\n--";

    return oss.str();
}

/*__________________________________________________________________________________________

                 Función: Recepción de Tráfico
  ___________________________________________________________________________________________
*/
void ReceivePacket(Ptr<Socket> socket)
{
    Ptr<Packet> packet;
    Address from;
    while ((packet = socket->RecvFrom(from)))
    {
        if (packet->GetSize() > 0)
        {
            NS_LOG_UNCOND(PrintReceivedPacket(from));
        }
    }
}

/*__________________________________________________________________________________________

                Función: Generación de Tráfico
  ___________________________________________________________________________________________
*/
static void GenerateTraffic(Ptr<Socket> socket, uint32_t pktSize,
                            uint32_t pktCount, Time pktInterval)
{
    if (pktCount > 0)
    {
        socket->Send(Create<Packet>(pktSize));
        Simulator::Schedule(pktInterval, &GenerateTraffic,
                            socket, pktSize, pktCount - 1, pktInterval);
    }
    else
    {
        socket->Close();
    }
}

/*__________________________________________________________________________________________

                Función: Configurar Modelo de Propagación
  ___________________________________________________________________________________________
*/
void ConfigurePropagationModel(YansWifiChannelHelper &channel, EnvironmentConfiguration &config)
{
    if (config.propagationModel == "LogDistance")
    {
        channel.AddPropagationLoss("ns3::LogDistancePropagationLossModel",
                                   "Exponent", DoubleValue(config.pathLossExponent),
                                   "ReferenceDistance", DoubleValue(config.referenceDistance),
                                   "ReferenceLoss", DoubleValue(config.referenceLoss));
        
        // Agregar shadowing (desvanecimiento lento) para realismo
        // Esto suaviza la transición entre recepción y no recepción
        if (config.enableShadowing)
        {
            channel.AddPropagationLoss("ns3::RandomPropagationLossModel",
                                       "Variable", StringValue("ns3::NormalRandomVariable[Mean=0|Variance=" + 
                                       std::to_string(config.shadowingStdDev * config.shadowingStdDev) + "]"));
        }
    }
    else if (config.propagationModel == "TwoRayGround")
    {
        channel.AddPropagationLoss("ns3::TwoRayGroundPropagationLossModel",
                                   "Frequency", DoubleValue(config.propagationModel == "TwoRayGround" ? 2.4e9 : 5.0e9),
                                   "SystemLoss", DoubleValue(config.systemLoss));
    }
    else if (config.propagationModel == "Nakagami")
    {
        channel.AddPropagationLoss("ns3::NakagamiPropagationLossModel",
                                   "m0", DoubleValue(config.nakagamiM0),
                                   "m1", DoubleValue(config.nakagamiM1),
                                   "m2", DoubleValue(config.nakagamiM2));
    }
    else if (config.propagationModel == "Friis")
    {
        channel.AddPropagationLoss("ns3::FriisPropagationLossModel",
                                   "Frequency", DoubleValue(2.4e9),
                                   "SystemLoss", DoubleValue(config.systemLoss));
    }
    else
    {
        // Modelo por defecto si no se reconoce
        NS_LOG_WARN("Modelo de propagación no reconocido: " << config.propagationModel 
                    << ". Usando LogDistance por defecto.");
        channel.AddPropagationLoss("ns3::LogDistancePropagationLossModel",
                                   "Exponent", DoubleValue(config.pathLossExponent),
                                   "ReferenceDistance", DoubleValue(config.referenceDistance),
                                   "ReferenceLoss", DoubleValue(config.referenceLoss));
        
        // Agregar shadowing al modelo por defecto también
        if (config.enableShadowing)
        {
            channel.AddPropagationLoss("ns3::RandomPropagationLossModel",
                                       "Variable", StringValue("ns3::NormalRandomVariable[Mean=0|Variance=" + 
                                       std::to_string(config.shadowingStdDev * config.shadowingStdDev) + "]"));
        }
    }
    
    // Modelo de retardo de propagación
    channel.SetPropagationDelay("ns3::ConstantSpeedPropagationDelayModel");
}

/*__________________________________________________________________________________________

                Función: Imprimir Configuración
  ___________________________________________________________________________________________
*/
void PrintAllConfiguration()
{
    std::cout << "\n========== CONFIGURACIÓN DE SIMULACIÓN ==========\n";
    wifiConfig.PrintConfiguration();
    envConfig.PrintConfiguration();
    std::cout << "=================================================\n\n";
}

/*________________________________________________________________________________________

                 Main
  ________________________________________________________________________________________
*/
int main(int argc, char *argv[])
{
    uint32_t packetSize = 1000;
    uint32_t numPackets = 100;
    uint32_t numNodes = 2;
    uint32_t sinkNode = 0;
    uint32_t sourceNode = 1;
    double interval = 0.01;
    bool verbose = false;
    bool tracing = true;

    CommandLine cmd;
    // Parámetros de simulación básicos
    cmd.AddValue("packetSize", "size of application packet sent", packetSize);
    cmd.AddValue("numPackets", "number of packets generated", numPackets);
    cmd.AddValue("interval", "interval (seconds) between packets", interval);
    cmd.AddValue("verbose", "turn on all WifiNetDevice log components", verbose);
    cmd.AddValue("tracing", "turn on ascii and pcap tracing", tracing);
    
    // Parámetros WiFi - Tarjeta
    cmd.AddValue("phyMode", "WiFi PHY mode (HtMcs0-HtMcs7)", wifiConfig.phyMode);
    cmd.AddValue("channelWidth", "Channel width in MHz (20 or 40)", wifiConfig.channelWidth);
    cmd.AddValue("channel", "WiFi channel number", wifiConfig.channelNumber);
    cmd.AddValue("txPower", "Transmission power in dBm", wifiConfig.txPowerStart);
    cmd.AddValue("txGain", "Transmission antenna gain in dBi", wifiConfig.txGain);
    cmd.AddValue("rxGain", "Reception antenna gain in dBi", wifiConfig.rxGain);
    cmd.AddValue("rxSensitivity", "Reception sensitivity in dBm", wifiConfig.rxSensitivity);
    cmd.AddValue("rateControl", "Rate control algorithm (ConstantRate/MinstrelHt/Ideal)", 
                 wifiConfig.rateControl);
    
    // Parámetros de propagación - Entorno
    cmd.AddValue("distance", "Distance between nodes in meters", envConfig.nodeDistance);
    cmd.AddValue("propModel", "Propagation loss model (LogDistance/TwoRayGround/Nakagami/Friis)", 
                 envConfig.propagationModel);
    cmd.AddValue("exponent", "Path loss exponent", envConfig.pathLossExponent);
    cmd.AddValue("shadowing", "Enable shadowing (fading) for more realistic behavior (true/false)", 
                 envConfig.enableShadowing);
    cmd.AddValue("shadowingStd", "Shadowing standard deviation in dB", envConfig.shadowingStdDev);
    
    cmd.Parse(argc, argv);

    // Sincronizar txPowerEnd con txPowerStart
    wifiConfig.txPowerEnd = wifiConfig.txPowerStart;
    wifiConfig.ccaThreshold = wifiConfig.rxSensitivity + 10.0;
    
    Time interPacketInterval = Seconds(interval);
    
    // Calcular tiempo de simulación dinámicamente
    // Tiempo total = tiempo inicial (5s) + tiempo para enviar todos los paquetes + margen
    double totalSimulationTime = 5.0 + (numPackets * interval) + 2.0;  // +2s de margen
    
    NS_LOG_UNCOND("Duración calculada: " << totalSimulationTime << " segundos para " 
                  << numPackets << " paquetes con intervalo de " << interval << "s");

    PrintAllConfiguration();

    /*__________________________________________________________________________________________________

                              Creación de Nodos Ad-Hoc
      __________________________________________________________________________________________________
    */
    NodeContainer AdHocNode;
    AdHocNode.Create(numNodes);

    /*__________________________________________________________________________________________________

                              Configuración del Canal con Propagación Realista
      __________________________________________________________________________________________________
    */
    YansWifiChannelHelper wifiChannel;
    ConfigurePropagationModel(wifiChannel, envConfig);

    /*__________________________________________________________________________________________________

                              Configuración Física
      __________________________________________________________________________________________________
    */
    YansWifiPhyHelper wifiPhy;
    wifiPhy.SetChannel(wifiChannel.Create());
    
    // Configurar potencia de transmisión
    wifiPhy.Set("TxPowerStart", DoubleValue(wifiConfig.txPowerStart));
    wifiPhy.Set("TxPowerEnd", DoubleValue(wifiConfig.txPowerEnd));
    wifiPhy.Set("TxPowerLevels", UintegerValue(wifiConfig.txPowerLevels));
    wifiPhy.Set("TxGain", DoubleValue(wifiConfig.txGain));
    wifiPhy.Set("RxGain", DoubleValue(wifiConfig.rxGain));
    wifiPhy.Set("RxSensitivity", DoubleValue(wifiConfig.rxSensitivity));
    wifiPhy.Set("CcaEdThreshold", DoubleValue(wifiConfig.ccaThreshold));
    
    // Configurar ancho de canal
    wifiPhy.Set("ChannelSettings", 
                StringValue("{" + std::to_string(wifiConfig.channelNumber) + ", " + 
                           std::to_string(wifiConfig.channelWidth) + ", BAND_2_4GHZ, 0}"));

    WifiHelper wifi;
    wifi.SetStandard(WIFI_STANDARD_80211n);
    
    // Configurar según el tipo de gestor de tasa
    if (wifiConfig.rateControl == "ns3::ConstantRateWifiManager")
    {
        wifi.SetRemoteStationManager(wifiConfig.rateControl,
                                     "DataMode", StringValue(wifiConfig.phyMode),
                                     "ControlMode", StringValue(wifiConfig.phyMode));
    }
    else
    {
        // Para gestores adaptativos como Minstrel
        wifi.SetRemoteStationManager(wifiConfig.rateControl);
    }

    WifiMacHelper wifiMac;
    wifiMac.SetType("ns3::AdhocWifiMac");

    NetDeviceContainer devices = wifi.Install(wifiPhy, wifiMac, AdHocNode);

    /*__________________________________________________________________________________________________

                        Movilidad con distancia configurable
      __________________________________________________________________________________________________
    */
    MobilityHelper mobility;
    mobility.SetMobilityModel("ns3::ConstantPositionMobilityModel");
    mobility.Install(AdHocNode);

    // Nodo 0 en el origen, Nodo 1 a la distancia especificada
    AnimationInterface::SetConstantPosition(AdHocNode.Get(0), 0, 0);
    AnimationInterface::SetConstantPosition(AdHocNode.Get(1), envConfig.nodeDistance, 0);

    /*__________________________________________________________________________________________________

                        Capa de Red
      __________________________________________________________________________________________________
    */
    InternetStackHelper internet;
    internet.Install(AdHocNode);

    Ipv4AddressHelper ipv4;
    ipv4.SetBase("10.10.10.0", "255.255.255.0");
    Ipv4InterfaceContainer i = ipv4.Assign(devices);

    /*__________________________________________________________________________________________________

                        Aplicación UDP
      __________________________________________________________________________________________________
    */
    TypeId tid = TypeId::LookupByName("ns3::UdpSocketFactory");
    Ptr<Socket> recvSink = Socket::CreateSocket(AdHocNode.Get(sinkNode), tid);
    InetSocketAddress local = InetSocketAddress(Ipv4Address::GetAny(), 1234);
    recvSink->Bind(local);
    recvSink->SetRecvCallback(MakeCallback(&ReceivePacket));

    Ptr<Socket> source = Socket::CreateSocket(AdHocNode.Get(sourceNode), tid);
    InetSocketAddress remote = InetSocketAddress(i.GetAddress(sinkNode, 0), 1234);
    source->Connect(remote);

    /*__________________________________________________________________________________________________

                        Trazas y Animación
      __________________________________________________________________________________________________
    */
    Simulator::Schedule(Seconds(5.0), &GenerateTraffic,
                        source, packetSize, numPackets, interPacketInterval);

    NS_LOG_UNCOND("Testing from node " << sourceNode << " to " << sinkNode 
                  << " at distance " << envConfig.nodeDistance << "m");

    Simulator::Stop(Seconds(totalSimulationTime));

    if (tracing)
    {
        wifiPhy.EnablePcap("twoNodes", devices);
    }

    // AnimationInterface anim("twoNodes.xml");

    Simulator::Run();
    
    Simulator::Destroy();

    return 0;
}
