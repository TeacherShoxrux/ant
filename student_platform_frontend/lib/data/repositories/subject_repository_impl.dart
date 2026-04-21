import '../../domain/repositories/subject_repository.dart';
import '../data_sources/remote/api_service.dart';
import '../models/subject.dart';
import '../models/topic.dart';

class SubjectRepositoryImpl implements SubjectRepository {
  final ApiService _apiService;

  SubjectRepositoryImpl(this._apiService);

  @override
  Future<List<Subject>> getSubjects() async {
    final response = await _apiService.getSubjects();
    if (response.isSuccessful && response.body != null) {
      return (response.body as List).map((e) => Subject.fromJson(e)).toList();
    }
    return [];
  }

  @override
  Future<List<Topic>> getTopics(int subjectId) async {
    final response = await _apiService.getTopics(subjectId);
    if (response.isSuccessful && response.body != null) {
      return (response.body as List).map((e) => Topic.fromJson(e)).toList();
    }
    return [];
  }

  @override
  Future<bool> createSubject(String name, String description) async {
    final response = await _apiService.createSubject({
      'name': name,
      'description': description,
    });
    return response.isSuccessful;
  }

  @override
  Future<bool> updateSubject(int id, String name, String description, bool isDisabled) async {
    final response = await _apiService.updateSubject(id, {
      'name': name,
      'description': description,
      'isDisabled': isDisabled,
    });
    return response.isSuccessful;
  }

  @override
  Future<bool> deleteSubject(int id) async {
    final response = await _apiService.deleteSubject(id);
    return response.isSuccessful;
  }
}
