import 'package:cloud_firestore/cloud_firestore.dart';

class MateriaModel {
  final String id;
  final String nombre;
  final String codigo;
  final String? docente;
  final bool activo;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const MateriaModel({
    required this.id,
    required this.nombre,
    required this.codigo,
    this.docente,
    required this.activo,
    this.createdAt,
    this.updatedAt,
  });

  factory MateriaModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MateriaModel(
      id: doc.id,
      nombre: data['nombre'] ?? '',
      codigo: data['codigo'] ?? '',
      docente: data['docente'] as String?,
      activo: data['activo'] ?? true,
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'codigo': codigo,
      'docente': docente,
      'activo': activo,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    };
  }

  MateriaModel copyWith({
    String? nombre,
    String? codigo,
    String? docente,
    bool? activo,
  }) {
    return MateriaModel(
      id: id,
      nombre: nombre ?? this.nombre,
      codigo: codigo ?? this.codigo,
      docente: docente ?? this.docente,
      activo: activo ?? this.activo,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
