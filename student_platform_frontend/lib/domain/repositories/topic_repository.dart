import '../../data/models/topic.dart';
import '../../data/models/topic_quiz.dart';
import '../../data/models/test_question.dart';

abstract class TopicRepository {
  Future<Topic?> getTopic(int id);
  Future<bool> createTopic(int subjectId, String title, String content);
  Future<bool> updateTopic(int topicId, String title, String content, bool isDisabled);
  Future<bool> deleteTopic(int topicId);
  Future<bool> addTopicVideo(int topicId, String title, String youtubeUrl);
  Future<bool> uploadTopicDocument(int topicId, String title, List<int> fileBytes);
  Future<List<TopicQuiz>> getQuizzes(int topicId);
  Future<List<TestQuestion>> getQuizQuestions(int quizId);
}
