import 'package:json_annotation/json_annotation.dart';

part 'test_option.g.dart';

@JsonSerializable()
class TestOption {
  final int id;
  final int questionId;
  final String optionText;
  final bool isCorrect;

  TestOption({
    required this.id,
    required this.questionId,
    required this.optionText,
    required this.isCorrect,
  });

  factory TestOption.fromJson(Map<String, dynamic> json) => _$TestOptionFromJson(json);
  Map<String, dynamic> toJson() => _$TestOptionToJson(this);
}
