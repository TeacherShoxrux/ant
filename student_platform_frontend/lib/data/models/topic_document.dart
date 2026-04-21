import 'package:json_annotation/json_annotation.dart';

part 'topic_document.g.dart';

@JsonSerializable()
class TopicDocument {
  final int id;
  final int topicId;
  final String title;
  final String filePath;
  final String fileName;

  TopicDocument({
    required this.id,
    required this.topicId,
    required this.title,
    required this.filePath,
    required this.fileName,
  });

  factory TopicDocument.fromJson(Map<String, dynamic> json) => _$TopicDocumentFromJson(json);
  Map<String, dynamic> toJson() => _$TopicDocumentToJson(this);
}
