import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final ApiService _apiService = ApiService();

  AuthCubit() : super(AuthInitial()) {
    checkSession();
  }

  Future<void> checkSession() async {
    emit(AuthLoading());
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final role = prefs.getString('role');
      final fullName = prefs.getString('fullName');
      final username = prefs.getString('username');
      final imagePath = prefs.getString('imagePath');

      if (token != null && role != null && fullName != null && username != null) {
        emit(AuthAuthenticated(
          token: token,
          role: role,
          fullName: fullName,
          username: username,
          imagePath: imagePath,
        ));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthUnauthenticated());
    }
  }

  Future<bool> login(String username, String password) async {
    emit(AuthLoading());
    try {
      final response = await _apiService.login(username, password);
      if (response != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('username', response.username);
        // api_service already saves token, role, and fullName

        emit(AuthAuthenticated(
          token: response.token,
          role: response.role,
          fullName: response.fullName,
          username: response.username,
          imagePath: response.imagePath,
        ));
        return true;
      } else {
        emit(const AuthError('Login yoki parol noto\'g\'ri'));
        return false;
      }
    } catch (e) {
      emit(const AuthError('Tizim xatoligi yuz berdi'));
      return false;
    }
  }

  Future<bool> faceLogin(dynamic imageBytes, String fileName) async {
    emit(AuthLoading());
    try {
      final response = await _apiService.faceLogin(imageBytes, fileName);
      if (response != null) {
        emit(AuthAuthenticated(
          token: response.token,
          role: response.role,
          fullName: response.fullName,
          username: response.username,
          imagePath: response.imagePath,
        ));
        return true;
      } else {
        emit(const AuthError('Yuz aniqlanmadi yoki rasmda talaba topilmadi'));
        return false;
      }
    } catch (e) {
      emit(const AuthError('Face ID tizim xatoligi'));
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    emit(AuthUnauthenticated());
  }
}
