import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class ApiService {
  final String baseUrl = "http://localhost:5297/api";

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<AuthResponse?> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final authResponse = AuthResponse.fromJson(data);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', authResponse.token);
      await prefs.setString('role', authResponse.role);
      await prefs.setString('fullName', authResponse.fullName);
      return authResponse;
    }
    return null;
  }

  Future<bool> register(String username, String password, String fullName) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
        'fullName': fullName,
      }),
    );
    return response.statusCode == 200;
  }

  Future<List<Subject>> getSubjects() async {
    final response = await http.get(
      Uri.parse('$baseUrl/subjects'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((s) => Subject.fromJson(s)).toList();
    }
    return [];
  }

  Future<List<Topic>> getTopics(int subjectId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/topics/subject/$subjectId'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((t) => Topic.fromJson(t)).toList();
    }
    return [];
  }

  Future<List<TestQuestion>> getTestQuestions(int topicId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/tests/topic/$topicId'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((q) => TestQuestion.fromJson(q)).toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> submitQuiz(int quizId, List<Map<String, dynamic>> answers) async {
    final response = await http.post(
      Uri.parse('$baseUrl/quizzes/submit'),
      headers: await _getHeaders(),
      body: jsonEncode({'quizId': quizId, 'answers': answers}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception(response.body);
  }

  Future<List<Assignment>> getAssignments(int topicId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/assignments/topic/$topicId'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((a) => Assignment.fromJson(a)).toList();
    }
    return [];
  }

  Future<List<Submission>> getMySubmissions() async {
    final response = await http.get(
      Uri.parse('$baseUrl/assignments/my-submissions'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((s) => Submission.fromJson(s)).toList();
    }
    return [];
  }

  // Admin section
  Future<bool> createSubject(String name, String description) async {
    final response = await http.post(
      Uri.parse('$baseUrl/subjects'),
      headers: await _getHeaders(),
      body: jsonEncode({'name': name, 'description': description}),
    );
    return response.statusCode == 201;
  }

  Future<bool> createTopic(int subjectId, String title, String content) async {
    final response = await http.post(
      Uri.parse('$baseUrl/topics'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'subjectId': subjectId,
        'title': title,
        'content': content
      }),
    );
    return response.statusCode == 201;
  }

  Future<bool> addTopicVideo(int topicId, String title, String youtubeUrl) async {
    final response = await http.post(
      Uri.parse('$baseUrl/topics/$topicId/videos'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'title': title,
        'youtubeUrl': youtubeUrl
      }),
    );
    return response.statusCode == 200;
  }

  Future<Topic?> getTopic(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/topics/$id'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return Topic.fromJson(jsonDecode(response.body));
    }
    return null;
  }

  Future<bool> uploadTopicDocument(int topicId, String title, List<int> fileBytes, String fileName) async {
    final token = await _getToken();
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/topics/$topicId/documents'));
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['title'] = title;
    request.files.add(http.MultipartFile.fromBytes('file', fileBytes, filename: fileName));

    final response = await request.send();
    return response.statusCode == 200;
  }

  Future<bool> createAssignment({
    required int topicId,
    required String title,
    required String description,
    required int maxScore,
    DateTime? deadline,
    List<int>? fileBytes,
    String? fileName,
  }) async {
    final token = await _getToken();
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/assignments'));
    request.headers['Authorization'] = 'Bearer $token';

    request.fields['topicId'] = topicId.toString();
    request.fields['title'] = title;
    request.fields['description'] = description;
    request.fields['maxScore'] = maxScore.toString();
    if (deadline != null) {
      request.fields['deadline'] = deadline.toIso8601String();
    }

    if (fileBytes != null && fileName != null) {
      request.files.add(http.MultipartFile.fromBytes('file', fileBytes, filename: fileName));
    }

    final response = await request.send();
    return response.statusCode == 200;
  }

  Future<bool> submitAssignment({
    required int assignmentId,
    String? comment,
    required List<int> fileBytes,
    required String fileName,
  }) async {
    final token = await _getToken();
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/assignments/submit/$assignmentId'));
    request.headers['Authorization'] = 'Bearer $token';

    if (comment != null) {
      request.fields['studentComment'] = comment;
    }

    request.files.add(http.MultipartFile.fromBytes('file', fileBytes, filename: fileName));

    final response = await request.send();
    return response.statusCode == 200;
  }

  Future<List<Submission>> getTopicSubmissions(int topicId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/assignments/topic/$topicId/all-submissions'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((s) => Submission.fromJson(s)).toList();
    }
    return [];
  }

  Future<bool> gradeSubmission(int submissionId, int grade, String feedback) async {
    final response = await http.post(
      Uri.parse('$baseUrl/assignments/grade/$submissionId'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'grade': grade,
        'feedback': feedback,
      }),
    );
    return response.statusCode == 200;
  }

  Future<bool> createQuiz({
    required int topicId,
    required String title,
    required String content,
    required int timeLimitMinutes,
    Uint8List? imageBytes,
    String? imageName,
  }) async {
    final token = await _getToken();
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/quizzes'));
    request.headers['Authorization'] = 'Bearer $token';

    request.fields['topicId'] = topicId.toString();
    request.fields['title'] = title;
    request.fields['content'] = content;
    request.fields['timeLimitMinutes'] = timeLimitMinutes.toString();

    if (imageBytes != null && imageName != null) {
      request.files.add(http.MultipartFile.fromBytes('image', imageBytes, filename: imageName));
    }

    final response = await request.send();
    return response.statusCode == 200;
  }

  Future<bool> addQuestionToQuiz({
    required int quizId,
    required String title,
    required String question,
    required List<Map<String, dynamic>> options,
    Uint8List? imageBytes,
    String? imageName,
  }) async {
    final token = await _getToken();
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/quizzes/$quizId/questions'));
    request.headers['Authorization'] = 'Bearer $token';

    request.fields['title'] = title;
    request.fields['question'] = question;
    request.fields['optionsJson'] = jsonEncode(options);

    if (imageBytes != null && imageName != null) {
      request.files.add(http.MultipartFile.fromBytes('image', imageBytes, filename: imageName));
    }

    final response = await request.send();
    return response.statusCode == 200;
  }

  Future<List<TopicQuiz>> getQuizzes(int topicId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/quizzes/topic/$topicId'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((q) => TopicQuiz.fromJson(q)).toList();
    }
    return [];
  }

  Future<List<TestQuestion>> getQuizQuestions(int quizId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/quizzes/$quizId/questions'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((q) => TestQuestion.fromJson(q)).toList();
    }
    return [];
  }
}
