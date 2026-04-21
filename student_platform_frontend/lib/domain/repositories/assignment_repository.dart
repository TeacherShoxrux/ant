import '../../data/models/assignment.dart';
import '../../data/models/submission.dart';

abstract class AssignmentRepository {
  Future<List<Assignment>> getAssignments(int topicId);
  Future<List<Submission>> getMySubmissions();
  Future<bool> createAssignment({
    required int topicId,
    required String title,
    required String description,
    required int maxScore,
    DateTime? deadline,
    List<int>? fileBytes,
  });
  Future<bool> submitAssignment({
    required int assignmentId,
    String? comment,
    required List<int> fileBytes,
  });
  Future<List<Submission>> getTopicSubmissions(int topicId);
  Future<bool> gradeSubmission(int submissionId, int grade, String feedback);
}
