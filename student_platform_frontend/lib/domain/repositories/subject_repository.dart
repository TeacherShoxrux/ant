import '../../data/models/subject.dart';
import '../../data/models/topic.dart';

abstract class SubjectRepository {
  Future<List<Subject>> getSubjects();
  Future<List<Topic>> getTopics(int subjectId);
  Future<bool> createSubject(String name, String description);
  Future<bool> updateSubject(int id, String name, String description, bool isDisabled);
  Future<bool> deleteSubject(int id);
}
