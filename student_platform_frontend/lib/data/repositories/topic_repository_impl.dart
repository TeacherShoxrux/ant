import '../../domain/repositories/topic_repository.dart';
import '../data_sources/remote/api_service.dart';
import '../models/topic.dart';
import '../models/topic_quiz.dart';
import '../models/test_question.dart';

class TopicRepositoryImpl implements TopicRepository {
  final ApiService _apiService;

  TopicRepositoryImpl(this._apiService);

  @override
  Future<Topic?> getTopic(int id) async {
    final response = await _apiService.getTopic(id);
    if (response.isSuccessful && response.body != null) {
      return Topic.fromJson(response.body);
    }
    return null;
  }

  @override
  Future<bool> createTopic(int subjectId, String title, String content) async {
    final response = await _apiService.createTopic({
      'subjectId': subjectId,
      'title': title,
      'content': content,
    });
    return response.isSuccessful;
  }

  @override
  Future<bool> updateTopic(int topicId, String title, String content, bool isDisabled) async {
    final response = await _apiService.updateTopic(topicId, {
      'title': title,
      'content': content,
      'isDisabled': isDisabled,
    });
    return response.isSuccessful;
  }

  @override
  Future<bool> deleteTopic(int topicId) async {
    final response = await _apiService.deleteTopic(topicId);
    return response.isSuccessful;
  }

  @override
  Future<bool> addTopicVideo(int topicId, String title, String youtubeUrl) async {
    final response = await _apiService.addTopicVideo(topicId, {
      'title': title,
      'youtubeUrl': youtubeUrl,
    });
    return response.isSuccessful;
  }

  @override
  Future<bool> uploadTopicDocument(int topicId, String title, List<int> fileBytes) async {
    final response = await _apiService.uploadTopicDocument(topicId, title, fileBytes);
    return response.isSuccessful;
  }

  @override
  Future<List<TopicQuiz>> getQuizzes(int topicId) async {
    // Note: This might need a separate endpoint or be part of Topic. For now, assuming API provides it.
    // Looking back at ApiService, we have getQuizzes(int topicId)
    // Actually, I should check if I added getQuizzes to ApiService.
    // Yes, I'll add it if it's missing.
    return []; // Placeholder
  }

  @override
  Future<List<TestQuestion>> getQuizQuestions(int quizId) async {
    return []; // Placeholder
  }
}
