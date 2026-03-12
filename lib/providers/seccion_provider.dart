import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/seccion_model.dart';
import '../services/firestore_service.dart';

class SeccionProvider extends ChangeNotifier {
  final FirestoreService _service = FirestoreService();

  List<SeccionModel> _secciones = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription<List<SeccionModel>>? _sub;

  List<SeccionModel> get secciones => _secciones;
  bool get isLoading => _isLoading;
  String? get error => _error;

  SeccionProvider() {
    _loadSecciones();
  }

  void _loadSecciones() {
    _isLoading = true;
    _sub = _service.getSecciones().listen(
      (data) {
        _secciones = data;
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

  Future<bool> addSeccion(SeccionModel seccion) async {
    try {
      await _service.addSeccion(seccion);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateSeccion(String id, Map<String, dynamic> data) async {
    try {
      await _service.updateSeccion(id, data);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteSeccion(String id) async {
    try {
      await _service.deleteSeccion(id);
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
