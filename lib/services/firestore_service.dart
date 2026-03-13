import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/constants.dart';
import '../models/seccion_model.dart';
import '../models/materia_model.dart';
import '../models/evaluacion_model.dart';
import '../models/estudiante_model.dart';
import '../models/nota_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─────────────────────────────────────────
  // SECCIONES (top-level)
  // ─────────────────────────────────────────

  Stream<List<SeccionModel>> getSecciones() {
    return _db
        .collection(AppConstants.colSecciones)
        .where('activo', isEqualTo: true)
        .snapshots()
        .map((snap) {
      final list =
          snap.docs.map((d) => SeccionModel.fromFirestore(d)).toList();
      list.sort((a, b) => a.nombre.compareTo(b.nombre));
      return list;
    });
  }

  Future<SeccionModel?> getSeccionById(String id) async {
    final doc =
        await _db.collection(AppConstants.colSecciones).doc(id).get();
    if (!doc.exists) return null;
    return SeccionModel.fromFirestore(doc);
  }

  Future<String> addSeccion(SeccionModel seccion) async {
    final ref = await _db
        .collection(AppConstants.colSecciones)
        .add(seccion.toMap());
    return ref.id;
  }

  Future<void> updateSeccion(String id, Map<String, dynamic> data) async {
    await _db.collection(AppConstants.colSecciones).doc(id).update(data);
  }

  Future<void> deleteSeccion(String id) async {
    await _db
        .collection(AppConstants.colSecciones)
        .doc(id)
        .update({'activo': false});
  }

  // ─────────────────────────────────────────
  // MATERIAS (subcolección de sección)
  // secciones/{seccionId}/materias/{materiaId}
  // ─────────────────────────────────────────

  CollectionReference _materiasRef(String seccionId) {
    return _db
        .collection(AppConstants.colSecciones)
        .doc(seccionId)
        .collection(AppConstants.subColMaterias);
  }

  Stream<List<MateriaModel>> getMateriasBySeccion(String seccionId) {
    return _materiasRef(seccionId)
        .where('activo', isEqualTo: true)
        .snapshots()
        .map((snap) {
      final list =
          snap.docs.map((d) => MateriaModel.fromFirestore(d)).toList();
      list.sort((a, b) => a.nombre.compareTo(b.nombre));
      return list;
    });
  }

  Future<String> addMateria(String seccionId, MateriaModel materia) async {
    final ref = await _materiasRef(seccionId).add(materia.toMap());
    return ref.id;
  }

  Future<void> updateMateria(
      String seccionId, String materiaId, Map<String, dynamic> data) async {
    data['updated_at'] = FieldValue.serverTimestamp();
    await _materiasRef(seccionId).doc(materiaId).update(data);
  }

  Future<void> deleteMateria(String seccionId, String materiaId) async {
    await _materiasRef(seccionId).doc(materiaId).update({'activo': false});
  }

  // ─────────────────────────────────────────
  // EVALUACIONES (subcolección de materia)
  // secciones/{seccionId}/materias/{materiaId}/evaluaciones/{evalId}
  // ─────────────────────────────────────────

  CollectionReference _evaluacionesRef(String seccionId, String materiaId) {
    return _materiasRef(seccionId)
        .doc(materiaId)
        .collection(AppConstants.subColEvaluaciones);
  }

  Stream<List<EvaluacionModel>> getEvaluaciones(
      String seccionId, String materiaId) {
    return _evaluacionesRef(seccionId, materiaId)
        .snapshots()
        .map((snap) {
      final list =
          snap.docs.map((d) => EvaluacionModel.fromFirestore(d)).toList();
      list.sort((a, b) => a.orden.compareTo(b.orden));
      return list;
    });
  }

  Future<String> addEvaluacion(
      String seccionId, String materiaId, EvaluacionModel eval) async {
    final ref =
        await _evaluacionesRef(seccionId, materiaId).add(eval.toMap());
    return ref.id;
  }

  Future<void> updateEvaluacion(String seccionId, String materiaId,
      String evalId, Map<String, dynamic> data) async {
    await _evaluacionesRef(seccionId, materiaId).doc(evalId).update(data);
  }

  Future<void> deleteEvaluacion(
      String seccionId, String materiaId, String evalId) async {
    await _evaluacionesRef(seccionId, materiaId).doc(evalId).delete();
  }

  Future<double> getPorcentajeTotal(
      String seccionId, String materiaId) async {
    final snap = await _evaluacionesRef(seccionId, materiaId).get();
    double total = 0;
    for (final doc in snap.docs) {
      total += ((doc.data() as Map<String, dynamic>)['porcentaje'] ?? 0)
          .toDouble();
    }
    return total;
  }

  // ─────────────────────────────────────────
  // ESTUDIANTES (subcolección de materia)
  // secciones/{seccionId}/materias/{materiaId}/estudiantes/{estId}
  // ─────────────────────────────────────────

  CollectionReference _estudiantesRef(String seccionId, String materiaId) {
    return _materiasRef(seccionId)
        .doc(materiaId)
        .collection(AppConstants.subColEstudiantes);
  }

  Stream<List<EstudianteModel>> getEstudiantes(
      String seccionId, String materiaId) {
    return _estudiantesRef(seccionId, materiaId)
        .where('activo', isEqualTo: true)
        .snapshots()
        .map((snap) {
      final list =
          snap.docs.map((d) => EstudianteModel.fromFirestore(d)).toList();
      list.sort((a, b) => a.apellido.compareTo(b.apellido));
      return list;
    });
  }

  Future<String> addEstudiante(
      String seccionId, String materiaId, EstudianteModel est) async {
    final ref =
        await _estudiantesRef(seccionId, materiaId).add(est.toMap());
    return ref.id;
  }

  Future<void> updateEstudiante(String seccionId, String materiaId,
      String estId, Map<String, dynamic> data) async {
    await _estudiantesRef(seccionId, materiaId).doc(estId).update(data);
  }

  Future<void> deleteEstudiante(
      String seccionId, String materiaId, String estId) async {
    await _estudiantesRef(seccionId, materiaId)
        .doc(estId)
        .update({'activo': false});
  }

  // ─────────────────────────────────────────
  // NOTAS (subcolección de materia)
  // secciones/{seccionId}/materias/{materiaId}/notas/{notaId}
  // ─────────────────────────────────────────

  CollectionReference _notasRef(String seccionId, String materiaId) {
    return _materiasRef(seccionId)
        .doc(materiaId)
        .collection(AppConstants.subColNotas);
  }

  Stream<List<NotaModel>> getNotasByEvaluacion(
      String seccionId, String materiaId, String evaluacionId) {
    return _notasRef(seccionId, materiaId)
        .where('evaluacion_id', isEqualTo: evaluacionId)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => NotaModel.fromFirestore(d)).toList());
  }

  Stream<List<NotaModel>> getNotasByEstudiante(
      String seccionId, String materiaId, String estudianteId) {
    return _notasRef(seccionId, materiaId)
        .where('estudiante_id', isEqualTo: estudianteId)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => NotaModel.fromFirestore(d)).toList());
  }

  Future<List<NotaModel>> getAllNotas(
      String seccionId, String materiaId) async {
    final snap = await _notasRef(seccionId, materiaId).get();
    return snap.docs.map((d) => NotaModel.fromFirestore(d)).toList();
  }

  Future<void> addOrUpdateNota(
      String seccionId, String materiaId, NotaModel nota) async {
    // Buscar si ya existe nota para este estudiante + evaluación
    final existing = await _notasRef(seccionId, materiaId)
        .where('estudiante_id', isEqualTo: nota.estudianteId)
        .where('evaluacion_id', isEqualTo: nota.evaluacionId)
        .get();

    if (existing.docs.isNotEmpty) {
      await _notasRef(seccionId, materiaId)
          .doc(existing.docs.first.id)
          .update({
        'calificacion': nota.calificacion,
        'observacion': nota.observacion,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } else {
      await _notasRef(seccionId, materiaId).add(nota.toMap());
    }
  }

  Future<void> guardarNotasMasivas(
      String seccionId, String materiaId, List<NotaModel> notas) async {
    final batch = _db.batch();
    final ref = _notasRef(seccionId, materiaId);

    // Obtener notas existentes para esta evaluación
    final evaluacionId = notas.first.evaluacionId;
    final existing = await ref
        .where('evaluacion_id', isEqualTo: evaluacionId)
        .get();

    final existingMap = <String, String>{};
    for (final doc in existing.docs) {
      final data = doc.data() as Map<String, dynamic>;
      existingMap[data['estudiante_id'] as String] = doc.id;
    }

    for (final nota in notas) {
      final existingId = existingMap[nota.estudianteId];
      if (existingId != null) {
        batch.update(ref.doc(existingId), {
          'calificacion': nota.calificacion,
          'observacion': nota.observacion,
          'updated_at': FieldValue.serverTimestamp(),
        });
      } else {
        batch.set(ref.doc(), nota.toMap());
      }
    }
    await batch.commit();
  }

  // ─────────────────────────────────────────
  // ELIMINACIÓN EN CASCADA
  // ─────────────────────────────────────────

  /// Elimina una sección y todo su contenido (materias, evaluaciones, estudiantes, notas)
  Future<void> deleteSeccionCascade(String seccionId) async {
    // Obtener todas las materias de la sección
    final materiasSnap = await _materiasRef(seccionId).get();
    for (final materiaDoc in materiasSnap.docs) {
      await deleteMateriaCascade(seccionId, materiaDoc.id);
    }
    // Eliminar la sección
    await _db.collection(AppConstants.colSecciones).doc(seccionId).delete();
  }

  /// Elimina una materia y todo su contenido (evaluaciones, estudiantes, notas)
  Future<void> deleteMateriaCascade(String seccionId, String materiaId) async {
    final batch = _db.batch();

    // Eliminar todas las notas
    final notasSnap = await _notasRef(seccionId, materiaId).get();
    for (final doc in notasSnap.docs) {
      batch.delete(doc.reference);
    }

    // Eliminar todos los estudiantes
    final estudiantesSnap = await _estudiantesRef(seccionId, materiaId).get();
    for (final doc in estudiantesSnap.docs) {
      batch.delete(doc.reference);
    }

    // Eliminar todas las evaluaciones
    final evaluacionesSnap = await _evaluacionesRef(seccionId, materiaId).get();
    for (final doc in evaluacionesSnap.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();

    // Eliminar la materia
    await _materiasRef(seccionId).doc(materiaId).delete();
  }

  /// Elimina todas las notas de un estudiante en una materia
  Future<void> deleteNotasByEstudiante(
      String seccionId, String materiaId, String estudianteId) async {
    final snap = await _notasRef(seccionId, materiaId)
        .where('estudiante_id', isEqualTo: estudianteId)
        .get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  /// Elimina todas las notas de una evaluación
  Future<void> deleteNotasByEvaluacion(
      String seccionId, String materiaId, String evaluacionId) async {
    final snap = await _notasRef(seccionId, materiaId)
        .where('evaluacion_id', isEqualTo: evaluacionId)
        .get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  /// Importar estudiantes en batch
  Future<int> importarEstudiantesBatch(
      String seccionId, String materiaId, List<EstudianteModel> estudiantes) async {
    int imported = 0;
    // Firestore batch limit is 500
    for (var i = 0; i < estudiantes.length; i += 450) {
      final batch = _db.batch();
      final chunk = estudiantes.skip(i).take(450);
      for (final est in chunk) {
        batch.set(_estudiantesRef(seccionId, materiaId).doc(), est.toMap());
        imported++;
      }
      await batch.commit();
    }
    return imported;
  }

  /// Obtener lista de cédulas existentes en una materia
  Future<List<String>> getCedulasExistentes(
      String seccionId, String materiaId) async {
    final snap = await _estudiantesRef(seccionId, materiaId)
        .where('activo', isEqualTo: true)
        .get();
    return snap.docs
        .map((d) => (d.data() as Map<String, dynamic>)['cedula'] as String)
        .toList();
  }
}
