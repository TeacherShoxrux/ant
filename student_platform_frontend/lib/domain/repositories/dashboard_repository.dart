abstract class DashboardRepository {
  Future<Map<String, dynamic>> getStats();
  Future<Map<String, dynamic>> getStudents({int pageNumber = 1, int pageSize = 10, String? searchTerm, int? groupId});
  Future<List<Map<String, dynamic>>> getGroups();
  Future<Map<String, dynamic>?> createGroup(String name);
  Future<bool> deleteStudent(int id);
  Future<bool> toggleStudentStatus(int id);
}
