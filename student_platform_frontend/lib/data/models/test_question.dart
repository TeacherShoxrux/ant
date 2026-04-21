import 'package:json_annotation/json_annotation.dart';
import 'test_option.dart';

part 'test_question.g.dart';

@JsonSerializable()
class TestQuestion {
  final int id;
  final int quizId;
  final String title;
  final String question;
  final String? imagePath;
  final List<TestOption> options;

  TestQuestion({
    required this.id,
    required this.quizId,
    required this.title,
    required this.question,
    this.imagePath,
    this.options = const [],
  });

  factory TestQuestion.fromJson(Map<String, dynamic> json) => _$TestQuestionFromJson(json);
  Map<String, dynamic> toJson() => _$TestQuestionToJson(this);
}
