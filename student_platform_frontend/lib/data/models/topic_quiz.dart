import 'package:json_annotation/json_annotation.dart';
import 'test_question.dart';

part 'topic_quiz.g.dart';

@JsonSerializable()
class TopicQuiz {
  final int id;
  final int topicId;
  final String title;
  final String content;
  final int timeLimitMinutes;
  final String? imagePath;
  final List<TestQuestion> questions;
  final String? createdByName;

  TopicQuiz({
    required this.id,
    required this.topicId,
    required this.title,
    required this.content,
    required this.timeLimitMinutes,
    this.imagePath,
    this.questions = const [],
    this.createdByName,
  });

  factory TopicQuiz.fromJson(Map<String, dynamic> json) => _$TopicQuizFromJson(json);
  Map<String, dynamic> toJson() => _$TopicQuizToJson(this);
}
