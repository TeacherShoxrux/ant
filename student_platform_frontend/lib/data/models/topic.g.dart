// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'topic.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Topic _$TopicFromJson(Map<String, dynamic> json) => Topic(
      id: (json['id'] as num).toInt(),
      subjectId: (json['subjectId'] as num).toInt(),
      title: json['title'] as String,
      content: json['content'] as String,
      isDisabled: json['isDisabled'] as bool? ?? false,
      quizzes: (json['quizzes'] as List<dynamic>?)
              ?.map((e) => TopicQuiz.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      assignments: (json['assignments'] as List<dynamic>?)
              ?.map((e) => Assignment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      documents: (json['documents'] as List<dynamic>?)
              ?.map((e) => TopicDocument.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      videos: (json['videos'] as List<dynamic>?)
              ?.map((e) => TopicVideo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      createdByName: json['createdByName'] as String?,
    );

Map<String, dynamic> _$TopicToJson(Topic instance) => <String, dynamic>{
      'id': instance.id,
      'subjectId': instance.subjectId,
      'title': instance.title,
      'content': instance.content,
      'isDisabled': instance.isDisabled,
      'quizzes': instance.quizzes,
      'assignments': instance.assignments,
      'documents': instance.documents,
      'videos': instance.videos,
      'createdByName': instance.createdByName,
    };
