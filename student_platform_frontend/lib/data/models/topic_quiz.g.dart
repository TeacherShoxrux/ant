// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'topic_quiz.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TopicQuiz _$TopicQuizFromJson(Map<String, dynamic> json) => TopicQuiz(
      id: (json['id'] as num).toInt(),
      topicId: (json['topicId'] as num).toInt(),
      title: json['title'] as String,
      content: json['content'] as String,
      timeLimitMinutes: (json['timeLimitMinutes'] as num).toInt(),
      imagePath: json['imagePath'] as String?,
      questions: (json['questions'] as List<dynamic>?)
              ?.map((e) => TestQuestion.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      createdByName: json['createdByName'] as String?,
    );

Map<String, dynamic> _$TopicQuizToJson(TopicQuiz instance) => <String, dynamic>{
      'id': instance.id,
      'topicId': instance.topicId,
      'title': instance.title,
      'content': instance.content,
      'timeLimitMinutes': instance.timeLimitMinutes,
      'imagePath': instance.imagePath,
      'questions': instance.questions,
      'createdByName': instance.createdByName,
    };
