import 'package:cloud_firestore/cloud_firestore.dart';

class EstudianteModel {
  final String id;
  final String nombre;
  final String apellido;
  final String cedula;
  final String? email;
  final bool activo;
  final DateTime? createdAt;

  const EstudianteModel({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.cedula,
    this.email,
    required this.activo,
    this.createdAt,
  });

  String get nombreCompleto => '$nombre $apellido';

  factory EstudianteModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EstudianteModel(
      id: doc.id,
      nombre: data['nombre'] ?? '',
      apellido: data['apellido'] ?? '',
      cedula: data['cedula'] ?? '',
      email: data['email'] as String?,
      activo: data['activo'] ?? true,
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'apellido': apellido,
      'cedula': cedula,
      'email': email,
      'activo': activo,
      'created_at': FieldValue.serverTimestamp(),
    };
  }

  EstudianteModel copyWith({
    String? nombre,
    String? apellido,
    String? cedula,
    String? email,
    bool? activo,
  }) {
    return EstudianteModel(
      id: id,
      nombre: nombre ?? this.nombre,
      apellido: apellido ?? this.apellido,
      cedula: cedula ?? this.cedula,
      email: email ?? this.email,
      activo: activo ?? this.activo,
      createdAt: createdAt,
    );
  }
}
