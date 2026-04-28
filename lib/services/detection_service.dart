import 'dart:io';
import 'package:camera/camera.dart';

class RealDetectionService {
  static final RealDetectionService _instance = RealDetectionService._internal();
  factory RealDetectionService() => _instance;
  RealDetectionService._internal();

  bool _isInitialized = false;

  // Palabras clave que indican un CRIADERO REAL de mosquitos
  final List<String> palabrasCriaderoReal = [
    'water', 'agua', 'pond', 'estancada', 'stagnant',
    'bucket', 'balde', 'tire', 'llanta', 'bottle', 'botella',
    'container', 'recipiente', 'flower', 'florero', 'pot', 'maceta',
    'drain', 'desague', 'canaleta', 'puddle', 'charco',
    'drum', 'tambor', 'barrel', 'barril', 'pool', 'piscina'
  ];

  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;
    print('Servicio de deteccion de criaderos reales inicializado');
  }

  // Deteccion mejorada para identificar CRIADEROS REALES
  Future<DetectionResult> detectarCriadero(XFile imageFile) async {
    await init();

    // Analisis basico de la imagen (simulado)
    // En produccion, esto usaria un modelo de IA entrenado
    // Por ahora, usamos un algoritmo que simula deteccion real

    double confianza = _simularDeteccionReal(imageFile);

    return DetectionResult(
      confianza: confianza,
      tipoCriadero: confianza >= 0.7 ? 'Posible criadero de mosquitos' : null,
    );
  }

  double _simularDeteccionReal(XFile imageFile) {
    // Simulacion de deteccion basada en el nombre del archivo y tamaño
    // Esto es TEMPORAL - Reemplazar con modelo IA real

    final nombreArchivo = imageFile.path.toLowerCase();
    double confianzaBase = 0.0;

    // Palabras que indican alto riesgo
    if (nombreArchivo.contains('water') || nombreArchivo.contains('agua')) {
      confianzaBase = 0.85;
    } else if (nombreArchivo.contains('bucket') || nombreArchivo.contains('tire')) {
      confianzaBase = 0.80;
    } else if (nombreArchivo.contains('bottle') || nombreArchivo.contains('container')) {
      confianzaBase = 0.75;
    } else {
      // Deteccion aleatoria pero realista (20%-40%)
      confianzaBase = 0.2 + (DateTime.now().millisecondsSinceEpoch % 20) / 100;
    }

    return confianzaBase > 0.95 ? 0.95 : confianzaBase;
  }

  void dispose() {
    _isInitialized = false;
  }
}

class DetectionResult {
  final double confianza;
  final String? tipoCriadero;

  DetectionResult({
    required this.confianza,
    this.tipoCriadero,
  });

  bool get esCriadero => confianza >= 0.65;  // 65% o mas se considera criadero
}