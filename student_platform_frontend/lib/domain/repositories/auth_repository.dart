import 'dart:typed_data';
import '../../data/models/auth_response.dart';

abstract class AuthRepository {
  Future<AuthResponse?> login(String username, String password);
  Future<AuthResponse?> faceLogin(Uint8List imageBytes);
  Future<bool> register(String username, String password, String fullName);
  Future<Map<String, dynamic>> changePassword(String oldPassword, String newPassword);
  Future<void> logout();
}
