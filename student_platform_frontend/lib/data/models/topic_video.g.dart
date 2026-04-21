// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'topic_video.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TopicVideo _$TopicVideoFromJson(Map<String, dynamic> json) => TopicVideo(
      id: (json['id'] as num).toInt(),
      topicId: (json['topicId'] as num).toInt(),
      title: json['title'] as String,
      youtubeUrl: json['youtubeUrl'] as String,
      createdByName: json['createdByName'] as String?,
    );

Map<String, dynamic> _$TopicVideoToJson(TopicVideo instance) =>
    <String, dynamic>{
      'id': instance.id,
      'topicId': instance.topicId,
      'title': instance.title,
      'youtubeUrl': instance.youtubeUrl,
      'createdByName': instance.createdByName,
    };
