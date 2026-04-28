import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import '../models/report_model.dart';

class InformeCriaderoView extends StatefulWidget {
  final List<File> fotosTomadas;
  final String ubicacion;
  final Position? posicionActual;
  final int totalDetecciones;

  const InformeCriaderoView({
    super.key,
    required this.fotosTomadas,
    required this.ubicacion,
    required this.posicionActual,
    required this.totalDetecciones,
  });

  @override
  State<InformeCriaderoView> createState() => _InformeCriaderoViewState();
}

class _InformeCriaderoViewState extends State<InformeCriaderoView> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreReporteController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController();
  final TextEditingController _referenciaController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _personasAfectadasController = TextEditingController();

  List<String> _tiposCriaderoSeleccionados = [];
  String _estadoCriadero = 'Con agua estancada';
  bool _guardando = false;
  String _userName = 'Cargando...';

  final List<String> tiposCriaderoDisponibles = [
    'Llantas viejas', 'Baldes con agua', 'Tanques destapados', 'Botellas estancadas',
    'Floreros', 'Bebederos de mascotas', 'Canaletas tapadas', 'Charco de agua',
    'Tambores', 'Envases plasticos', 'Coches abandonados', 'Techos', 'Piscinas descuidadas', 'Otro',
  ];

  final List<String> estadosCriadero = ['Con agua estancada', 'Con larvas visibles', 'Con mosquitos adultos', 'Seco', 'Parcialmente lleno'];

  @override
  void initState() {
    super.initState();
    _obtenerUsuario();
    _direccionController.text = widget.ubicacion;
  }

  Future<void> _obtenerUsuario() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      setState(() => _userName = userDoc.data()?['name'] ?? user.displayName ?? 'Brigadista');
    }
  }

  String _generarRecomendacionesIA() {
    String tiposTexto = _tiposCriaderoSeleccionados.join(', ');
    if (_tiposCriaderoSeleccionados.length >= 3) {
      return '⚠️ ALERTA CRITICA: Multiples criaderos detectados.\n\nTIPOS: $tiposTexto\n\nMEDIDAS: Elimine agua estancada, lave recipientes con cloro, reporte a sanidad.';
    } else if (_tiposCriaderoSeleccionados.length >= 2) {
      return '⚠️ ALERTA MEDIA: ${_tiposCriaderoSeleccionados.length} tipos de criaderos.\n\nTIPOS: $tiposTexto\n\nMEDIDAS: Revise el area, elimine agua estancada, tape recipientes.';
    } else {
      return '🔍 MONITOREO: Posible criadero detectado.\n\nMEDIDAS: Inspeccione visualmente, elimine agua estancada, limpie el recipiente.';
    }
  }

  Future<void> _guardarInforme() async {
    if (!_formKey.currentState!.validate()) return;
    if (_nombreReporteController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingrese un nombre para el reporte')));
      return;
    }
    if (_tiposCriaderoSeleccionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Seleccione al menos un tipo de criadero')));
      return;
    }

    setState(() => _guardando = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');

      final String userId = user.uid;

      final Directory appDir = await getApplicationDocumentsDirectory();
      final String folderPath = '${appDir.path}/reportes/$userId/${DateTime.now().millisecondsSinceEpoch}';
      final Directory folder = Directory(folderPath);
      if (!await folder.exists()) await folder.create(recursive: true);

      List<String> rutasFotos = [];
      for (int i = 0; i < widget.fotosTomadas.length; i++) {
        final fileName = 'foto_${i + 1}.jpg';
        final localPath = '$folderPath/$fileName';
        await widget.fotosTomadas[i].copy(localPath);
        rutasFotos.add(localPath);
      }

      final reporteRef = FirebaseFirestore.instance.collection('reportes').doc();

      final reporte = ReportModel(
        id: reporteRef.id,
        userId: userId,
        userName: _userName,
        nombreReporte: _nombreReporteController.text,
        direccion: _direccionController.text,
        latitud: widget.posicionActual?.latitude ?? 0,
        longitud: widget.posicionActual?.longitude ?? 0,
        fecha: DateTime.now(),
        fotosUrls: rutasFotos,
        tiposCriadero: _tiposCriaderoSeleccionados,
        estadoCriadero: _estadoCriadero,
        personasAfectadas: _personasAfectadasController.text,
        descripcion: _descripcionController.text,
        recomendacionesIA: _generarRecomendacionesIA(),
        estado: 'pendiente',
        accionTomada: '',
      );

      await reporteRef.set(reporte.toMap());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Informe guardado con ${rutasFotos.length} fotos')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }

    setState(() => _guardando = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Generar Informe'), backgroundColor: const Color(0xFF2a7f4a), foregroundColor: Colors.white),
      body: _guardando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Card(color: Colors.blue.shade50, child: Padding(padding: const EdgeInsets.all(16), child: Text('📸 Fotos: ${widget.fotosTomadas.length} | Detecciones IA: ${widget.totalDetecciones}'))),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text('TITULO DEL REPORTE', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextFormField(controller: _nombreReporteController, decoration: const InputDecoration(hintText: 'Ej: Criadero en calle Las Flores'), validator: (v) => v!.isEmpty ? 'Ingrese un titulo' : null),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text('UBICACION', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Brigadista: $_userName'),
                      const SizedBox(height: 8),
                      TextFormField(controller: _direccionController, decoration: const InputDecoration(hintText: 'Direccion exacta')),
                      const SizedBox(height: 8),
                      TextFormField(controller: _referenciaController, decoration: const InputDecoration(hintText: 'Referencia (cerca de...)')),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text('TIPOS DE CRIADERO', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ...tiposCriaderoDisponibles.map((tipo) => CheckboxListTile(
                        title: Text(tipo),
                        value: _tiposCriaderoSeleccionados.contains(tipo),
                        onChanged: (bool? seleccionado) {
                          setState(() {
                            if (seleccionado == true) _tiposCriaderoSeleccionados.add(tipo);
                            else _tiposCriaderoSeleccionados.remove(tipo);
                          });
                        },
                        activeColor: const Color(0xFF2a7f4a),
                        dense: true,
                      )),
                      if (_tiposCriaderoSeleccionados.isEmpty) const Padding(padding: EdgeInsets.all(8), child: Text('⚠️ Seleccione al menos un tipo', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text('ESTADO DEL CRIADERO', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField(
                        value: _estadoCriadero,
                        items: estadosCriadero.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                        onChanged: (v) => setState(() => _estadoCriadero = v!),
                        decoration: const InputDecoration(border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(controller: _personasAfectadasController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Personas que viven cerca')),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(color: Colors.blue.shade50, child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [const Text('RECOMENDACIONES IA', style: TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 8), Text(_generarRecomendacionesIA())]))),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text('DESCRIPCION ADICIONAL', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextFormField(controller: _descripcionController, maxLines: 3, decoration: const InputDecoration(hintText: 'Observaciones importantes...')),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _guardarInforme,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2a7f4a), padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: Text('GUARDAR INFORME (${_tiposCriaderoSeleccionados.length} tipos)'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}