import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  String? _token;
  String? _role;
  String? _fullName;

  String? get token => _token;
  String? get role => _role;
  String? get fullName => _fullName;
  bool get isAuthenticated => _token != null;
  bool get isAdmin => _role == 'Admin';

  AuthProvider() {
    _loadSession();
  }

  Future<void> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    _role = prefs.getString('role');
    _fullName = prefs.getString('fullName');
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    final response = await _apiService.login(username, password);
    if (response != null) {
      _token = response.token;
      _role = response.role;
      _fullName = response.fullName;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _token = null;
    _role = null;
    _fullName = null;
    notifyListeners();
  }
}
