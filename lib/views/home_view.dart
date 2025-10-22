import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../controllers/ponto_controller.dart'; // Verifique se o nome do controller está correto
import 'hist_view.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final controller = RegistroController(); // Controlador de registro
  final Distance distance = Distance();
  final MapController mapController = MapController();

  // Local da empresa (CCS Limeira)
  final LatLng empresaLocal = LatLng(-22.5703659, -47.4471221);

  LatLng? posicaoAtual;
  String status = 'Pressione o botão para marcar ponto';
  bool dentroDaArea = false;
  bool _isProcessing = false; // Controle de carregamento

  // Obtém a localização atual
  Future<void> _pegarLocalizacao() async {
    if (_isProcessing) return; // Evita duplicar processo

    setState(() {
      _isProcessing = true;
      status = 'Buscando localização...';
    });

    try {
      final pos = await controller.pegarLocalizacao();
      final atual = LatLng(pos.latitude, pos.longitude);

      final metros = distance.as(LengthUnit.Meter, empresaLocal, atual);

      setState(() {
        posicaoAtual = atual;
        dentroDaArea = metros <= 100;
        status = 'Distância até a empresa: ${metros.toStringAsFixed(1)} m';
      });

      mapController.move(atual, 17);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao obter localização: $e')),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  // Registra o ponto atual
  Future<void> _registrarPonto() async {
    if (_isProcessing) return; // Evita repetição
    
    setState(() {
      _isProcessing = true;
      status = 'Registrando ponto...';
    });

    try {
      Position pos;
      if (posicaoAtual != null) {
        // Usa a última localização
        pos = Position(
          latitude: posicaoAtual!.latitude,
          longitude: posicaoAtual!.longitude,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0, 
          altitudeAccuracy: 0, 
          headingAccuracy: 0,
        );
      } else {
        // Obtém nova localização
        pos = await controller.pegarLocalizacao();
      }

      final metros = distance.as(LengthUnit.Meter, empresaLocal, LatLng(pos.latitude, pos.longitude));
      final dentro = metros <= 100;

      setState(() {
        posicaoAtual = LatLng(pos.latitude, pos.longitude);
        dentroDaArea = dentro;
        status = 'Distância até a empresa: ${metros.toStringAsFixed(1)} m';
      });

      if (dentro) {
        await controller.registrarPonto( // Salva no banco
          latitude: pos.latitude,
          longitude: pos.longitude,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ponto registrado!\nLat: ${pos.latitude}, Lng: ${pos.longitude}')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Você está fora da área de 100 metros!')),
        );
      }

      mapController.move(posicaoAtual!, 17);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao registrar ponto: $e')),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  // Retorna o conteúdo do botão com ícone ou carregamento
  Widget _buildButtonChild(String label, IconData icon) {
    if (_isProcessing) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }
    
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CCS Limeira'),
        actions: [
          IconButton(
            icon: const Icon(Icons.access_time),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HistoricoPage()),
              );
            },
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: empresaLocal,
                initialZoom: 16,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://a.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: empresaLocal,
                      width: 60,
                      height: 60,
                      child: const Icon(Icons.business, color: Color.fromARGB(255, 148, 3, 117), size: 35),
                    ),
                    if (posicaoAtual != null)
                      Marker(
                        point: posicaoAtual!,
                        width: 60,
                        height: 60,
                        child: Icon(
                          Icons.person_pin_circle,
                          color: dentroDaArea
                              ? const Color.fromARGB(255, 250, 183, 244)
                              : const Color.fromARGB(255, 199, 8, 8),
                          size: 35,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(status, textAlign: TextAlign.center),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Botão de localização (desativado se processando)
              ElevatedButton(
                onPressed: _isProcessing ? null : _pegarLocalizacao,
                child: _buildButtonChild('Ver Localização', Icons.my_location),
              ),
              // Botão de registro (desativado se processando)
              ElevatedButton(
                onPressed: _isProcessing ? null : _registrarPonto,
                child: _buildButtonChild('Registrar Ponto', Icons.fingerprint),
              ),
            ],
          ),
          const SizedBox(height: 15),
        ],
      ),
    );
  }
}
