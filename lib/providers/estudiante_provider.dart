import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/estudiante_model.dart';
import '../services/firestore_service.dart';

class EstudianteProvider extends ChangeNotifier {
  final FirestoreService _service = FirestoreService();

  List<EstudianteModel> _estudiantes = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription<List<EstudianteModel>>? _sub;
  String? _currentSeccionId;
  String? _currentMateriaId;

  List<EstudianteModel> get estudiantes => _estudiantes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void loadEstudiantes(String seccionId, String materiaId) {
    if (_currentSeccionId == seccionId &&
        _currentMateriaId == materiaId) return;
    _currentSeccionId = seccionId;
    _currentMateriaId = materiaId;
    _sub?.cancel();
    _isLoading = true;
    notifyListeners();
    _sub = _service.getEstudiantes(seccionId, materiaId).listen(
      (data) {
        _estudiantes = data;
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

  Future<bool> addEstudiante(
      String seccionId, String materiaId, EstudianteModel est) async {
    try {
      await _service.addEstudiante(seccionId, materiaId, est);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateEstudiante(String seccionId, String materiaId,
      String estId, Map<String, dynamic> data) async {
    try {
      await _service.updateEstudiante(seccionId, materiaId, estId, data);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteEstudiante(
      String seccionId, String materiaId, String estId) async {
    try {
      await _service.deleteEstudiante(seccionId, materiaId, estId);
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
