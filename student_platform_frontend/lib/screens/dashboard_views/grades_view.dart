import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';
import 'package:flutter_animate/flutter_animate.dart';

class GradesScreen extends StatefulWidget {
  const GradesScreen({super.key});

  @override
  State<GradesScreen> createState() => _GradesScreenState();
}

class _GradesScreenState extends State<GradesScreen> {
  final ApiService _apiService = ApiService();
  List<Subject>? _subjects;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSubjects();
  }

  Future<void> _fetchSubjects() async {
    final subjects = await _apiService.getSubjects();
    if (mounted) {
      setState(() {
        _subjects = subjects;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_subjects == null || _subjects!.isEmpty) {
      return const Center(child: Text('Baholar topilmadi.'));
    }

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'O\'zlashtirish jurnali',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
          ).animate().fadeIn().slideY(begin: 0.2),
          const SizedBox(height: 8),
          Text(
            'Barcha fanlardan yakuniy natijalar',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 32),
          
          Expanded(
            child: ListView.builder(
              itemCount: _subjects!.length,
              itemBuilder: (context, index) {
                final subject = _subjects![index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: const Color(0xFF1E3A8A).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.school, color: Color(0xFF1E3A8A)),
                        ),
                        title: Text(subject.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        subtitle: Text('Batafsil', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                        children: [
                          FutureBuilder<List<Map<String, dynamic>>>(
                            future: _apiService.getSubjectGrades(subject.id),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator());
                              }
                              final grades = snapshot.data ?? [];
                              if (grades.isEmpty) {
                                return const Padding(padding: EdgeInsets.all(16), child: Text('Hozircha baholar yo\'q'));
                              }
                              return Column(
                                children: grades.map((g) {
                                  final bool isQuiz = g['type'] == 'Quiz';
                                  final Color color = isQuiz ? Colors.purple : Colors.green;
                                  final grade = g['grade'];
                                  final maxScore = g['maxScore'] ?? 100;

                                  return ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                                    leading: Icon(isQuiz ? Icons.timer : Icons.assignment_turned_in, color: color, size: 20),
                                    title: Text(g['title'] ?? 'Nomsiz', style: const TextStyle(fontSize: 14)),
                                    subtitle: Text(g['date']?.toString().split('T')[0] ?? '', style: const TextStyle(fontSize: 12)),
                                    trailing: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                                      child: Text(
                                        grade != null ? '$grade / $maxScore' : 'Baholanmagan',
                                        style: TextStyle(color: color, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              );
                            },
                          )
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: Duration(milliseconds: 100 * index)).slideX(begin: 0.1),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
