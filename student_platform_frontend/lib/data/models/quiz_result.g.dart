// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quiz_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QuizResult _$QuizResultFromJson(Map<String, dynamic> json) => QuizResult(
      studentName: json['studentName'] as String,
      score: (json['score'] as num).toInt(),
      totalQuestions: (json['totalQuestions'] as num).toInt(),
      takenAt: DateTime.parse(json['takenAt'] as String),
    );

Map<String, dynamic> _$QuizResultToJson(QuizResult instance) =>
    <String, dynamic>{
      'studentName': instance.studentName,
      'score': instance.score,
      'totalQuestions': instance.totalQuestions,
      'takenAt': instance.takenAt.toIso8601String(),
    };
