// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'assignment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Assignment _$AssignmentFromJson(Map<String, dynamic> json) => Assignment(
      id: (json['id'] as num).toInt(),
      topicId: (json['topicId'] as num).toInt(),
      title: json['title'] as String,
      description: json['description'] as String,
      maxScore: (json['maxScore'] as num).toInt(),
      deadline: json['deadline'] == null
          ? null
          : DateTime.parse(json['deadline'] as String),
      filePath: json['filePath'] as String?,
      isSubmitted: json['isSubmitted'] as bool? ?? false,
      grade: (json['grade'] as num?)?.toInt(),
      gradedByName: json['gradedByName'] as String?,
      createdByName: json['createdByName'] as String?,
    );

Map<String, dynamic> _$AssignmentToJson(Assignment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'topicId': instance.topicId,
      'title': instance.title,
      'description': instance.description,
      'maxScore': instance.maxScore,
      'deadline': instance.deadline?.toIso8601String(),
      'filePath': instance.filePath,
      'isSubmitted': instance.isSubmitted,
      'grade': instance.grade,
      'gradedByName': instance.gradedByName,
      'createdByName': instance.createdByName,
    };
