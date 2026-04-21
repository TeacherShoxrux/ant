// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserSession _$UserSessionFromJson(Map<String, dynamic> json) => UserSession(
      id: (json['id'] as num).toInt(),
      studentId: (json['studentId'] as num).toInt(),
      studentName: json['studentName'] as String,
      username: json['username'] as String,
      phone: json['phone'] as String,
      roleName: json['roleName'] as String,
      loginTime: DateTime.parse(json['loginTime'] as String),
      ipAddress: json['ipAddress'] as String?,
      deviceInfo: json['deviceInfo'] as String?,
      locationInfo: json['locationInfo'] as String?,
      faceImagePath: json['faceImagePath'] as String?,
    );

Map<String, dynamic> _$UserSessionToJson(UserSession instance) =>
    <String, dynamic>{
      'id': instance.id,
      'studentId': instance.studentId,
      'studentName': instance.studentName,
      'username': instance.username,
      'phone': instance.phone,
      'roleName': instance.roleName,
      'loginTime': instance.loginTime.toIso8601String(),
      'ipAddress': instance.ipAddress,
      'deviceInfo': instance.deviceInfo,
      'locationInfo': instance.locationInfo,
      'faceImagePath': instance.faceImagePath,
    };
