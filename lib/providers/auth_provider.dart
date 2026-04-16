import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/supabase_auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final SupabaseAuthService _authService = SupabaseAuthService();
  UserModel? _currentUser;
  bool _isLoading = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;

  AuthProvider() {
    _loadUserSession();
  }

  Future<void> _loadUserSession() async {
    _setLoading(true);
    _currentUser = await _authService.getCurrentUser();
    _setLoading(false);
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    final user = await _authService.loginUser(email, password);
    _currentUser = user;
    _setLoading(false);
    return _currentUser != null;
  }

  Future<UserModel?> register(String name, String email, String password) async {
    _setLoading(true);
    try {
      final user = await _authService.registerUser(name, email, password);
      _currentUser = user;
      _setLoading(false);
      return user;
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    await _authService.logout();
    _currentUser = null;
    _setLoading(false);
  }

  Future<void> resetPassword(String email) async {
    _setLoading(true);
    try {
      await _authService.resetPassword(email);
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
