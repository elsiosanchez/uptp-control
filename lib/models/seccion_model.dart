import 'package:cloud_firestore/cloud_firestore.dart';

class SeccionModel {
  final String id;
  final String nombre;
  final String codigo;
  final String turno;
  final int anioEscolar;
  final bool activo;
  final DateTime? createdAt;

  const SeccionModel({
    required this.id,
    required this.nombre,
    required this.codigo,
    required this.turno,
    required this.anioEscolar,
    required this.activo,
    this.createdAt,
  });

  factory SeccionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SeccionModel(
      id: doc.id,
      nombre: data['nombre'] ?? '',
      codigo: data['codigo'] ?? '',
      turno: data['turno'] ?? '',
      anioEscolar: (data['anio_escolar'] as num?)?.toInt() ?? DateTime.now().year,
      activo: data['activo'] ?? true,
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'codigo': codigo,
      'turno': turno,
      'anio_escolar': anioEscolar,
      'activo': activo,
      'created_at': FieldValue.serverTimestamp(),
    };
  }

  SeccionModel copyWith({
    String? nombre,
    String? codigo,
    String? turno,
    int? anioEscolar,
    bool? activo,
  }) {
    return SeccionModel(
      id: id,
      nombre: nombre ?? this.nombre,
      codigo: codigo ?? this.codigo,
      turno: turno ?? this.turno,
      anioEscolar: anioEscolar ?? this.anioEscolar,
      activo: activo ?? this.activo,
      createdAt: createdAt,
    );
  }
}
