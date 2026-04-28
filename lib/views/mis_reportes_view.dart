import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import '../models/report_model.dart';

class MisReportesView extends StatefulWidget {
  const MisReportesView({super.key});

  @override
  State<MisReportesView> createState() => _MisReportesViewState();
}

class _MisReportesViewState extends State<MisReportesView> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _formatFecha(DateTime fecha) {
    return '${fecha.day}/${fecha.month}/${fecha.year} ${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}';
  }

  void _verFotos(List<String> paths) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: Colors.black87),
          child: Stack(
            children: [
              PageView.builder(
                itemCount: paths.length,
                itemBuilder: (context, index) => InteractiveViewer(child: Image.file(File(paths[index]), fit: BoxFit.contain)),
              ),
              Positioned(top: 10, right: 10, child: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white))),
              Positioned(
                bottom: 10,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                    child: Text('${paths.length} fotos', style: const TextStyle(color: Colors.white)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _eliminarReporte(String reporteId) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar reporte'),
        content: const Text('¿Estas seguro de que deseas eliminar este reporte?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _firestore.collection('reportes').doc(reporteId).delete();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reporte eliminado')));
                Navigator.pop(context, true);
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Future<void> _marcarSolucionado(ReportModel reporte) async {
    final accion = await _mostrarDialogoAccion(context);
    if (accion != null && accion.isNotEmpty) {
      await _firestore.collection('reportes').doc(reporte.id).update({
        'estado': 'solucionado',
        'accionTomada': accion,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reporte marcado como solucionado')));
        setState(() {});
      }
    }
  }

  Future<String?> _mostrarDialogoAccion(BuildContext context) async {
    final List<String> opciones = [
      'Limpie el criadero',
      'Elimine el agua estancada',
      'Tape o cubri el recipiente',
      'Aplique larvicida',
      'Reporte a sanidad',
      'El propietario limpio',
      'Pendiente de verificacion',
    ];
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Que accion tomaste?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: opciones.map((opcion) => ListTile(
            leading: const Icon(Icons.check_circle, color: Colors.green),
            title: Text(opcion),
            onTap: () => Navigator.pop(context, opcion),
          )).toList(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, null), child: const Text('Cancelar')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text('No autenticado')));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Reportes'),
        backgroundColor: const Color(0xFF2a7f4a),
        foregroundColor: Colors.white,
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: () => setState(() {}))],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('reportes').where('userId', isEqualTo: user.uid).orderBy('fecha', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final reportes = snapshot.data!.docs;
          if (reportes.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [Icon(Icons.report_off, size: 64, color: Colors.grey), SizedBox(height: 16), Text('No hay reportes aun'), Text('Usa el Smart Scanner para crear tu primer reporte')],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reportes.length,
            itemBuilder: (context, index) {
              final data = reportes[index].data() as Map<String, dynamic>;
              final reporte = ReportModel.fromMap(reportes[index].id, data);
              final bool esPendiente = reporte.estado == 'pendiente';
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 16),
                color: esPendiente ? Colors.red.shade50 : Colors.green.shade50,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: esPendiente ? Colors.red : Colors.green, width: 2)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: esPendiente ? Colors.red : Colors.green, borderRadius: BorderRadius.circular(12)),
                            child: Text(esPendiente ? 'PENDIENTE' : 'SOLUCIONADO', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                          const Spacer(),
                          Text(_formatFecha(reporte.fecha), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(reporte.nombreReporte, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.bug_report, size: 20, color: Colors.orange),
                          const SizedBox(width: 8),
                          Expanded(child: Text(reporte.tiposCriadero.join(', '), style: const TextStyle(fontSize: 14))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(child: Text(reporte.direccion, style: const TextStyle(fontSize: 12), maxLines: 2)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
                        child: Text('Estado: ${reporte.estadoCriadero}', style: const TextStyle(fontSize: 11)),
                      ),
                      if (reporte.recomendacionesIA.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Recomendaciones IA:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                              const SizedBox(height: 4),
                              Text(reporte.recomendacionesIA, style: const TextStyle(fontSize: 11), maxLines: 3),
                            ],
                          ),
                        ),
                      ],
                      if (!esPendiente && reporte.accionTomada.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            children: [
                              const Icon(Icons.verified, size: 16, color: Colors.green),
                              const SizedBox(width: 8),
                              Expanded(child: Text(reporte.accionTomada, style: const TextStyle(fontSize: 12))),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          if (reporte.fotosUrls.isNotEmpty)
                            Expanded(
                              child: TextButton.icon(
                                onPressed: () => _verFotos(reporte.fotosUrls),
                                icon: const Icon(Icons.image, size: 18),
                                label: Text('${reporte.fotosUrls.length} fotos'),
                                style: TextButton.styleFrom(foregroundColor: const Color(0xFF2a7f4a)),
                              ),
                            ),
                          if (esPendiente)
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _marcarSolucionado(reporte),
                                icon: const Icon(Icons.check_circle, size: 18),
                                label: const Text('Solucionar'),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                              ),
                            ),
                          IconButton(onPressed: () => _eliminarReporte(reporte.id), icon: const Icon(Icons.delete_outline, color: Colors.red)),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}