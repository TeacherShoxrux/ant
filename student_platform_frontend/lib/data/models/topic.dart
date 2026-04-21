import 'package:json_annotation/json_annotation.dart';
import 'assignment.dart';
import 'topic_quiz.dart';
import 'topic_document.dart';
import 'topic_video.dart';

part 'topic.g.dart';

@JsonSerializable()
class Topic {
  final int id;
  final int subjectId;
  final String title;
  final String content;
  final bool isDisabled;
  final List<TopicQuiz> quizzes;
  final List<Assignment> assignments;
  final List<TopicDocument> documents;
  final List<TopicVideo> videos;
  final String? createdByName;

  Topic({
    required this.id,
    required this.subjectId,
    required this.title,
    required this.content,
    this.isDisabled = false,
    this.quizzes = const [],
    this.assignments = const [],
    this.documents = const [],
    this.videos = const [],
    this.createdByName,
  });

  factory Topic.fromJson(Map<String, dynamic> json) => _$TopicFromJson(json);
  Map<String, dynamic> toJson() => _$TopicToJson(this);
}
