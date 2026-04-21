import 'package:json_annotation/json_annotation.dart';

part 'submission.g.dart';

@JsonSerializable()
class Submission {
  final int id;
  final String? assignmentTitle;
  final int? assignmentMaxScore;
  final String studentName;
  final String? studentComment;
  final String filePath;
  final DateTime submittedAt;
  final int? grade;
  final String? feedback;
  final String? gradedByName;

  Submission({
    required this.id,
    this.assignmentTitle,
    this.assignmentMaxScore,
    required this.studentName,
    this.studentComment,
    required this.filePath,
    required this.submittedAt,
    this.grade,
    this.feedback,
    this.gradedByName,
  });

  factory Submission.fromJson(Map<String, dynamic> json) => _$SubmissionFromJson(json);
  Map<String, dynamic> toJson() => _$SubmissionToJson(this);
}
