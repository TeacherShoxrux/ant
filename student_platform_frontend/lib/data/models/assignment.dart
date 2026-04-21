import 'package:json_annotation/json_annotation.dart';

part 'assignment.g.dart';

@JsonSerializable()
class Assignment {
  final int id;
  final int topicId;
  final String title;
  final String description;
  final int maxScore;
  final DateTime? deadline;
  final String? filePath;
  final bool isSubmitted;
  final int? grade;
  final String? gradedByName;
  final String? createdByName;

  Assignment({
    required this.id,
    required this.topicId,
    required this.title,
    required this.description,
    required this.maxScore,
    this.deadline,
    this.filePath,
    this.isSubmitted = false,
    this.grade,
    this.gradedByName,
    this.createdByName,
  });

  factory Assignment.fromJson(Map<String, dynamic> json) => _$AssignmentFromJson(json);
  Map<String, dynamic> toJson() => _$AssignmentToJson(this);
}
