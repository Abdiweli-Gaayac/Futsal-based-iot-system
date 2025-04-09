// lib/services/auth_service.dart
import 'package:flutter/foundation.dart';
import 'package:futsal/models/user.dart';
import 'package:futsal/services/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  final ApiClient _apiClient = ApiClient();

  // Auth state
  bool _isAuthenticated = false;
  String? _token;
  User? _user;

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  String? get token => _token;
  User? get user => _user;
  bool get isManager => _user?.role == 'manager';
  bool get isClient => _user?.role == 'client';

  // Auth state notifier
  final ValueNotifier<bool> authStateChanges = ValueNotifier<bool>(false);

  // Singleton pattern
  factory AuthService() => _instance;

  AuthService._internal();

  Future<void> initialize() async {
    await _loadFromStorage();
  }

  // In lib/services/auth_service.dart
  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tokenStr = prefs.getString('token');
      final userStr = prefs.getString('user');

      if (tokenStr != null && userStr != null) {
        _token = tokenStr;
        // Add Bearer prefix when loading from storage
        _apiClient.setToken('Bearer $tokenStr'); // ← This is the critical fix
        _user = User.fromJson(jsonDecode(userStr));
        _isAuthenticated = true;
        authStateChanges.value = true;
      }
    } catch (e) {
      await _clearAuth();
    }
  }

  Future<Map<String, dynamic>> register(
      String name, String phone, String password) async {
    final response = await _apiClient.request(
      method: 'POST',
      path: '/auth/register',
      data: {
        'name': name,
        'phone': phone,
        'password': password,
      },
    );

    if (response['success'] && response['data'] != null) {
      final userData = response['data']['user'];
      final token = response['data']['token'];
      final user = User.fromJson(userData);

      await _handleSuccessfulAuth(token, user);
    }

    return response;
  }

  Future<Map<String, dynamic>> login(String phone, String password) async {
    final response = await _apiClient.request(
      method: 'POST',
      path: '/auth/login',
      data: {
        'phone': phone,
        'password': password,
      },
    );

    if (response['success'] && response['data'] != null) {
      final userData = response['data']['user'];
      final token = response['data']['token'];
      final user = User.fromJson(userData);

      await _handleSuccessfulAuth(token, user);
    }

    return response;
  }

  Future<Map<String, dynamic>> logout() async {
    await _clearAuth();
    return {
      'success': true,
      'message': 'Logged out successfully',
    };
  }

  Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? phone,
    String? currentPassword,
    String? newPassword,
  }) async {
    try {
      final data = <String, dynamic>{};

      if (name != null) data['name'] = name;
      if (phone != null) data['phone'] = phone;
      if (currentPassword != null) data['currentPassword'] = currentPassword;
      if (newPassword != null) data['newPassword'] = newPassword;

      final response = await _apiClient.request(
        method: 'PATCH',
        path: '/auth/update-profile',
        data: data,
      );

      if (response['success'] && response['data'] != null) {
        try {
          _user = User.fromJson(response['data']);
          await _saveUserToStorage();
          authStateChanges.value = true;
        } catch (e) {
          debugPrint('Error parsing user data: $e');
          return {
            'success': false,
            'message': 'Error updating profile',
          };
        }
      }

      return response;
    } catch (e) {
      debugPrint('Error updating profile: $e');
      return {
        'success': false,
        'message': 'Error updating profile',
      };
    }
  }

  Future<void> _handleSuccessfulAuth(String token, User user) async {
    _token = token;
    _user = user;
    _isAuthenticated = true;

    // Set token with Bearer prefix
    _apiClient.setToken('Bearer $token'); // ← Ensure consistency here

    await _saveToStorage();
    authStateChanges.value = true;
  }

  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', _token!);
    await prefs.setString('user', jsonEncode(_user!.toJson()));
  }

  Future<void> _saveUserToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', jsonEncode(_user!.toJson()));
  }

  Future<void> _clearAuth() async {
    _token = null;
    _user = null;
    _isAuthenticated = false;

    _apiClient.clearToken();

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    authStateChanges.value = false;
  }
}
