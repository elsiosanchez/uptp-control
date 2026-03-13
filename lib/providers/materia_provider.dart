import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/materia_model.dart';
import '../services/firestore_service.dart';

class MateriaProvider extends ChangeNotifier {
  final FirestoreService _service = FirestoreService();

  List<MateriaModel> _materias = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription<List<MateriaModel>>? _sub;
  String? _currentSeccionId;

  List<MateriaModel> get materias => _materias;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get currentSeccionId => _currentSeccionId;

  void loadMaterias(String seccionId, {bool forceReload = false}) {
    if (_currentSeccionId == seccionId && !forceReload) return;
    _currentSeccionId = seccionId;
    _sub?.cancel();
    _isLoading = true;
    notifyListeners();
    _sub = _service.getMateriasBySeccion(seccionId).listen(
      (data) {
        _materias = data;
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

  Future<bool> addMateria(String seccionId, MateriaModel materia) async {
    try {
      await _service.addMateria(seccionId, materia);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateMateria(
      String seccionId, String materiaId, Map<String, dynamic> data) async {
    try {
      await _service.updateMateria(seccionId, materiaId, data);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteMateria(String seccionId, String materiaId) async {
    try {
      await _service.deleteMateriaCascade(seccionId, materiaId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
