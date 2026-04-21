class AuthResponse {
  final String token;
  final String username;
  final String fullName;
  final String role;
  final String? imagePath;

  AuthResponse({
    required this.token,
    required this.username,
    required this.fullName,
    required this.role,
    this.imagePath,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'],
      username: json['username'],
      fullName: json['fullName'],
      role: json['role'],
      imagePath: json['imagePath'],
    );
  }
}

class Group {
  final int id;
  final String name;

  Group({required this.id, required this.name});

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'],
      name: json['name'],
    );
  }
}

class Subject {
  final int id;
  final String name;
  final String description;
  final bool isDisabled;

  Subject({
    required this.id, 
    required this.name, 
    required this.description,
    this.isDisabled = false,
  });

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      isDisabled: json['isDisabled'] ?? false,
    );
  }
}


class Topic {
  final int id;
  final int subjectId;
  final String title;
  final String content;
  final bool isDisabled;
  final List<TopicQuiz> quizzes;
  final List<Assignment> assignments;
  final List<TopicDocument> documents;
  final List<TopicVideo> videos;
  final String? createdByName;

  Topic({
    required this.id,
    required this.subjectId,
    required this.title,
    required this.content,
    this.isDisabled = false,
    this.quizzes = const [],
    this.assignments = const [],
    this.documents = const [],
    this.videos = const [],
    this.createdByName,
  });

  factory Topic.fromJson(Map<String, dynamic> json) {
    return Topic(
      id: json['id'],
      subjectId: json['subjectId'],
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      isDisabled: json['isDisabled'] ?? false,
      quizzes: json['quizzes'] != null
          ? (json['quizzes'] as List).map((i) => TopicQuiz.fromJson(i)).toList()
          : [],
      assignments: json['assignments'] != null
          ? (json['assignments'] as List).map((i) => Assignment.fromJson(i)).toList()
          : [],
      documents: (json['documents'] as List?)
              ?.map((d) => TopicDocument.fromJson(d))
              .toList() ??
          [],
      videos: (json['videos'] as List?)
              ?.map((v) => TopicVideo.fromJson(v))
              .toList() ??
          [],
      createdByName: json['createdByName'] ?? json['createdBy']?['fullName'],
    );
  }
}

class TopicVideo {
  final int id;
  final int topicId;
  final String title;
  final String youtubeUrl;
  final String? createdByName;

  TopicVideo({
    required this.id,
    required this.topicId,
    required this.title,
    required this.youtubeUrl,
    this.createdByName,
  });

  factory TopicVideo.fromJson(Map<String, dynamic> json) {
    return TopicVideo(
      id: json['id'],
      topicId: json['topicId'],
      title: json['title'] ?? '',
      youtubeUrl: json['youtubeUrl'] ?? '',
      createdByName: json['createdBy']?['fullName'],
    );
  }
}

class TopicDocument {
  final int id;
  final int topicId;
  final String title;
  final String filePath;
  final String fileName;

  TopicDocument({
    required this.id,
    required this.topicId,
    required this.title,
    required this.filePath,
    required this.fileName,
  });

  factory TopicDocument.fromJson(Map<String, dynamic> json) {
    return TopicDocument(
      id: json['id'],
      topicId: json['topicId'],
      title: json['title'] ?? '',
      filePath: json['filePath'] ?? '',
      fileName: json['fileName'] ?? '',
    );
  }
}

class TopicQuiz {
  final int id;
  final int topicId;
  final String title;
  final String content;
  final int timeLimitMinutes;
  final String? imagePath;
  final List<TestQuestion> questions;
  final String? createdByName;

  TopicQuiz({
    required this.id,
    required this.topicId,
    required this.title,
    required this.content,
    required this.timeLimitMinutes,
    this.imagePath,
    this.questions = const [],
    this.createdByName,
  });

  factory TopicQuiz.fromJson(Map<String, dynamic> json) {
    return TopicQuiz(
      id: json['id'],
      topicId: json['topicId'],
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      timeLimitMinutes: json['timeLimitMinutes'] ?? 0,
      imagePath: json['imagePath'],
      questions: json['questions'] != null
          ? (json['questions'] as List).map((i) => TestQuestion.fromJson(i)).toList()
          : [],
      createdByName: json['createdByName'] ?? json['createdBy']?['fullName'],
    );
  }
}

class TestQuestion {
  final int id;
  final int quizId;
  final String title;
  final String question;
  final String? imagePath;
  final List<TestOption> options;

  TestQuestion({
    required this.id,
    required this.quizId,
    required this.title,
    required this.question,
    this.imagePath,
    this.options = const [],
  });

  factory TestQuestion.fromJson(Map<String, dynamic> json) {
    return TestQuestion(
      id: json['id'],
      quizId: json['quizId'] ?? 0,
      title: json['title'] ?? '',
      question: json['question'] ?? '',
      imagePath: json['imagePath'],
      options: json['options'] != null
          ? (json['options'] as List).map((i) => TestOption.fromJson(i)).toList()
          : [],
    );
  }
}

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

  factory TestOption.fromJson(Map<String, dynamic> json) {
    return TestOption(
      id: json['id'],
      questionId: json['questionId'] ?? 0,
      optionText: json['optionText'] ?? '',
      isCorrect: json['isCorrect'] ?? false,
    );
  }
}

class Assignment {
  final int id;
  final int topicId;
  final String title;
  final String description;
  final int maxScore;
  final DateTime? deadline;
  final String? filePath;
  final bool isSubmitted;
  final int? grade;
  final String? gradedByName;
  final String? createdByName;

  Assignment({
    required this.id,
    required this.topicId,
    required this.title,
    required this.description,
    required this.maxScore,
    this.deadline,
    this.filePath,
    this.isSubmitted = false,
    this.grade,
    this.gradedByName,
    this.createdByName,
  });

  factory Assignment.fromJson(Map<String, dynamic> json) {
    return Assignment(
      id: json['id'],
      topicId: json['topicId'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      maxScore: json['maxScore'] ?? 0,
      deadline: json['deadline'] != null ? DateTime.parse(json['deadline']) : null,
      filePath: json['filePath'],
      isSubmitted: json['isSubmitted'] ?? false,
      grade: json['grade'],
      gradedByName: json['gradedByName'],
      createdByName: json['createdByName'],
    );
  }
}

class Submission {
  final int id;
  final String? assignmentTitle;
  final int? assignmentMaxScore;
  final String studentName;
  final String? studentComment;
  final String filePath;
  final DateTime submittedAt;
  final int? grade;
  final String? feedback;
  final String? gradedByName;

  Submission({
    required this.id,
    required this.assignmentTitle,
    this.assignmentMaxScore,
    required this.studentName,
    this.studentComment,
    required this.filePath,
    required this.submittedAt,
    this.grade,
    this.feedback,
    this.gradedByName,
  });

  factory Submission.fromJson(Map<String, dynamic> json) {
    return Submission(
      id: json['id'],
      assignmentTitle: json['assignment']?['title'] ?? 'Vazifa',
      assignmentMaxScore: json['assignment']?['maxScore'],
      studentName: json['student']?['fullName'] ?? 'Talaba',
      studentComment: json['studentComment'],
      filePath: json['filePath'],
      submittedAt: DateTime.parse(json['submittedAt'] ?? DateTime.now().toIso8601String()),
      grade: json['grade'],
      feedback: json['feedback'],
      gradedByName: json['gradedBy']?['fullName'],
    );
  }
}

class QuizResult {
  final String studentName;
  final int score;
  final int totalQuestions;
  final DateTime takenAt;

  QuizResult({
    required this.studentName,
    required this.score,
    required this.totalQuestions,
    required this.takenAt,
  });

  factory QuizResult.fromJson(Map<String, dynamic> json) {
    return QuizResult(
      studentName: json['studentName'] ?? 'Noma\'lum',
      score: json['score'] ?? 0,
      totalQuestions: json['totalQuestions'] ?? 0,
      takenAt: DateTime.parse(json['takenAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class UserSession {
  final int id;
  final int studentId;
  final String studentName;
  final String username;
  final String phone;
  final String roleName;
  final DateTime loginTime;
  final String? ipAddress;
  final String? deviceInfo;
  final String? locationInfo;
  final String? faceImagePath;

  UserSession({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.username,
    required this.phone,
    required this.roleName,
    required this.loginTime,
    this.ipAddress,
    this.deviceInfo,
    this.locationInfo,
    this.faceImagePath,
  });

  factory UserSession.fromJson(Map<String, dynamic> json) {
    return UserSession(
      id: json['id'],
      studentId: json['studentId'],
      studentName: json['studentName'] ?? 'Noma\'lum',
      username: json['username'] ?? 'Noma\'lum',
      phone: json['phone'] ?? 'Kiritilmagan',
      roleName: json['roleName'] ?? 'Foydalanuvchi',
      loginTime: DateTime.parse(json['loginTime']),
      ipAddress: json['ipAddress'],
      deviceInfo: json['deviceInfo'],
      locationInfo: json['locationInfo'],
      faceImagePath: json['faceImagePath'],
    );
  }
}

class NotificationModel {
  final int id;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final String? senderName;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.isRead,
    this.senderName,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      createdAt: DateTime.parse(json['createdAt']),
      isRead: json['isRead'],
      senderName: json['senderName'],
    );
  }
}

class OnlineMeeting {
  final int id;
  final int subjectId;
  final String title;
  final String meetingUrl;
  final DateTime startTime;
  final String? createdByName;

  OnlineMeeting({
    required this.id,
    required this.subjectId,
    required this.title,
    required this.meetingUrl,
    required this.startTime,
    this.createdByName,
  });

  factory OnlineMeeting.fromJson(Map<String, dynamic> json) {
    return OnlineMeeting(
      id: json['id'],
      subjectId: json['subjectId'],
      title: json['title'] ?? '',
      meetingUrl: json['meetingUrl'] ?? '',
      startTime: DateTime.parse(json['startTime']),
      createdByName: json['createdByName'],
    );
  }
}
