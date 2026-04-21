import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/auth/auth_cubit.dart';
import '../../logic/auth/auth_state.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../widgets/responsive_dialog.dart';
import 'package:student_platform_frontend/widgets/app_toast.dart';

class GradesScreen extends StatefulWidget {
  const GradesScreen({super.key});

  @override
  State<GradesScreen> createState() => _GradesScreenState();
}

class _GradesScreenState extends State<GradesScreen> {
  final ApiService _apiService = ApiService();
  List<Subject>? _subjects;
  bool _isLoading = true;

  // Pagination & Search
  int _currentPage = 1;
  int _pageSize = 10;
  int _totalCount = 0;
  int _totalPages = 0;
  String _searchTerm = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchSubjects();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchSubjects() async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiService.getSubjects(
        pageNumber: _currentPage,
        pageSize: _pageSize,
        searchTerm: _searchTerm,
      );
      if (mounted) {
        setState(() {
          final List items = data['items'] ?? [];
          _subjects = items.map((s) => Subject.fromJson(s)).toList();
          _totalCount = data['totalCount'] ?? 0;
          _totalPages = data['totalPages'] ?? 0;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppToast.show(context, 'Xatolik: $e', isError: true);
      }
    }
  }

  void _onSearch() {
    setState(() {
      _searchTerm = _searchController.text.trim();
      _currentPage = 1;
    });
    _fetchSubjects();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    final isAdmin = authState is AuthAuthenticated && authState.isAdmin;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final padding = isMobile ? 16.0 : 32.0;

        return Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'O\'zlashtirish jurnali',
                style: TextStyle(fontSize: isMobile ? 24 : 28, fontWeight: FontWeight.bold, color: const Color(0xFF1E3A8A)),
              ).animate().fadeIn().slideY(begin: 0.2),
              const SizedBox(height: 8),
              Text(
                isAdmin ? 'Talabalar natijalarini kuzatish' : 'Barcha fanlardan yakuniy natijalar',
                style: TextStyle(color: Colors.grey[600], fontSize: isMobile ? 14 : 16),
              ).animate().fadeIn(delay: 100.ms),
              const SizedBox(height: 32),
              
              // Search Bar
              Flex(
                direction: isMobile ? Axis.vertical : Axis.horizontal,
                children: [
                  Expanded(
                    flex: isMobile ? 0 : 1,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Fanlarni qidirish...',
                          prefixIcon: const Icon(Icons.search, color: Color(0xFF1E3A8A)),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                        ),
                        onSubmitted: (_) => _onSearch(),
                      ),
                    ),
                  ),
                  if (isMobile) const SizedBox(height: 12) else const SizedBox(width: 16),
                  SizedBox(
                    width: isMobile ? double.infinity : null,
                    child: ElevatedButton(
                      onPressed: _onSearch,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Qidirish', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 32),

              if (_isLoading)
                const Expanded(child: Center(child: CircularProgressIndicator()))
              else if (_subjects == null || _subjects!.isEmpty)
                const Expanded(child: Center(child: Text('Baholar topilmadi.')))
              else ...[
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
                const SizedBox(height: 16),
                // Pagination Controls
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: _currentPage > 1 ? () {
                          setState(() => _currentPage--);
                          _fetchSubjects();
                        } : null,
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Text(
                        isMobile ? '$_currentPage / $_totalPages' : 'Sahifa $_currentPage / $_totalPages (${_totalCount} ta fan)',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        onPressed: _currentPage < _totalPages ? () {
                          setState(() => _currentPage++);
                          _fetchSubjects();
                        } : null,
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 300.ms),
              ],
            ],
          ),
        );
      },
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
        AppToast.show(context, 'Xatolik: $e');
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
    AppToast.show(context, 'Hisobot yuklanmoqda kuting...');
    try {
      await _apiService.downloadExcelReport(subjectId, groupId, subjectName);
      if (mounted) AppToast.show(context, 'Hisobot yuklab olindi!');
    } catch (e) {
      if (mounted) AppToast.show(context, e.toString());
    }
  }
}
