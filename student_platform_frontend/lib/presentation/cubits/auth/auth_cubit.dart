import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;

  AuthCubit(this._authRepository) : super(AuthInitial());

  Future<bool> login(String username, String password) async {
    emit(AuthLoading());
    try {
      final response = await _authRepository.login(username, password);
      if (response != null) {
        emit(AuthAuthenticated(response));
        return true;
      } else {
        emit(const AuthError('Login yoki parol xato'));
        return false;
      }
    } catch (e) {
      emit(AuthError(e.toString()));
      return false;
    }
  }

  Future<bool> faceLogin(Uint8List imageBytes) async {
    emit(AuthLoading());
    try {
      final response = await _authRepository.faceLogin(imageBytes);
      if (response != null) {
        emit(AuthAuthenticated(response));
        return true;
      } else {
        emit(const AuthError('Yuzni aniqlashda xatolik'));
        return false;
      }
    } catch (e) {
      emit(AuthError(e.toString()));
      return false;
    }
  }

  Future<void> logout() async {
    await _authRepository.logout();
    emit(AuthUnauthenticated());
  }
}
