import 'package:equatable/equatable.dart';
import '../../../data/models/auth_response.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class AuthAuthenticated extends AuthState {
  final AuthResponse authResponse;
  const AuthAuthenticated(this.authResponse);

  bool get isAdmin => authResponse.role == 'Admin';
  bool get isSuperAdmin => authResponse.role == 'SuperAdmin';

  @override
  List<Object?> get props => [authResponse];
}
class AuthUnauthenticated extends AuthState {}
class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
  @override
  List<Object?> get props => [message];
}
