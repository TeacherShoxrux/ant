// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'submission.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Submission _$SubmissionFromJson(Map<String, dynamic> json) => Submission(
      id: (json['id'] as num).toInt(),
      assignmentTitle: json['assignmentTitle'] as String?,
      assignmentMaxScore: (json['assignmentMaxScore'] as num?)?.toInt(),
      studentName: json['studentName'] as String,
      studentComment: json['studentComment'] as String?,
      filePath: json['filePath'] as String,
      submittedAt: DateTime.parse(json['submittedAt'] as String),
      grade: (json['grade'] as num?)?.toInt(),
      feedback: json['feedback'] as String?,
      gradedByName: json['gradedByName'] as String?,
    );

Map<String, dynamic> _$SubmissionToJson(Submission instance) =>
    <String, dynamic>{
      'id': instance.id,
      'assignmentTitle': instance.assignmentTitle,
      'assignmentMaxScore': instance.assignmentMaxScore,
      'studentName': instance.studentName,
      'studentComment': instance.studentComment,
      'filePath': instance.filePath,
      'submittedAt': instance.submittedAt.toIso8601String(),
      'grade': instance.grade,
      'feedback': instance.feedback,
      'gradedByName': instance.gradedByName,
    };
