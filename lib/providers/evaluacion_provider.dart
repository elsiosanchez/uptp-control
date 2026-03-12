import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/evaluacion_model.dart';
import '../services/firestore_service.dart';

class EvaluacionProvider extends ChangeNotifier {
  final FirestoreService _service = FirestoreService();

  List<EvaluacionModel> _evaluaciones = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription<List<EvaluacionModel>>? _sub;
  String? _currentSeccionId;
  String? _currentMateriaId;

  List<EvaluacionModel> get evaluaciones => _evaluaciones;
  bool get isLoading => _isLoading;
  String? get error => _error;

  double get porcentajeTotal =>
      _evaluaciones.fold<double>(0, (sum, e) => sum + e.porcentaje);

  bool get evaluacionesCompletas => (porcentajeTotal - 100).abs() < 0.01;

  void loadEvaluaciones(String seccionId, String materiaId) {
    if (_currentSeccionId == seccionId &&
        _currentMateriaId == materiaId) return;
    _currentSeccionId = seccionId;
    _currentMateriaId = materiaId;
    _sub?.cancel();
    _isLoading = true;
    notifyListeners();
    _sub = _service.getEvaluaciones(seccionId, materiaId).listen(
      (data) {
        _evaluaciones = data;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (e) {
        _error = e.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<bool> addEvaluacion(
      String seccionId, String materiaId, EvaluacionModel eval) async {
    try {
      await _service.addEvaluacion(seccionId, materiaId, eval);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateEvaluacion(String seccionId, String materiaId,
      String evalId, Map<String, dynamic> data) async {
    try {
      await _service.updateEvaluacion(seccionId, materiaId, evalId, data);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteEvaluacion(
      String seccionId, String materiaId, String evalId) async {
    try {
      await _service.deleteEvaluacion(seccionId, materiaId, evalId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
