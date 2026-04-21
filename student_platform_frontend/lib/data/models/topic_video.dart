import 'package:json_annotation/json_annotation.dart';

part 'topic_video.g.dart';

@JsonSerializable()
class TopicVideo {
  final int id;
  final int topicId;
  final String title;
  final String youtubeUrl;
  final String? createdByName;

  TopicVideo({
    required this.id,
    required this.topicId,
    required this.title,
    required this.youtubeUrl,
    this.createdByName,
  });

  factory TopicVideo.fromJson(Map<String, dynamic> json) => _$TopicVideoFromJson(json);
  Map<String, dynamic> toJson() => _$TopicVideoToJson(this);
}
