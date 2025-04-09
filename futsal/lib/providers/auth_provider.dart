// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:futsal/models/user.dart';
import 'package:futsal/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _authService.isAuthenticated;
  User? get user => _authService.user;
  String? get token => _authService.token;
  bool get isManager => _authService.isManager;
  bool get isClient => _authService.isClient;

  AuthProvider() {
    _initialize();
    _authService.authStateChanges.addListener(_onAuthStateChanged);
  }

  void _onAuthStateChanged() {
    notifyListeners();
  }

  Future<void> _initialize() async {
    try {
      _setLoading(true);
      await _authService.initialize();
    } finally {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _setLoading(false);
      });
    }
  }

  Future<bool> register(String name, String phone, String password) async {
    _setLoading(true);
    _clearError();

    final response = await _authService.register(name, phone, password);

    if (!response['success']) {
      _setError(response['message']);
    }

    _setLoading(false);
    return response['success'];
  }

  Future<bool> login(String phone, String password) async {
    _setLoading(true);
    _clearError();

    final response = await _authService.login(phone, password);

    if (!response['success']) {
      _setError(response['message']);
    }

    _setLoading(false);
    return response['success'];
  }

  Future<bool> logout() async {
    _setLoading(true);
    _clearError();

    final response = await _authService.logout();

    if (!response['success']) {
      _setError(response['message']);
    }

    _setLoading(false);
    return response['success'];
  }

  Future<bool> updateProfile({
    String? name,
    String? phone,
    String? currentPassword,
    String? newPassword,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final response = await _authService.updateProfile(
        name: name,
        phone: phone,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      if (!response['success']) {
        _setError(response['message'] ?? 'Error updating profile');
      }

      return response['success'];
    } catch (e) {
      _setError('An error occurred while updating profile');
      return false;
    } finally {
      _setLoading(false);
    }
  }

// In lib/providers/auth_provider.dart
  Future<void> checkAuth() async {
    _setLoading(true);
    _clearError();

    await _initialize();

    // Delay state update until after build completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setLoading(false);
    });
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authService.authStateChanges.removeListener(_onAuthStateChanged);
    super.dispose();
  }
}
