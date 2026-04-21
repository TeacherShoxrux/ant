import 'package:equatable/equatable.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final String token;
  final String role;
  final String fullName;
  final String username;
  final String? imagePath;

  const AuthAuthenticated({
    required this.token,
    required this.role,
    required this.fullName,
    required this.username,
    this.imagePath,
  });

  bool get isAdmin => role == 'Admin';

  @override
  List<Object?> get props => [token, role, fullName, username, imagePath];
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}
