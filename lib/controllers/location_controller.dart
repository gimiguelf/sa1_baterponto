// lib/controllers/location_controller.dart
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Modelo de ponto geográfico (latitude e longitude).
class Ponto {
  final double latitude;
  final double longitude;

  Ponto(this.latitude, this.longitude);

  /// Cria a partir de um LatLng.
  factory Ponto.fromLatLng(LatLng l) => Ponto(l.latitude, l.longitude);

  /// Cria a partir de uma string "lat,lon".
  factory Ponto.fromStorageString(String s) {
    final partes = s.split(',');
    return Ponto(double.parse(partes[0]), double.parse(partes[1]));
  }

  /// Converte para LatLng.
  LatLng toLatLng() => LatLng(latitude, longitude);

  /// Converte para string para salvar.
  String toStorageString() => '$latitude,$longitude';

  @override
  String toString() => 'Ponto(lat: $latitude, lon: $longitude)';
}

/// Controla localização e armazenamento de pontos.
class LocationController {
  final Distance _distance;
  final String _storageKey;

  /// Define distância e chave de armazenamento (opcionais).
  LocationController({Distance? distance, String storageKey = 'pontos'})
      : _distance = distance ?? Distance(),
        _storageKey = storageKey;

  /// Obtém a localização atual.
  Future<Position> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      throw Exception('Serviço de localização desativado');
    }

    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception('Permissão de localização negada');
    }

    return await Geolocator.getCurrentPosition();
  }

  /// Calcula a distância entre dois pontos.
  double calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    return _distance(LatLng(lat1, lon1), LatLng(lat2, lon2));
  }

  /// Salva um ponto em SharedPreferences.
  Future<void> salvarPonto(LatLng ponto) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> pontos = prefs.getStringList(_storageKey) ?? [];
    final p = Ponto.fromLatLng(ponto);
    pontos.add(p.toStorageString());
    await prefs.setStringList(_storageKey, pontos);
  }

  /// Recupera os pontos salvos como LatLng.
  Future<List<LatLng>> getPontos() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> pontos = prefs.getStringList(_storageKey) ?? [];
    return pontos.map((e) => Ponto.fromStorageString(e).toLatLng()).toList();
  }

  /// Recupera os pontos como objetos Ponto.
  Future<List<Ponto>> getPontosComoObjetos() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> pontos = prefs.getStringList(_storageKey) ?? [];
    return pontos.map((e) => Ponto.fromStorageString(e)).toList();
  }

  /// Salva um objeto Ponto diretamente.
  Future<void> salvarPontoObjeto(Ponto ponto) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> pontos = prefs.getStringList(_storageKey) ?? [];
    pontos.add(ponto.toStorageString());
    await prefs.setStringList(_storageKey, pontos);
  }
}
