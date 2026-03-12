import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _user;
  String? _rol;
  bool _isLoading = false;
  String? _error;

  AuthProvider() {
    _authService.authStateChanges.listen((user) async {
      _user = user;
      if (user != null) {
        _rol = await _authService.getUserRole(user.uid);
      } else {
        _rol = null;
      }
      notifyListeners();
    });
  }

  User? get user => _user;
  String? get rol => _rol;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  bool get isAdmin => _rol == 'admin';

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _authService.login(email, password);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String email, String password, String nombre) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _authService.register(email, password, nombre);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
