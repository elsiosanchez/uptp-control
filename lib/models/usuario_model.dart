import 'package:cloud_firestore/cloud_firestore.dart';

class UsuarioModel {
  final String uid;
  final String nombre;
  final String email;
  final String rol;
  final bool activo;
  final DateTime? createdAt;

  const UsuarioModel({
    required this.uid,
    required this.nombre,
    required this.email,
    required this.rol,
    required this.activo,
    this.createdAt,
  });

  factory UsuarioModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UsuarioModel(
      uid: doc.id,
      nombre: data['nombre'] ?? '',
      email: data['email'] ?? '',
      rol: data['rol'] ?? 'admin',
      activo: data['activo'] ?? true,
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'email': email,
      'rol': rol,
      'activo': activo,
      'created_at': FieldValue.serverTimestamp(),
    };
  }
}
