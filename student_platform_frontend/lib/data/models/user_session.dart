import 'package:json_annotation/json_annotation.dart';

part 'user_session.g.dart';

@JsonSerializable()
class UserSession {
  final int id;
  final int studentId;
  final String studentName;
  final String username;
  final String phone;
  final String roleName;
  final DateTime loginTime;
  final String? ipAddress;
  final String? deviceInfo;
  final String? locationInfo;
  final String? faceImagePath;

  UserSession({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.username,
    required this.phone,
    required this.roleName,
    required this.loginTime,
    this.ipAddress,
    this.deviceInfo,
    this.locationInfo,
    this.faceImagePath,
  });

  factory UserSession.fromJson(Map<String, dynamic> json) => _$UserSessionFromJson(json);
  Map<String, dynamic> toJson() => _$UserSessionToJson(this);
}
