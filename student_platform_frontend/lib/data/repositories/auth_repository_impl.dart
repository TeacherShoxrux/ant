import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/repositories/auth_repository.dart';
import '../data_sources/remote/api_service.dart';
import '../models/auth_response.dart';

class AuthRepositoryImpl implements AuthRepository {
  final ApiService _apiService;
  final SharedPreferences _prefs;

  AuthRepositoryImpl(this._apiService, this._prefs);

  @override
  Future<AuthResponse?> login(String username, String password) async {
    final response = await _apiService.login({'username': username, 'password': password});
    if (response.isSuccessful && response.body != null) {
      final authResponse = AuthResponse.fromJson(response.body);
      await _saveAuthData(authResponse);
      return authResponse;
    }
    return null;
  }

  @override
  Future<AuthResponse?> faceLogin(Uint8List imageBytes) async {
    final response = await _apiService.faceLogin(imageBytes.toList());
    if (response.isSuccessful && response.body != null) {
      final authResponse = AuthResponse.fromJson(response.body);
      await _saveAuthData(authResponse);
      return authResponse;
    }
    return null;
  }

  @override
  Future<bool> register(String username, String password, String fullName) async {
    final response = await _apiService.register({
      'username': username,
      'password': password,
      'fullName': fullName,
    });
    return response.isSuccessful;
  }

  @override
  Future<Map<String, dynamic>> changePassword(String oldPassword, String newPassword) async {
    final response = await _apiService.changePassword({
      'oldPassword': oldPassword,
      'newPassword': newPassword,
    });
    if (response.isSuccessful) {
      return {'success': true, 'message': 'Parol muvaffaqiyatli o\'zgartirildi.'};
    } else {
      return {'success': false, 'message': response.error?.toString() ?? 'Xatolik yuz berdi.'};
    }
  }

  @override
  Future<void> logout() async {
    await _prefs.clear();
  }

  Future<void> _saveAuthData(AuthResponse authResponse) async {
    await _prefs.setString('token', authResponse.token);
    await _prefs.setString('role', authResponse.role);
    await _prefs.setString('fullName', authResponse.fullName);
    await _prefs.setString('username', authResponse.username);
    if (authResponse.imagePath != null) {
      await _prefs.setString('imagePath', authResponse.imagePath!);
    }
  }
}
