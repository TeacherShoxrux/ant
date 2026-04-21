// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_service.dart';

// **************************************************************************
// ChopperGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
final class _$ApiService extends ApiService {
  _$ApiService([ChopperClient? client]) {
    if (client == null) return;
    this.client = client;
  }

  @override
  final Type definitionType = ApiService;

  @override
  Future<Response<dynamic>> login(Map<String, dynamic> body) {
    final Uri $url = Uri.parse('/api/auth/login');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> faceLogin(List<int> imageBytes) {
    final Uri $url = Uri.parse('/api/auth/face-login');
    final List<PartValue> $parts = <PartValue>[
      PartValueFile<List<int>>(
        'faceImage',
        imageBytes,
      )
    ];
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      parts: $parts,
      multipart: true,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> register(Map<String, dynamic> body) {
    final Uri $url = Uri.parse('/api/auth/register');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> changePassword(Map<String, dynamic> body) {
    final Uri $url = Uri.parse('/api/auth/change-password');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> getSubjects() {
    final Uri $url = Uri.parse('/api/subjects');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> getTopics(int subjectId) {
    final Uri $url = Uri.parse('/api/topics/subject/${subjectId}');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> getTestQuestions(int topicId) {
    final Uri $url = Uri.parse('/api/tests/topic/${topicId}');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> submitQuiz(Map<String, dynamic> body) {
    final Uri $url = Uri.parse('/api/quizzes/submit');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> getAssignments(int topicId) {
    final Uri $url = Uri.parse('/api/assignments/topic/${topicId}');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> getMySubmissions() {
    final Uri $url = Uri.parse('/api/assignments/my-submissions');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> createSubject(Map<String, dynamic> body) {
    final Uri $url = Uri.parse('/api/subjects');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> updateSubject(
    int id,
    Map<String, dynamic> body,
  ) {
    final Uri $url = Uri.parse('/api/subjects/${id}');
    final $body = body;
    final Request $request = Request(
      'PUT',
      $url,
      client.baseUrl,
      body: $body,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> toggleSubjectStatus(int id) {
    final Uri $url = Uri.parse('/api/subjects/${id}/toggle-status');
    final Request $request = Request(
      'PATCH',
      $url,
      client.baseUrl,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> deleteSubject(int id) {
    final Uri $url = Uri.parse('/api/subjects/${id}');
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> getSubjectGroups(int subjectId) {
    final Uri $url = Uri.parse('/api/subjects/${subjectId}/groups');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> attachSubjectToGroups(
    int subjectId,
    List<int> groupIds,
  ) {
    final Uri $url = Uri.parse('/api/subjects/${subjectId}/groups');
    final $body = groupIds;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> createTopic(Map<String, dynamic> body) {
    final Uri $url = Uri.parse('/api/topics');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> updateTopic(
    int topicId,
    Map<String, dynamic> body,
  ) {
    final Uri $url = Uri.parse('/api/topics/${topicId}');
    final $body = body;
    final Request $request = Request(
      'PUT',
      $url,
      client.baseUrl,
      body: $body,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> toggleTopicStatus(int topicId) {
    final Uri $url = Uri.parse('/api/topics/${topicId}/toggle-status');
    final Request $request = Request(
      'PATCH',
      $url,
      client.baseUrl,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> deleteTopic(int topicId) {
    final Uri $url = Uri.parse('/api/topics/${topicId}');
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> addTopicVideo(
    int topicId,
    Map<String, dynamic> body,
  ) {
    final Uri $url = Uri.parse('/api/topics/${topicId}/videos');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> getTopic(int id) {
    final Uri $url = Uri.parse('/api/topics/${id}');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> uploadTopicDocument(
    int topicId,
    String title,
    List<int> fileBytes,
  ) {
    final Uri $url = Uri.parse('/api/topics/${topicId}/documents');
    final List<PartValue> $parts = <PartValue>[
      PartValue<String>(
        'title',
        title,
      ),
      PartValueFile<List<int>>(
        'file',
        fileBytes,
      ),
    ];
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      parts: $parts,
      multipart: true,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> createAssignment(
    int topicId,
    String title,
    String description,
    int maxScore,
    String? deadline,
    List<int>? fileBytes,
  ) {
    final Uri $url = Uri.parse('/api/assignments');
    final List<PartValue> $parts = <PartValue>[
      PartValue<int>(
        'topicId',
        topicId,
      ),
      PartValue<String>(
        'title',
        title,
      ),
      PartValue<String>(
        'description',
        description,
      ),
      PartValue<int>(
        'maxScore',
        maxScore,
      ),
      PartValue<String?>(
        'deadline',
        deadline,
      ),
      PartValueFile<List<int>?>(
        'file',
        fileBytes,
      ),
    ];
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      parts: $parts,
      multipart: true,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> updateAssignment(
    int id,
    String title,
    String description,
    int maxScore,
    String? deadline,
    List<int>? fileBytes,
  ) {
    final Uri $url = Uri.parse('/api/assignments/update/${id}');
    final List<PartValue> $parts = <PartValue>[
      PartValue<String>(
        'title',
        title,
      ),
      PartValue<String>(
        'description',
        description,
      ),
      PartValue<int>(
        'maxScore',
        maxScore,
      ),
      PartValue<String?>(
        'deadline',
        deadline,
      ),
      PartValueFile<List<int>?>(
        'file',
        fileBytes,
      ),
    ];
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      parts: $parts,
      multipart: true,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> submitAssignment(
    int assignmentId,
    String? comment,
    List<int> fileBytes,
  ) {
    final Uri $url = Uri.parse('/api/assignments/submit/${assignmentId}');
    final List<PartValue> $parts = <PartValue>[
      PartValue<String?>(
        'studentComment',
        comment,
      ),
      PartValueFile<List<int>>(
        'file',
        fileBytes,
      ),
    ];
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      parts: $parts,
      multipart: true,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> getTopicSubmissions(int topicId) {
    final Uri $url =
        Uri.parse('/api/assignments/topic/${topicId}/all-submissions');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> gradeSubmission(
    int submissionId,
    Map<String, dynamic> body,
  ) {
    final Uri $url = Uri.parse('/api/assignments/grade/${submissionId}');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> createQuiz(
    int topicId,
    String title,
    String content,
    int timeLimitMinutes,
    List<int>? imageBytes,
  ) {
    final Uri $url = Uri.parse('/api/quizzes');
    final List<PartValue> $parts = <PartValue>[
      PartValue<int>(
        'topicId',
        topicId,
      ),
      PartValue<String>(
        'title',
        title,
      ),
      PartValue<String>(
        'content',
        content,
      ),
      PartValue<int>(
        'timeLimitMinutes',
        timeLimitMinutes,
      ),
      PartValueFile<List<int>?>(
        'image',
        imageBytes,
      ),
    ];
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      parts: $parts,
      multipart: true,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> addQuestionToQuiz(
    int quizId,
    String title,
    String question,
    String optionsJson,
    List<int>? imageBytes,
  ) {
    final Uri $url = Uri.parse('/api/quizzes/${quizId}/questions');
    final List<PartValue> $parts = <PartValue>[
      PartValue<String>(
        'title',
        title,
      ),
      PartValue<String>(
        'question',
        question,
      ),
      PartValue<String>(
        'optionsJson',
        optionsJson,
      ),
      PartValueFile<List<int>?>(
        'image',
        imageBytes,
      ),
    ];
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      parts: $parts,
      multipart: true,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> getQuizzes(int topicId) {
    final Uri $url = Uri.parse('/api/quizzes/topic/${topicId}');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> getQuizQuestions(int quizId) {
    final Uri $url = Uri.parse('/api/quizzes/${quizId}/questions');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> getQuizResults(int quizId) {
    final Uri $url = Uri.parse('/api/quizzes/${quizId}/results');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> getStats() {
    final Uri $url = Uri.parse('/api/dashboard/stats');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> getStudents(Map<String, dynamic> query) {
    final Uri $url = Uri.parse('/api/dashboard/students');
    final Map<String, dynamic> $params = query;
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> getSubjectGrades(int subjectId) {
    final Uri $url = Uri.parse('/api/dashboard/grades/${subjectId}');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> getTopicGradesAdmin(int topicId) {
    final Uri $url = Uri.parse('/api/dashboard/grades/topic/${topicId}');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> getGroups() {
    final Uri $url = Uri.parse('/api/dashboard/groups');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> createGroup(Map<String, dynamic> body) {
    final Uri $url = Uri.parse('/api/dashboard/groups');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> createStudent(
    String fullName,
    String? patronymic,
    String username,
    String password,
    String? phoneNumber,
    int? groupId,
    List<int>? imageBytes,
  ) {
    final Uri $url = Uri.parse('/api/dashboard/students');
    final List<PartValue> $parts = <PartValue>[
      PartValue<String>(
        'fullName',
        fullName,
      ),
      PartValue<String?>(
        'patronymic',
        patronymic,
      ),
      PartValue<String>(
        'username',
        username,
      ),
      PartValue<String>(
        'password',
        password,
      ),
      PartValue<String?>(
        'phoneNumber',
        phoneNumber,
      ),
      PartValue<int?>(
        'groupId',
        groupId,
      ),
      PartValueFile<List<int>?>(
        'faceImage',
        imageBytes,
      ),
    ];
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      parts: $parts,
      multipart: true,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> updateStudent(
    int id,
    String fullName,
    String? patronymic,
    String username,
    String? phoneNumber,
    int? groupId,
    List<int>? imageBytes,
  ) {
    final Uri $url = Uri.parse('/api/dashboard/students/${id}');
    final List<PartValue> $parts = <PartValue>[
      PartValue<String>(
        'fullName',
        fullName,
      ),
      PartValue<String?>(
        'patronymic',
        patronymic,
      ),
      PartValue<String>(
        'username',
        username,
      ),
      PartValue<String?>(
        'phoneNumber',
        phoneNumber,
      ),
      PartValue<int?>(
        'groupId',
        groupId,
      ),
      PartValueFile<List<int>?>(
        'faceImage',
        imageBytes,
      ),
    ];
    final Request $request = Request(
      'PUT',
      $url,
      client.baseUrl,
      parts: $parts,
      multipart: true,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> toggleStudentStatus(int id) {
    final Uri $url = Uri.parse('/api/dashboard/students/${id}/toggle-status');
    final Request $request = Request(
      'PATCH',
      $url,
      client.baseUrl,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> deleteStudent(int id) {
    final Uri $url = Uri.parse('/api/dashboard/students/${id}');
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> getAdmins(Map<String, dynamic> query) {
    final Uri $url = Uri.parse('/api/dashboard/admins');
    final Map<String, dynamic> $params = query;
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> createAdmin(
    String fullName,
    String username,
    String password,
    String? phoneNumber,
    int roleId,
    List<int>? imageBytes,
  ) {
    final Uri $url = Uri.parse('/api/dashboard/admins');
    final List<PartValue> $parts = <PartValue>[
      PartValue<String>(
        'fullName',
        fullName,
      ),
      PartValue<String>(
        'username',
        username,
      ),
      PartValue<String>(
        'password',
        password,
      ),
      PartValue<String?>(
        'phoneNumber',
        phoneNumber,
      ),
      PartValue<int>(
        'roleId',
        roleId,
      ),
      PartValueFile<List<int>?>(
        'image',
        imageBytes,
      ),
    ];
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      parts: $parts,
      multipart: true,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> changeAdminRole(
    int id,
    Map<String, dynamic> body,
  ) {
    final Uri $url = Uri.parse('/api/dashboard/admins/${id}/change-role');
    final $body = body;
    final Request $request = Request(
      'PATCH',
      $url,
      client.baseUrl,
      body: $body,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> toggleAdminStatus(int id) {
    final Uri $url = Uri.parse('/api/dashboard/admins/${id}/toggle-status');
    final Request $request = Request(
      'PATCH',
      $url,
      client.baseUrl,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> deleteAdmin(int id) {
    final Uri $url = Uri.parse('/api/dashboard/admins/${id}');
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> resetAdminPassword(
    int id,
    Map<String, dynamic> body,
  ) {
    final Uri $url = Uri.parse('/api/dashboard/admins/${id}/reset-password');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> getSessions(Map<String, dynamic> query) {
    final Uri $url = Uri.parse('/api/sessions');
    final Map<String, dynamic> $params = query;
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> getNotifications() {
    final Uri $url = Uri.parse('/api/notifications');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> createNotification(Map<String, dynamic> body) {
    final Uri $url = Uri.parse('/api/notifications');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
    );
    return client.send<dynamic, dynamic>($request);
  }
}
