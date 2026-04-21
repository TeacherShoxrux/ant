import 'package:json_annotation/json_annotation.dart';

part 'quiz_result.g.dart';

@JsonSerializable()
class QuizResult {
  final String studentName;
  final int score;
  final int totalQuestions;
  final DateTime takenAt;

  QuizResult({
    required this.studentName,
    required this.score,
    required this.totalQuestions,
    required this.takenAt,
  });

  factory QuizResult.fromJson(Map<String, dynamic> json) => _$QuizResultFromJson(json);
  Map<String, dynamic> toJson() => _$QuizResultToJson(this);
}
