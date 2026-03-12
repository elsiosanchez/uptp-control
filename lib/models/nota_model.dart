import 'package:cloud_firestore/cloud_firestore.dart';

class NotaModel {
  final String id;
  final String estudianteId;
  final String evaluacionId;
  final double calificacion;
  final String? observacion;
  final DateTime? fechaRegistro;
  final DateTime? updatedAt;

  const NotaModel({
    required this.id,
    required this.estudianteId,
    required this.evaluacionId,
    required this.calificacion,
    this.observacion,
    this.fechaRegistro,
    this.updatedAt,
  });

  factory NotaModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotaModel(
      id: doc.id,
      estudianteId: data['estudiante_id'] ?? '',
      evaluacionId: data['evaluacion_id'] ?? '',
      calificacion: (data['calificacion'] as num?)?.toDouble() ?? 0,
      observacion: data['observacion'] as String?,
      fechaRegistro: (data['fecha_registro'] as Timestamp?)?.toDate(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'estudiante_id': estudianteId,
      'evaluacion_id': evaluacionId,
      'calificacion': calificacion,
      'observacion': observacion,
      'fecha_registro': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    };
  }

  NotaModel copyWith({
    double? calificacion,
    String? observacion,
  }) {
    return NotaModel(
      id: id,
      estudianteId: estudianteId,
      evaluacionId: evaluacionId,
      calificacion: calificacion ?? this.calificacion,
      observacion: observacion ?? this.observacion,
      fechaRegistro: fechaRegistro,
      updatedAt: updatedAt,
    );
  }
}
