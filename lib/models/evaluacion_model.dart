import 'package:cloud_firestore/cloud_firestore.dart';

class EvaluacionModel {
  final String id;
  final String nombre;
  final double porcentaje;
  final DateTime? fecha;
  final String? descripcion;
  final int orden;
  final DateTime? createdAt;

  const EvaluacionModel({
    required this.id,
    required this.nombre,
    required this.porcentaje,
    this.fecha,
    this.descripcion,
    required this.orden,
    this.createdAt,
  });

  factory EvaluacionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EvaluacionModel(
      id: doc.id,
      nombre: data['nombre'] ?? '',
      porcentaje: (data['porcentaje'] as num?)?.toDouble() ?? 0,
      fecha: (data['fecha'] as Timestamp?)?.toDate(),
      descripcion: data['descripcion'] as String?,
      orden: (data['orden'] as num?)?.toInt() ?? 0,
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'porcentaje': porcentaje,
      'fecha': fecha != null ? Timestamp.fromDate(fecha!) : null,
      'descripcion': descripcion,
      'orden': orden,
      'created_at': FieldValue.serverTimestamp(),
    };
  }

  EvaluacionModel copyWith({
    String? nombre,
    double? porcentaje,
    DateTime? fecha,
    String? descripcion,
    int? orden,
  }) {
    return EvaluacionModel(
      id: id,
      nombre: nombre ?? this.nombre,
      porcentaje: porcentaje ?? this.porcentaje,
      fecha: fecha ?? this.fecha,
      descripcion: descripcion ?? this.descripcion,
      orden: orden ?? this.orden,
      createdAt: createdAt,
    );
  }
}
