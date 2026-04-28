import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import '../services/detection_service.dart';
import 'informe_criadero_view.dart';

class SmartScannerView extends StatefulWidget {
  const SmartScannerView({super.key});

  @override
  State<SmartScannerView> createState() => _SmartScannerViewState();
}

class _SmartScannerViewState extends State<SmartScannerView> {
  CameraController? _camaraController;
  List<CameraDescription>? _camaras;
  bool _isInicializando = true;
  bool _isDetectando = false;
  bool _puedeCapturar = true;
  double _confianzaActual = 0.0;

  List<File> _fotosTomadas = [];

  String _ubicacion = 'Obteniendo ubicacion...';
  Position? _posicionActual;

  final RealDetectionService _detectionService = RealDetectionService();
  Timer? _detectionTimer;

  @override
  void initState() {
    super.initState();
    _iniciarCamara();
    _obtenerUbicacion();
  }

  @override
  void dispose() {
    _detectionTimer?.cancel();
    _camaraController?.dispose();
    _detectionService.dispose();
    super.dispose();
  }

  Future<void> _iniciarCamara() async {
    try {
      _camaras = await availableCameras();
      if (_camaras != null && _camaras!.isNotEmpty) {
        _camaraController = CameraController(_camaras![0], ResolutionPreset.low);
        await _camaraController!.initialize();
        await _detectionService.init();
        setState(() => _isInicializando = false);
        _iniciarDeteccionContinua();
      }
    } catch (e) {
      setState(() => _isInicializando = false);
    }
  }

  void _iniciarDeteccionContinua() {
    _detectionTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      if (!_isInicializando && _camaraController != null && _camaraController!.value.isInitialized && _puedeCapturar) {
        _detectarYActualizarConfianza();
      }
    });
  }

  Future<void> _detectarYActualizarConfianza() async {
    if (_isDetectando) return;
    _isDetectando = true;
    _puedeCapturar = false;

    try {
      final imagen = await _camaraController!.takePicture();
      final result = await _detectionService.detectarCriadero(imagen);
      await File(imagen.path).delete();
      setState(() => _confianzaActual = result.confianza);
      if (result.esCriadero) {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('⚠️ POSIBLE CRIADERO! Confianza: ${(result.confianza * 100).toStringAsFixed(0)}%'), duration: const Duration(seconds: 1), backgroundColor: Colors.red),
        );
      }
    } catch (e) {}

    _isDetectando = false;
    Future.delayed(const Duration(seconds: 1), () => _puedeCapturar = true);
  }

  Future<void> _tomarFotoManual() async {
    if (_camaraController == null || !_puedeCapturar) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Espere un momento antes de tomar otra foto')));
      return;
    }
    _puedeCapturar = false;
    try {
      final imagen = await _camaraController!.takePicture();
      final file = File(imagen.path);
      setState(() => _fotosTomadas.add(file));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('📸 Foto ${_fotosTomadas.length} guardada'), duration: const Duration(milliseconds: 500), backgroundColor: Colors.green));
      HapticFeedback.lightImpact();
    } catch (e) {}
    Future.delayed(const Duration(seconds: 1), () => _puedeCapturar = true);
  }

  Future<void> _obtenerUbicacion() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        setState(() => _ubicacion = 'Active la ubicacion');
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      _posicionActual = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
      setState(() => _ubicacion = '${_posicionActual!.latitude.toStringAsFixed(6)}, ${_posicionActual!.longitude.toStringAsFixed(6)}');
    } catch (e) {
      setState(() => _ubicacion = 'Error al obtener ubicacion');
    }
  }

  void _finalizarEscaneo() {
    if (_fotosTomadas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tome al menos una foto')));
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => InformeCriaderoView(fotosTomadas: _fotosTomadas, ubicacion: _ubicacion, posicionActual: _posicionActual, totalDetecciones: _fotosTomadas.length)),
    ).then((_) {
      setState(() {
        _fotosTomadas.clear();
        _confianzaActual = 0.0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Scanner'),
        backgroundColor: _confianzaActual >= 0.65 ? Colors.red[800] : const Color(0xFF2a7f4a),
        foregroundColor: Colors.white,
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
            child: Row(
              children: [const Icon(Icons.photo_camera, size: 16, color: Colors.white), const SizedBox(width: 4), Text('${_fotosTomadas.length}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))],
            ),
          ),
          Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: _confianzaActual >= 0.65 ? Colors.red : Colors.black54, borderRadius: BorderRadius.circular(20)),
            child: Text('${(_confianzaActual * 100).toStringAsFixed(0)}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: _isInicializando
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          if (_camaraController != null && _camaraController!.value.isInitialized) CameraPreview(_camaraController!),
          if (_confianzaActual >= 0.65)
            Container(
              decoration: BoxDecoration(border: Border.all(color: Colors.red, width: 6), borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.5), blurRadius: 20, spreadRadius: 5)]),
              margin: const EdgeInsets.all(20),
            ),
          if (_confianzaActual >= 0.65)
            const Positioned(
              top: 80,
              left: 0,
              right: 0,
              child: Center(
                child: Material(
                  color: Colors.black54,
                  borderRadius: BorderRadius.all(Radius.circular(30)),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.warning, color: Colors.red, size: 24), SizedBox(width: 8), Text('¡CRIADERO DETECTADO!', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))]),
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: 100,
            right: 20,
            child: FloatingActionButton(onPressed: _tomarFotoManual, backgroundColor: const Color(0xFF2a7f4a), child: const Icon(Icons.camera_alt, size: 30)),
          ),
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: ElevatedButton.icon(
              onPressed: _finalizarEscaneo,
              icon: const Icon(Icons.check_circle),
              label: Text(_fotosTomadas.isEmpty ? 'FINALIZAR (sin fotos)' : 'FINALIZAR (${_fotosTomadas.length} fotos)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _fotosTomadas.isEmpty ? Colors.grey : const Color(0xFF2a7f4a),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ),
          if (_fotosTomadas.isNotEmpty)
            Positioned(
              top: 10,
              left: 10,
              child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)), child: Row(children: [const Icon(Icons.photo_library, color: Colors.white, size: 20), const SizedBox(width: 4), Text('${_fotosTomadas.length} fotos', style: const TextStyle(color: Colors.white))])),
            ),
        ],
      ),
    );
  }
}