import '../../domain/repositories/dashboard_repository.dart';
import '../data_sources/remote/api_service.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final ApiService _apiService;

  DashboardRepositoryImpl(this._apiService);

  @override
  Future<Map<String, dynamic>> getStats() async {
    final response = await _apiService.getStats();
    if (response.isSuccessful && response.body != null) {
      return response.body as Map<String, dynamic>;
    }
    return {};
  }

  @override
  Future<Map<String, dynamic>> getStudents({
    int pageNumber = 1,
    int pageSize = 10,
    String? searchTerm,
    int? groupId,
  }) async {
    final Map<String, dynamic> query = {
      'pageNumber': pageNumber,
      'pageSize': pageSize,
    };
    if (searchTerm != null) query['searchTerm'] = searchTerm;
    if (groupId != null) query['groupId'] = groupId;

    final response = await _apiService.getStudents(query);
    if (response.isSuccessful && response.body != null) {
      return response.body as Map<String, dynamic>;
    }
    return {'items': [], 'totalCount': 0, 'totalPages': 0};
  }

  @override
  Future<List<Map<String, dynamic>>> getGroups() async {
    final response = await _apiService.getGroups();
    if (response.isSuccessful && response.body != null) {
      return List<Map<String, dynamic>>.from(response.body as List);
    }
    return [];
  }

  @override
  Future<Map<String, dynamic>?> createGroup(String name) async {
    final response = await _apiService.createGroup({'name': name});
    if (response.isSuccessful && response.body != null) {
      return response.body as Map<String, dynamic>;
    }
    return null;
  }

  @override
  Future<bool> deleteStudent(int id) async {
    final response = await _apiService.deleteStudent(id);
    return response.isSuccessful;
  }

  @override
  Future<bool> toggleStudentStatus(int id) async {
    final response = await _apiService.toggleStudentStatus(id);
    return response.isSuccessful;
  }
}
