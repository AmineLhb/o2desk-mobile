import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  String? _token;
  String _role = 'user'; // user, agent, manager
  bool _isLoading = false;
  String? _errorMessage;
  bool _twoFactorRequired = false;

  UserModel? get user => _user;
  String? get token => _token;
  String get role => _role;
  String get userRole => _role;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;
  bool get twoFactorRequired => _twoFactorRequired;

  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('auth_token');
      _role = prefs.getString('auth_role') ?? 'user';

      if (_token != null && _token!.isNotEmpty) {
        final res = await ApiService.get('/me');
        if (res['success'] == true && res['user'] != null) {
          _user = UserModel.fromJson(res['user']);
          _role = res['role'] ?? _role;
        } else {
          await logout();
        }
      }
    } catch (_) {
      // offline or token invalid
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveAuthData(String token, String role, Map<String, dynamic> userData) async {
    _token = token;
    _role = role;
    if (userData.isNotEmpty) {
      _user = UserModel.fromJson(userData);
    }
    _twoFactorRequired = false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', _token!);
    await prefs.setString('auth_role', _role);

    notifyListeners();
  }

  Future<bool> login(String email, String password, String selectedRole, {String? otpCode}) async {
    _isLoading = true;
    _errorMessage = null;
    _twoFactorRequired = false;
    notifyListeners();

    try {
      final payload = <String, dynamic>{
        'email': email,
        'password': password,
        'role': selectedRole,
      };
      if (otpCode != null && otpCode.isNotEmpty) {
        payload['otp_code'] = otpCode;
      }

      final res = await ApiService.post('/login', payload, auth: false);

      if (res['two_factor_required'] == true) {
        _twoFactorRequired = true;
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (res['success'] == true && res['token'] != null) {
        final tokenStr = res['token'] as String;
        final roleStr = (res['role'] ?? selectedRole).toString();
        final userMap = res['user'] as Map<String, dynamic>? ?? {};

        await saveAuthData(tokenStr, roleStr, userMap);

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = res['message'] ?? 'Échec de connexion';
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    _user = null;
    _token = null;
    _role = 'user';
    _twoFactorRequired = false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('auth_role');

    notifyListeners();

    // Run backend logout in background non-blocking
    ApiService.post('/logout', {}).catchError((_) {});
  }
}