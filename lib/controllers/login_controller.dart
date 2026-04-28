import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/login_model.dart';
import '../views/register_view.dart';

class LoginController {
  LoginModel model = LoginModel();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void updateEmail(String value) {
    model.setEmail(value);
  }

  void updatePassword(String value) {
    model.setPassword(value);
  }

  Future<Map<String, dynamic>> loginWithFirebase() async {
    if (model.email.isEmpty) {
      return {"success": false, "message": "Ingresa tu correo electrónico"};
    }
    if (model.password.isEmpty) {
      return {"success": false, "message": "Ingresa tu contraseña"};
    }

    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: model.email.trim(),
        password: model.password,
      );

      return {
        "success": true,
        "message": "Bienvenido ${userCredential.user?.displayName ?? 'Brigadista'}",
        "user": userCredential.user
      };
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = "❌ Usuario no encontrado";
          break;
        case 'wrong-password':
          message = "❌ Contraseña incorrecta";
          break;
        case 'invalid-email':
          message = "❌ Correo electrónico inválido";
          break;
        default:
          message = "❌ Error: ${e.message}";
      }
      return {"success": false, "message": message};
    } catch (e) {
      return {"success": false, "message": "❌ Error de conexión: $e"};
    }
  }

  void onRegisterPressed(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegisterView()),
    );
  }

  void onForgotPasswordPressed() {
    print("Olvidé contraseña presionado");
  }
}