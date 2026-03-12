import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/nota_model.dart';
import '../services/firestore_service.dart';

class NotaProvider extends ChangeNotifier {
  final FirestoreService _service = FirestoreService();

  List<NotaModel> _notas = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription<List<NotaModel>>? _sub;

  List<NotaModel> get notas => _notas;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void loadNotasByEvaluacion(
      String seccionId, String materiaId, String evaluacionId) {
    _sub?.cancel();
    _isLoading = true;
    notifyListeners();
    _sub = _service
        .getNotasByEvaluacion(seccionId, materiaId, evaluacionId)
        .listen(
      (data) {
        _notas = data;
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

  void loadNotasByEstudiante(
      String seccionId, String materiaId, String estudianteId) {
    _sub?.cancel();
    _isLoading = true;
    notifyListeners();
    _sub = _service
        .getNotasByEstudiante(seccionId, materiaId, estudianteId)
        .listen(
      (data) {
        _notas = data;
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

  Future<bool> guardarNotasMasivas(
      String seccionId, String materiaId, List<NotaModel> notas) async {
    try {
      await _service.guardarNotasMasivas(seccionId, materiaId, notas);
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
