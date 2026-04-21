import 'package:json_annotation/json_annotation.dart';

part 'auth_response.g.dart';

@JsonSerializable()
class AuthResponse {
  final String token;
  final String username;
  final String fullName;
  final String role;
  final String? imagePath;

  AuthResponse({
    required this.token,
    required this.username,
    required this.fullName,
    required this.role,
    this.imagePath,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) => _$AuthResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AuthResponseToJson(this);
}
