// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'test_question.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TestQuestion _$TestQuestionFromJson(Map<String, dynamic> json) => TestQuestion(
      id: (json['id'] as num).toInt(),
      quizId: (json['quizId'] as num).toInt(),
      title: json['title'] as String,
      question: json['question'] as String,
      imagePath: json['imagePath'] as String?,
      options: (json['options'] as List<dynamic>?)
              ?.map((e) => TestOption.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$TestQuestionToJson(TestQuestion instance) =>
    <String, dynamic>{
      'id': instance.id,
      'quizId': instance.quizId,
      'title': instance.title,
      'question': instance.question,
      'imagePath': instance.imagePath,
      'options': instance.options,
    };
