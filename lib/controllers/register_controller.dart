import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/register_model.dart';

class RegisterController {
  RegisterModel model = RegisterModel();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void updateName(String value) => model.setName(value);
  void updateEmail(String value) => model.setEmail(value);
  void updatePassword(String value) => model.setPassword(value);
  void updateConfirmPassword(String value) => model.setConfirmPassword(value);

  Future<Map<String, dynamic>> registerWithFirebase() async {
    if (!model.isNameValid) {
      return {"success": false, "message": "Ingresa tu nombre completo"};
    }
    if (!model.isEmailValid) {
      return {"success": false, "message": "Ingresa un correo electrónico válido"};
    }
    if (!model.isPasswordValid) {
      return {"success": false, "message": "La contraseña debe tener mínimo 6 caracteres"};
    }
    if (!model.isPasswordMatch) {
      return {"success": false, "message": "Las contraseñas no coinciden"};
    }

    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: model.email.trim(),
        password: model.password,
      );

      await userCredential.user?.updateDisplayName(model.name);
      await userCredential.user?.reload();

      await _saveUserToFirestore(userCredential.user!);

      String userName = model.name;
      model.clear();

      return {
        "success": true,
        "message": "✅ Registro exitoso. ¡Bienvenido $userName!",
        "user": userCredential.user
      };
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message = "❌ Este correo ya está registrado";
          break;
        case 'invalid-email':
          message = "❌ Correo electrónico inválido";
          break;
        case 'weak-password':
          message = "❌ La contraseña es muy débil";
          break;
        default:
          message = "❌ Error: ${e.message}";
      }
      return {"success": false, "message": message};
    } catch (e) {
      return {"success": false, "message": "❌ Error de conexión: $e"};
    }
  }

  Future<void> _saveUserToFirestore(User user) async {
    try {
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('users').doc(user.uid).set({
        'name': model.name,
        'email': model.email,
        'role': 'brigadista',
        'createdAt': FieldValue.serverTimestamp(),
        'uid': user.uid,
      });
    } catch (e) {
      print("Error guardando en Firestore: $e");
    }
  }
}