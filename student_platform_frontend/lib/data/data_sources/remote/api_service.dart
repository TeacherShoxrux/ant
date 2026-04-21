import 'package:chopper/chopper.dart';
import 'package:http/http.dart' show MultipartFile;

part 'api_service.chopper.dart';

@ChopperApi(baseUrl: "/api")
abstract class ApiService extends ChopperService {
  static ApiService create([ChopperClient? client]) => _$ApiService(client);

  @Post(path: 'auth/login')
  Future<Response> login(@Body() Map<String, dynamic> body);

  @Post(path: 'auth/face-login')
  @Multipart()
  Future<Response> faceLogin(@PartFile('faceImage') List<int> imageBytes);

  @Post(path: 'auth/register')
  Future<Response> register(@Body() Map<String, dynamic> body);

  @Post(path: 'auth/change-password')
  Future<Response> changePassword(@Body() Map<String, dynamic> body);

  @Get(path: 'subjects')
  Future<Response> getSubjects();

  @Get(path: 'topics/subject/{id}')
  Future<Response> getTopics(@Path('id') int subjectId);

  @Get(path: 'tests/topic/{id}')
  Future<Response> getTestQuestions(@Path('id') int topicId);

  @Post(path: 'quizzes/submit')
  Future<Response> submitQuiz(@Body() Map<String, dynamic> body);

  @Get(path: 'assignments/topic/{id}')
  Future<Response> getAssignments(@Path('id') int topicId);

  @Get(path: 'assignments/my-submissions')
  Future<Response> getMySubmissions();

  // Subjects Admin
  @Post(path: 'subjects')
  Future<Response> createSubject(@Body() Map<String, dynamic> body);

  @Put(path: 'subjects/{id}')
  Future<Response> updateSubject(@Path('id') int id, @Body() Map<String, dynamic> body);

  @Patch(path: 'subjects/{id}/toggle-status')
  Future<Response> toggleSubjectStatus(@Path('id') int id);

  @Delete(path: 'subjects/{id}')
  Future<Response> deleteSubject(@Path('id') int id);

  @Get(path: 'subjects/{id}/groups')
  Future<Response> getSubjectGroups(@Path('id') int subjectId);

  @Post(path: 'subjects/{id}/groups')
  Future<Response> attachSubjectToGroups(@Path('id') int subjectId, @Body() List<int> groupIds);

  // Topics Admin
  @Post(path: 'topics')
  Future<Response> createTopic(@Body() Map<String, dynamic> body);

  @Put(path: 'topics/{id}')
  Future<Response> updateTopic(@Path('id') int topicId, @Body() Map<String, dynamic> body);

  @Patch(path: 'topics/{id}/toggle-status')
  Future<Response> toggleTopicStatus(@Path('id') int topicId);

  @Delete(path: 'topics/{id}')
  Future<Response> deleteTopic(@Path('id') int topicId);

  @Post(path: 'topics/{id}/videos')
  Future<Response> addTopicVideo(@Path('id') int topicId, @Body() Map<String, dynamic> body);

  @Get(path: 'topics/{id}')
  Future<Response> getTopic(@Path('id') int id);

  @Post(path: 'topics/{id}/documents')
  @Multipart()
  Future<Response> uploadTopicDocument(
    @Path('id') int topicId,
    @Part('title') String title,
    @PartFile('file') List<int> fileBytes,
  );

  // Assignments Admin
  @Post(path: 'assignments')
  @Multipart()
  Future<Response> createAssignment(
    @Part('topicId') int topicId,
    @Part('title') String title,
    @Part('description') String description,
    @Part('maxScore') int maxScore,
    @Part('deadline') String? deadline,
    @PartFile('file') List<int>? fileBytes,
  );

  @Post(path: 'assignments/update/{id}')
  @Multipart()
  Future<Response> updateAssignment(
    @Path('id') int id,
    @Part('title') String title,
    @Part('description') String description,
    @Part('maxScore') int maxScore,
    @Part('deadline') String? deadline,
    @PartFile('file') List<int>? fileBytes,
  );

  @Post(path: 'assignments/submit/{id}')
  @Multipart()
  Future<Response> submitAssignment(
    @Path('id') int assignmentId,
    @Part('studentComment') String? comment,
    @PartFile('file') List<int> fileBytes,
  );

  @Get(path: 'assignments/topic/{id}/all-submissions')
  Future<Response> getTopicSubmissions(@Path('id') int topicId);

  @Post(path: 'assignments/grade/{id}')
  Future<Response> gradeSubmission(@Path('id') int submissionId, @Body() Map<String, dynamic> body);

  // Quizzes Admin
  @Post(path: 'quizzes')
  @Multipart()
  Future<Response> createQuiz(
    @Part('topicId') int topicId,
    @Part('title') String title,
    @Part('content') String content,
    @Part('timeLimitMinutes') int timeLimitMinutes,
    @PartFile('image') List<int>? imageBytes,
  );

  @Post(path: 'quizzes/{id}/questions')
  @Multipart()
  Future<Response> addQuestionToQuiz(
    @Path('id') int quizId,
    @Part('title') String title,
    @Part('question') String question,
    @Part('optionsJson') String optionsJson,
    @PartFile('image') List<int>? imageBytes,
  );

  @Get(path: 'quizzes/topic/{id}')
  Future<Response> getQuizzes(@Path('id') int topicId);

  @Get(path: 'quizzes/{id}/questions')
  Future<Response> getQuizQuestions(@Path('id') int quizId);

  @Get(path: 'quizzes/{id}/results')
  Future<Response> getQuizResults(@Path('id') int quizId);

  // Dashboard
  @Get(path: 'dashboard/stats')
  Future<Response> getStats();

  @Get(path: 'dashboard/students')
  Future<Response> getStudents(@QueryMap() Map<String, dynamic> query);

  @Get(path: 'dashboard/grades/{id}')
  Future<Response> getSubjectGrades(@Path('id') int subjectId);

  @Get(path: 'dashboard/grades/topic/{id}')
  Future<Response> getTopicGradesAdmin(@Path('id') int topicId);

  @Get(path: 'dashboard/groups')
  Future<Response> getGroups();

  @Post(path: 'dashboard/groups')
  Future<Response> createGroup(@Body() Map<String, dynamic> body);

  @Post(path: 'dashboard/students')
  @Multipart()
  Future<Response> createStudent(
    @Part('fullName') String fullName,
    @Part('patronymic') String? patronymic,
    @Part('username') String username,
    @Part('password') String password,
    @Part('phoneNumber') String? phoneNumber,
    @Part('groupId') int? groupId,
    @PartFile('faceImage') List<int>? imageBytes,
  );

  @Put(path: 'dashboard/students/{id}')
  @Multipart()
  Future<Response> updateStudent(
    @Path('id') int id,
    @Part('fullName') String fullName,
    @Part('patronymic') String? patronymic,
    @Part('username') String username,
    @Part('phoneNumber') String? phoneNumber,
    @Part('groupId') int? groupId,
    @PartFile('faceImage') List<int>? imageBytes,
  );

  @Patch(path: 'dashboard/students/{id}/toggle-status')
  Future<Response> toggleStudentStatus(@Path('id') int id);

  @Delete(path: 'dashboard/students/{id}')
  Future<Response> deleteStudent(@Path('id') int id);

  // Admins
  @Get(path: 'dashboard/admins')
  Future<Response> getAdmins(@QueryMap() Map<String, dynamic> query);

  @Post(path: 'dashboard/admins')
  @Multipart()
  Future<Response> createAdmin(
    @Part('fullName') String fullName,
    @Part('username') String username,
    @Part('password') String password,
    @Part('phoneNumber') String? phoneNumber,
    @Part('roleId') int roleId,
    @PartFile('image') List<int>? imageBytes,
  );

  @Patch(path: 'dashboard/admins/{id}/change-role')
  Future<Response> changeAdminRole(@Path('id') int id, @Body() Map<String, dynamic> body);

  @Patch(path: 'dashboard/admins/{id}/toggle-status')
  Future<Response> toggleAdminStatus(@Path('id') int id);

  @Delete(path: 'dashboard/admins/{id}')
  Future<Response> deleteAdmin(@Path('id') int id);

  @Post(path: 'dashboard/admins/{id}/reset-password')
  Future<Response> resetAdminPassword(@Path('id') int id, @Body() Map<String, dynamic> body);

  @Get(path: 'sessions')
  Future<Response> getSessions(@QueryMap() Map<String, dynamic> query);

  // Notifications
  @Get(path: 'notifications')
  Future<Response> getNotifications();

  @Post(path: 'notifications')
  Future<Response> createNotification(@Body() Map<String, dynamic> body);

  @HttpPatch(path: 'notifications/{id}/read')
  Future<Response> markAsRead(@Path('id') int id);

  @HttpPatch(path: 'notifications/read-all')
  Future<Response> markAllAsRead();
}

