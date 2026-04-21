import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/auth/auth_cubit.dart';
import '../../logic/auth/auth_state.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../widgets/responsive_dialog.dart';

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

    final authState = context.read<AuthCubit>().state;
    final isAdmin = authState is AuthAuthenticated && authState.isAdmin;

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
            isAdmin ? 'Talabalar natijalarini kuzatish' : 'Barcha fanlardan yakuniy natijalar',
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
                      child: isAdmin 
                        ? _buildAdminSubjectTile(subject)
                        : _buildStudentSubjectTile(subject),
                    ),
                  ),
                ).animate().fadeIn(delay: Duration(milliseconds: 100 * index)).slideX(begin: 0.1);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentSubjectTile(Subject subject) {
    return ExpansionTile(
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
    );
  }

  Widget _buildAdminSubjectTile(Subject subject) {
    return ExpansionTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: const Color(0xFF1E3A8A).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: const Icon(Icons.folder_shared, color: Color(0xFF1E3A8A)),
      ),
      title: Text(subject.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      subtitle: Text('Mavzular bo\'ylab natijalarni ko\'rish', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
      trailing: IconButton(
        icon: const Icon(Icons.sim_card_download, color: Colors.green),
        tooltip: 'Excel Hisobot (Qaydnomani yuklash)',
        onPressed: () => _showExcelDownloadDialog(subject),
      ),
      children: [
        FutureBuilder<List<Topic>>(
          future: _apiService.getTopics(subject.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator());
            }
            final topics = snapshot.data ?? [];
            if (topics.isEmpty) {
              return const Padding(padding: EdgeInsets.all(16), child: Text('Mavzular mavjud emas.'));
            }
            return Column(
              children: topics.map((topic) {
                return ExpansionTile(
                  title: Text(topic.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  leading: const Icon(Icons.topic, size: 18),
                  children: [
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: _apiService.getTopicGradesAdmin(topic.id),
                      builder: (context, gSnapshot) {
                        if (gSnapshot.connectionState == ConnectionState.waiting) {
                          return const Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator());
                        }
                        final grades = gSnapshot.data ?? [];
                        if (grades.isEmpty) {
                          return const Padding(padding: EdgeInsets.all(16), child: Text('Hali hech kim topshirmagan.', style: TextStyle(fontSize: 12, color: Colors.grey)));
                        }
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: grades.length,
                          itemBuilder: (context, i) {
                            final g = grades[i];
                            final bool isQuiz = g['type'] == 'Quiz';
                            final Color color = isQuiz ? Colors.purple : Colors.green;
                            
                            return ListTile(
                              dense: true,
                              title: Text(g['studentName'] ?? 'Nomalum', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('${g['title']} (${isQuiz ? 'Test' : 'Topshiriq'})'),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                child: Text(
                                  '${g['grade']} / ${g['maxScore']}',
                                  style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  void _showExcelDownloadDialog(Subject subject) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );
    
    // Get all groups first
    try {
      final groups = await _apiService.getGroups();
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // Close loading safely
      _showGroupSelector(subject, groups);
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Xatolik: $e')));
      }
    }
  }

  void _showGroupSelector(Subject subject, List<Map<String, dynamic>> groups) {
    showDialog(
      context: context,
      builder: (ctx) => ResponsiveDialog(
        title: 'Qaysi guruh bo\'yicha hisobot kerak?',
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: groups.isEmpty
            ? const Center(child: Text('Guruhlar mavjud emas.'))
            : ListView.builder(
                shrinkWrap: true,
                itemCount: groups.length,
                itemBuilder: (context, index) {
                  final group = groups[index];
                  return ListTile(
                    leading: const Icon(Icons.group, color: Colors.indigo),
                    title: Text(group['name']),
                    trailing: const Icon(Icons.download, color: Colors.green, size: 20),
                    onTap: () async {
                      Navigator.pop(ctx);
                      _downloadReport(subject.id, group['id'], subject.name);
                    },
                  );
                },
              ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Bekor qilish')),
        ],
      )
    );
  }

  void _downloadReport(int subjectId, int groupId, String subjectName) async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hisobot yuklanmoqda kuting...')));
    try {
      await _apiService.downloadExcelReport(subjectId, groupId, subjectName);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hisobot yuklab olindi!')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }
}
