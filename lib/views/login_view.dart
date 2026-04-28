import 'package:flutter/material.dart';
import '../controllers/login_controller.dart';
import 'register_view.dart';
import 'dashboard_view.dart';
class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final LoginController _controller = LoginController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    _controller.updateEmail(_emailController.text);
    _controller.updatePassword(_passwordController.text);

    setState(() => _isLoading = true);
    final result = await _controller.loginWithFirebase();
    setState(() => _isLoading = false);

    if (result["success"]) {
      _showSuccessDialog(result["message"]);
    } else {
      _showErrorDialog("Error", result["message"]);
    }
  }

  void _handleRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegisterView()),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.error, color: Color(0xFFe74c2b)),
            SizedBox(width: 8),
            Text('Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Aceptar', style: TextStyle(color: Color(0xFF2a7f4a))),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.check_circle, color: Color(0xFF2a7f4a)),
            SizedBox(width: 8),
            Text('Éxito'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Cierra el diálogo
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const DashboardView()),
              );
            },
            child: const Text('Aceptar', style: TextStyle(color: Color(0xFF2a7f4a))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF2d6a4f),
              Color(0xFF1b4332),
              Color(0xFF081c15),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              child: Container(
                width: 500,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.98),
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 20,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // HEADER
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF1e6f3f), Color(0xFF0f4c2c)],
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(40),
                          topRight: Radius.circular(40),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Text('🦟', style: TextStyle(fontSize: 44)),
                              SizedBox(width: 10),
                              Text(
                                'DENGUE\nDETECTOR',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Prevención comunitaria',
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    // FORMULARIO
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Center(
                            child: Column(
                              children: [
                                Text(
                                  'Iniciar Sesión',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1e5631),
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'TODOS CONTRA EL DENGUE',
                                  style: TextStyle(color: Color(0xFF5b7c6e), fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),
                          const Text(
                            'Correo electrónico',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2c5a3b),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _emailController,
                            onChanged: (value) => _controller.updateEmail(value),
                            decoration: InputDecoration(
                              hintText: 'brigadista@ejemplo.com',
                              hintStyle: const TextStyle(fontSize: 13),
                              filled: true,
                              fillColor: const Color(0xFFfefef7),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(45),
                                borderSide: const BorderSide(color: Color(0xFFcfdfd3)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(45),
                                borderSide: const BorderSide(color: Color(0xFFcfdfd3)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(45),
                                borderSide: const BorderSide(color: Color(0xFF2d8c5a), width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Contraseña',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2c5a3b),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _passwordController,
                            obscureText: true,
                            onChanged: (value) => _controller.updatePassword(value),
                            decoration: InputDecoration(
                              hintText: '',
                              hintStyle: const TextStyle(fontSize: 13),
                              filled: true,
                              fillColor: const Color(0xFFfefef7),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(45),
                                borderSide: const BorderSide(color: Color(0xFFcfdfd3)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(45),
                                borderSide: const BorderSide(color: Color(0xFFcfdfd3)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(45),
                                borderSide: const BorderSide(color: Color(0xFF2d8c5a), width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _controller.onForgotPasswordPressed,
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                minimumSize: Size.zero,
                              ),
                              child: const Text(
                                '¿Olvidaste tu contraseña?',
                                style: TextStyle(color: Color(0xFF3b8b5e), fontWeight: FontWeight.w500, fontSize: 12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2a7f4a),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(45),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                                  : const Text(
                                'INICIAR SESIÓN',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: _handleRegister,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF2a7f4a),
                                side: const BorderSide(color: Color(0xFF2a7f4a), width: 1.5),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(45),
                                ),
                              ),
                              child: const Text(
                                'REGISTRARSE',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFecf7f0),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Column(
                              children: [
                                Text(
                                  '🛡️ Ley N° 29733 · Protección de Datos Personales',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 10, color: Color(0xFF4a7c5e)),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Al iniciar sesión aceptas el tratamiento de tus datos',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 9, color: Color(0xFF6b9080)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Center(
                            child: Text(
                              'UCV',
                              style: TextStyle(fontSize: 22,  fontWeight: FontWeight.bold, color: Color(0xFF5b7c6e)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}