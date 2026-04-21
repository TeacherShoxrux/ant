import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/subject_repository.dart';
import 'subject_state.dart';

class SubjectCubit extends Cubit<SubjectState> {
  final SubjectRepository _subjectRepository;

  SubjectCubit(this._subjectRepository) : super(SubjectInitial());

  Future<void> fetchSubjects() async {
    emit(SubjectLoading());
    try {
      final subjects = await _subjectRepository.getSubjects();
      emit(SubjectsLoaded(subjects));
    } catch (e) {
      emit(SubjectError(e.toString()));
    }
  }

  Future<void> createSubject(String name, String description) async {
    try {
      final success = await _subjectRepository.createSubject(name, description);
      if (success) {
        fetchSubjects();
      } else {
        emit(const SubjectError('Fanni yaratishda xatolik'));
      }
    } catch (e) {
      emit(SubjectError(e.toString()));
    }
  }
}
