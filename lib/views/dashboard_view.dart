import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'smart_scanner_view.dart';
import 'mis_reportes_view.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _currentUser;
  String _userName = "Cargando...";
  int _totalReportes = 0;
  int _totalCriaderos = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadStats();
  }

  Future<void> _loadUserData() async {
    _currentUser = _auth.currentUser;
    if (_currentUser != null) {
      final doc = await _firestore.collection('users').doc(_currentUser!.uid).get();
      if (doc.exists) {
        setState(() {
          _userName = doc.data()?['name'] ?? _currentUser!.displayName ?? 'Brigadista';
        });
      } else {
        setState(() {
          _userName = _currentUser!.displayName ?? 'Brigadista';
        });
      }
    }
  }

  Future<void> _loadStats() async {
    if (_currentUser == null) return;

    final reportes = await _firestore
        .collection('reportes')
        .where('userId', isEqualTo: _currentUser!.uid)
        .get();

    int totalCriaderos = 0;
    for (var doc in reportes.docs) {
      final data = doc.data();
      final tipos = data['tiposCriadero'];
      if (tipos != null && tipos is List) {
        totalCriaderos += tipos.length;
      }
    }

    setState(() {
      _totalReportes = reportes.docs.length;
      _totalCriaderos = totalCriaderos;
    });
  }

  Future<void> _logout() async {
    await _auth.signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2d6a4f), Color(0xFF1b4332), Color(0xFF081c15)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Text('🦟', style: TextStyle(fontSize: 32)),
                        SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('DENGUE', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            Text('DETECTOR', style: TextStyle(color: Colors.white70, fontSize: 14)),
                          ],
                        ),
                      ],
                    ),
                    IconButton(onPressed: _logout, icon: const Icon(Icons.logout, color: Colors.white, size: 28)),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.95), borderRadius: BorderRadius.circular(24)),
                child: Column(
                  children: [
                    const Text('¡Bienvenido!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1e5631))),
                    const SizedBox(height: 8),
                    Text(_userName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF2a7f4a))),
                    const SizedBox(height: 8),
                    const Text('Tu eres parte de la solucion contra el dengue', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Color(0xFF5b7c6e))),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(child: _buildStatCard(icon: Icons.report, title: 'Reportes', value: _totalReportes, color: Colors.blue)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildStatCard(icon: Icons.bug_report, title: 'Criaderos', value: _totalCriaderos, color: Colors.orange)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.95), borderRadius: BorderRadius.circular(24)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Acciones rapidas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1e5631))),
                      const SizedBox(height: 16),
                      _buildMenuButton(
                        icon: Icons.qr_code_scanner,
                        title: 'Smart Scanner',
                        subtitle: 'Deteccion automatica con IA',
                        color: const Color(0xFFe74c2b),
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const SmartScannerView()),
                          );
                          if (result == true) _loadStats();
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildMenuButton(
                        icon: Icons.list_alt,
                        title: 'Mis Reportes',
                        subtitle: 'Historial y seguimiento',
                        color: const Color(0xFF3b8b5e),
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const MisReportesView()),
                          );
                          if (result == true) {
                            await _loadStats();
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildMenuButton(
                        icon: Icons.map,
                        title: 'Mapa de Riesgo',
                        subtitle: 'Visualiza zonas con criaderos',
                        color: const Color(0xFF5b7c6e),
                        onTap: () => _showComingSoon(context, 'Mapa de Riesgo'),
                      ),
                      const SizedBox(height: 12),
                      _buildMenuButton(
                        icon: Icons.people,
                        title: 'Equipo',
                        subtitle: 'Comunidad unida contra el dengue',
                        color: const Color(0xFF8baa9a),
                        onTap: () => _showComingSoon(context, 'Equipo'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({required IconData icon, required String title, required int value, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))]),
      child: Column(
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 8),
          Text(value.toString(), style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontSize: 12, color: Color(0xFF5b7c6e))),
        ],
      ),
    );
  }

  Widget _buildMenuButton({required IconData icon, required String title, required String subtitle, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.3))),
        child: Row(
          children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: Colors.white, size: 24)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF5b7c6e))),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 18),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Proximamente'),
        content: Text('La funcion "$feature" estara disponible pronto.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Aceptar', style: TextStyle(color: Color(0xFF2a7f4a)))),
        ],
      ),
    );
  }
}