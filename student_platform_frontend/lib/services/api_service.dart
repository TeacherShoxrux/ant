import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import 'package:universal_html/html.dart' as html;

class ApiService {
  static const String baseUrl = "http://localhost:5297/api";
  static const String serverUrl = "http://localhost:5297";

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
      await prefs.setString('username', authResponse.username);
      if (authResponse.imagePath != null) {
        await prefs.setString('imagePath', authResponse.imagePath!);
      }
      return authResponse;
    }
    return null;
  }

  Future<AuthResponse?> faceLogin(Uint8List imageBytes, String fileName) async {
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/auth/face-login'));
    request.files.add(http.MultipartFile.fromBytes('faceImage', imageBytes, filename: "fileName"));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final authResponse = AuthResponse.fromJson(data);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', authResponse.token);
      await prefs.setString('role', authResponse.role);
      await prefs.setString('fullName', authResponse.fullName);
      await prefs.setString('username', authResponse.username);
      if (authResponse.imagePath != null) {
        await prefs.setString('imagePath', authResponse.imagePath!);
      }
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

  Future<Map<String, dynamic>> changePassword(String oldPassword, String newPassword) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/change-password'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      }),
    );
    
    if (response.statusCode == 200) {
      return {'success': true, 'message': 'Parol muvaffaqiyatli o\'zgartirildi.'};
    } else {
      return {'success': false, 'message': response.body.isNotEmpty ? response.body : 'Xatolik yuz berdi.'};
    }
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

  Future<bool> updateSubject(int id, String name, String description, bool isDisabled) async {
    final response = await http.put(
      Uri.parse('$baseUrl/subjects/$id'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'name': name,
        'description': description,
        'isDisabled': isDisabled,
      }),
    );
    return response.statusCode == 204;
  }

  Future<bool> toggleSubjectStatus(int id) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/subjects/$id/toggle-status'),
      headers: await _getHeaders(),
    );
    return response.statusCode == 200;
  }

  Future<bool> deleteSubject(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/subjects/$id'),
      headers: await _getHeaders(),
    );
    return response.statusCode == 204;
  }

  Future<List<int>> getSubjectGroups(int subjectId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/subjects/$subjectId/groups'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return List<int>.from(jsonDecode(response.body));
    }
    return [];
  }

  Future<bool> attachSubjectToGroups(int subjectId, List<int> groupIds) async {
    final response = await http.post(
      Uri.parse('$baseUrl/subjects/$subjectId/groups'),
      headers: await _getHeaders(),
      body: jsonEncode(groupIds),
    );
    return response.statusCode == 200;
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

  Future<bool> updateTopic(int topicId, String title, String content, bool isDisabled) async {
    final response = await http.put(
      Uri.parse('$baseUrl/topics/$topicId'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'title': title,
        'content': content,
        'isDisabled': isDisabled
      }),
    );
    return response.statusCode == 204;
  }

  Future<bool> toggleTopicStatus(int topicId) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/topics/$topicId/toggle-status'),
      headers: await _getHeaders(),
    );
    return response.statusCode == 200;
  }

  Future<bool> deleteTopic(int topicId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/topics/$topicId'),
      headers: await _getHeaders(),
    );
    return response.statusCode == 204;
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

  Future<Map<String, dynamic>> updateAssignment({
    required int id,
    required String title,
    required String description,
    required int maxScore,
    DateTime? deadline,
    List<int>? fileBytes,
    String? fileName,
  }) async {
    debugPrint("UPDATING ASSIGNMENT: $id");
    final token = await _getToken();
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/assignments/update/$id'));
    request.headers['Authorization'] = 'Bearer $token';

    request.fields['title'] = title;
    request.fields['description'] = description;
    request.fields['maxScore'] = maxScore.toString();
    if (deadline != null) {
      // Use a format that is more likely to be parsed by ASP.NET Core consistently
      request.fields['deadline'] = deadline.toIso8601String();
    }

    if (fileBytes != null && fileName != null) {
      request.files.add(http.MultipartFile.fromBytes('file', fileBytes, filename: fileName));
    }

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      debugPrint("SERVER RESPONSE (Assignment Update): ${response.statusCode} - ${response.body}");
      
      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        return {'success': false, 'message': response.body.isNotEmpty ? response.body : 'Server xatosi: ${response.statusCode}'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Tarmoq xatosi: $e'};
    }
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

  Future<List<QuizResult>> getQuizResults(int quizId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/quizzes/$quizId/results'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((r) => QuizResult.fromJson(r)).toList();
    }
    return [];
  }

  // Dashboard & Misc
  Future<Map<String, dynamic>> getStats() async {
    final response = await http.get(
      Uri.parse('$baseUrl/dashboard/stats'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return {};
  }

  Future<Map<String, dynamic>> getStudents({int pageNumber = 1, int pageSize = 10, String? searchTerm, int? groupId}) async {
    final queryParams = {
      'pageNumber': pageNumber.toString(),
      'pageSize': pageSize.toString(),
    };
    if (searchTerm != null && searchTerm.isNotEmpty) queryParams['searchTerm'] = searchTerm;
    if (groupId != null) queryParams['groupId'] = groupId.toString();

    final uri = Uri.parse('$baseUrl/dashboard/students').replace(queryParameters: queryParams);
    
    final response = await http.get(
      uri,
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return {'items': [], 'totalCount': 0, 'totalPages': 0};
  }

  Future<List<Map<String, dynamic>>> getSubjectGrades(int subjectId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/dashboard/grades/$subjectId'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> getTopicGradesAdmin(int topicId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/dashboard/grades/topic/$topicId'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> getGroups() async {
    final response = await http.get(
      Uri.parse('$baseUrl/dashboard/groups'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    }
    return [];
  }

  Future<void> downloadExcelReport(int subjectId, int groupId, String subjectName) async {
    final response = await http.get(
      Uri.parse('$baseUrl/dashboard/reports/excel?subjectId=$subjectId&groupId=$groupId'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final blob = html.Blob([response.bodyBytes], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.document.createElement('a') as html.AnchorElement
        ..href = url
        ..style.display = 'none'
        ..download = 'Hisobot_${subjectName.replaceAll(" ", "_")}.xlsx';
      
      html.document.body!.children.add(anchor);
      anchor.click();
      
      html.document.body!.children.remove(anchor);
      html.Url.revokeObjectUrl(url);
    } else {
      throw Exception('Hisobotni yuklashda xatolik yuz berdi');
    }
  }

  Future<Map<String, dynamic>?> createGroup(String name) async {
    final response = await http.post(
      Uri.parse('$baseUrl/dashboard/groups'),
      headers: await _getHeaders(),
      body: jsonEncode({'name': name}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }

  Future<bool> createStudent({
    required String fullName,
    String? patronymic,
    required String username,
    required String password,
    String? phoneNumber,
    int? groupId,
    Uint8List? imageBytes,
    String? imageName,
  }) async {
    final token = await _getToken();
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/dashboard/students'));
    request.headers['Authorization'] = 'Bearer $token';

    request.fields['fullName'] = fullName;
    if (patronymic != null) request.fields['patronymic'] = patronymic;
    request.fields['username'] = username;
    request.fields['password'] = password;
    if (phoneNumber != null) request.fields['phoneNumber'] = phoneNumber;
    if (groupId != null) request.fields['groupId'] = groupId.toString();

    if (imageBytes != null && imageName != null) {
      request.files.add(http.MultipartFile.fromBytes('faceImage', imageBytes, filename: imageName));
    }

    final response = await request.send();
    return response.statusCode == 200;
  }

  Future<bool> updateStudent({
    required int id,
    required String fullName,
    String? patronymic,
    required String username,
    String? phoneNumber,
    int? groupId,
    Uint8List? imageBytes,
    String? imageName,
  }) async {
    final token = await _getToken();
    var request = http.MultipartRequest('PUT', Uri.parse('$baseUrl/dashboard/students/$id'));
    request.headers['Authorization'] = 'Bearer $token';

    request.fields['fullName'] = fullName;
    if (patronymic != null) request.fields['patronymic'] = patronymic;
    request.fields['username'] = username;
    if (phoneNumber != null) request.fields['phoneNumber'] = phoneNumber;
    if (groupId != null) request.fields['groupId'] = groupId.toString();

    if (imageBytes != null && imageName != null) {
      request.files.add(http.MultipartFile.fromBytes('faceImage', imageBytes, filename: imageName));
    }

    final response = await request.send();
    return response.statusCode == 200;
  }

  Future<bool> toggleStudentStatus(int id) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/dashboard/students/$id/toggle-status'),
      headers: await _getHeaders(),
    );
    return response.statusCode == 200;
  }

  Future<bool> deleteStudent(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/dashboard/students/$id'),
      headers: await _getHeaders(),
    );
    return response.statusCode == 204;
  }

  // Admins
  Future<List<Map<String, dynamic>>> getAdmins({String? searchTerm}) async {
    final queryParams = <String, String>{};
    if (searchTerm != null && searchTerm.isNotEmpty) queryParams['searchTerm'] = searchTerm;

    final uri = Uri.parse('$baseUrl/dashboard/admins').replace(queryParameters: queryParams);
    
    final response = await http.get(
      uri,
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    }
    return [];
  }

  Future<bool> createAdmin({
    required String fullName,
    required String username,
    required String password,
    String? phoneNumber,
    int roleId = 1,
    Uint8List? imageBytes,
    String? imageName,
  }) async {
    final token = await _getToken();
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/dashboard/admins'));
    request.headers['Authorization'] = 'Bearer $token';

    request.fields['fullName'] = fullName;
    request.fields['username'] = username;
    request.fields['password'] = password;
    request.fields['roleId'] = roleId.toString();
    if (phoneNumber != null) request.fields['phoneNumber'] = phoneNumber;

    if (imageBytes != null && imageName != null) {
      request.files.add(http.MultipartFile.fromBytes('image', imageBytes, filename: imageName));
    }

    final response = await request.send();
    return response.statusCode == 200;
  }

  Future<bool> changeAdminRole(int id, int roleId) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/dashboard/admins/$id/change-role'),
      headers: await _getHeaders(),
      body: jsonEncode({'roleId': roleId}),
    );
    return response.statusCode == 200;
  }

  Future<bool> toggleAdminStatus(int id) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/dashboard/admins/$id/toggle-status'),
      headers: await _getHeaders(),
    );
    return response.statusCode == 200;
  }

  Future<bool> deleteAdmin(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/dashboard/admins/$id'),
      headers: await _getHeaders(),
    );
    return response.statusCode == 204;
  }

  Future<bool> resetAdminPassword(int id, String newPassword) async {
    final response = await http.post(
      Uri.parse('$baseUrl/dashboard/admins/$id/reset-password'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'newPassword': newPassword,
      }),
    );
    return response.statusCode == 200;
  }

  Future<Map<String, dynamic>> getSessions({int page = 1, int limit = 10, String query = '', DateTime? startDate, DateTime? endDate}) async {
    String url = '$baseUrl/sessions?page=$page&limit=$limit&search=$query';
    if (startDate != null) {
      url += '&startDate=${startDate.toIso8601String()}';
    }
    if (endDate != null) {
      url += '&endDate=${endDate.toIso8601String()}';
    }
    
    final uri = Uri.parse(url);
    final response = await http.get(uri, headers: await _getHeaders());
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final List sessions = json['sessions'];
      return {
        'sessions': sessions.map((s) => UserSession.fromJson(s)).toList(),
        'totalCount': json['totalCount'],
      };
    }
    return {'sessions': <UserSession>[], 'totalCount': 0};
  }
}
