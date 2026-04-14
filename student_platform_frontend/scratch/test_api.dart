import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  var baseUrl = 'http://localhost:5297/api';
  
  // Login
  var loginRes = await http.post(
    Uri.parse('$baseUrl/auth/login'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'username': 'admin', 'password': 'admin123'})
  );
  if (loginRes.statusCode != 200) {
    print('Login failed: ${loginRes.body}');
    return;
  }
  var token = jsonDecode(loginRes.body)['token'];
  var headers = {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'};

  // Get subjects
  var subRes = await http.get(Uri.parse('$baseUrl/subjects'), headers: headers);
  var subjects = jsonDecode(subRes.body);
  if (subjects.isEmpty) { print('No subjects'); return; }
  var subjectId = subjects[0]['id'];

  // Get topics
  var topRes = await http.get(Uri.parse('$baseUrl/topics/subject/$subjectId'), headers: headers);
  var topics = jsonDecode(topRes.body);
  if (topics.isEmpty) { print('No topics'); return; }
  var topicId = topics[0]['id'];

  // Get quizzes
  var quizRes = await http.get(Uri.parse('$baseUrl/quizzes/topic/$topicId'), headers: headers);
  var quizzes = jsonDecode(quizRes.body);
  if (quizzes.isEmpty) { print('No quizzes'); return; }
  var quizId = quizzes[0]['id'];

  // Get questions
  var qRes = await http.get(Uri.parse('$baseUrl/quizzes/$quizId/questions'), headers: headers);
  var questions = jsonDecode(qRes.body);

  var answers = [];
  for (var q in questions) {
    if (q['options'] != null && q['options'].isNotEmpty) {
      answers.add({
        'questionId': q['id'],
        'selectedOptionId': q['options'][0]['id']
      });
    }
  }

  // Submit
  print('Submitting quiz $quizId with ${answers.length} answers');
  var submitRes = await http.post(
    Uri.parse('$baseUrl/quizzes/submit'),
    headers: headers,
    body: jsonEncode({'quizId': quizId, 'answers': answers})
  );
  
  print('Status: ${submitRes.statusCode}');
  print('Body: ${submitRes.body}');
}
