// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'topic_document.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TopicDocument _$TopicDocumentFromJson(Map<String, dynamic> json) =>
    TopicDocument(
      id: (json['id'] as num).toInt(),
      topicId: (json['topicId'] as num).toInt(),
      title: json['title'] as String,
      filePath: json['filePath'] as String,
      fileName: json['fileName'] as String,
    );

Map<String, dynamic> _$TopicDocumentToJson(TopicDocument instance) =>
    <String, dynamic>{
      'id': instance.id,
      'topicId': instance.topicId,
      'title': instance.title,
      'filePath': instance.filePath,
      'fileName': instance.fileName,
    };
