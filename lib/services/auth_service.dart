import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/constants.dart';
import '../models/usuario_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> login(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  Future<UserCredential> register(
      String email, String password, String nombre) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await _firestore
          .collection(AppConstants.colUsers)
          .doc(credential.user!.uid)
          .set(UsuarioModel(
            uid: credential.user!.uid,
            nombre: nombre,
            email: email.trim(),
            rol: AppConstants.rolAdmin,
            activo: true,
          ).toMap());
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<String?> getUserRole(String uid) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.colUsers)
          .doc(uid)
          .get();
      if (doc.exists) {
        return doc.data()?['rol'] as String?;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Exception _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return Exception('No existe una cuenta con ese correo.');
      case 'wrong-password':
        return Exception('Contraseña incorrecta.');
      case 'invalid-email':
        return Exception('El correo electrónico no es válido.');
      case 'user-disabled':
        return Exception('Esta cuenta ha sido deshabilitada.');
      case 'email-already-in-use':
        return Exception('Ya existe una cuenta con ese correo.');
      case 'weak-password':
        return Exception('La contraseña debe tener al menos 6 caracteres.');
      case 'too-many-requests':
        return Exception('Demasiados intentos. Intenta más tarde.');
      case 'network-request-failed':
        return Exception('Error de red. Verifica tu conexión.');
      default:
        return Exception('Error de autenticación: ${e.message}');
    }
  }
}
