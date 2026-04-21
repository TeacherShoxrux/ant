import '../../domain/repositories/assignment_repository.dart';
import '../data_sources/remote/api_service.dart';
import '../models/assignment.dart';
import '../models/submission.dart';

class AssignmentRepositoryImpl implements AssignmentRepository {
  final ApiService _apiService;

  AssignmentRepositoryImpl(this._apiService);

  @override
  Future<List<Assignment>> getAssignments(int topicId) async {
    final response = await _apiService.getAssignments(topicId);
    if (response.isSuccessful && response.body != null) {
      return (response.body as List).map((e) => Assignment.fromJson(e)).toList();
    }
    return [];
  }

  @override
  Future<List<Submission>> getMySubmissions() async {
    final response = await _apiService.getMySubmissions();
    if (response.isSuccessful && response.body != null) {
      return (response.body as List).map((e) => Submission.fromJson(e)).toList();
    }
    return [];
  }

  @override
  Future<bool> createAssignment({
    required int topicId,
    required String title,
    required String description,
    required int maxScore,
    DateTime? deadline,
    List<int>? fileBytes,
  }) async {
    final response = await _apiService.createAssignment(
      topicId,
      title,
      description,
      maxScore,
      deadline?.toIso8601String(),
      fileBytes,
    );
    return response.isSuccessful;
  }

  @override
  Future<bool> submitAssignment({
    required int assignmentId,
    String? comment,
    required List<int> fileBytes,
  }) async {
    final response = await _apiService.submitAssignment(
      assignmentId,
      comment,
      fileBytes,
    );
    return response.isSuccessful;
  }

  @override
  Future<List<Submission>> getTopicSubmissions(int topicId) async {
    final response = await _apiService.getTopicSubmissions(topicId);
    if (response.isSuccessful && response.body != null) {
      return (response.body as List).map((e) => Submission.fromJson(e)).toList();
    }
    return [];
  }

  @override
  Future<bool> gradeSubmission(int submissionId, int grade, String feedback) async {
    final response = await _apiService.gradeSubmission(submissionId, {
      'grade': grade,
      'feedback': feedback,
    });
    return response.isSuccessful;
  }
}
