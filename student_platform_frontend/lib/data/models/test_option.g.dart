// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'test_option.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TestOption _$TestOptionFromJson(Map<String, dynamic> json) => TestOption(
      id: (json['id'] as num).toInt(),
      questionId: (json['questionId'] as num).toInt(),
      optionText: json['optionText'] as String,
      isCorrect: json['isCorrect'] as bool,
    );

Map<String, dynamic> _$TestOptionToJson(TestOption instance) =>
    <String, dynamic>{
      'id': instance.id,
      'questionId': instance.questionId,
      'optionText': instance.optionText,
      'isCorrect': instance.isCorrect,
    };
