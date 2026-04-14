import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';
import '../subject_details_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/auth/auth_cubit.dart';
import '../../logic/auth/auth_state.dart';

class SubjectsScreen extends StatefulWidget {
  const SubjectsScreen({super.key});

  @override
  State<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends State<SubjectsScreen> {
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

  void _editSubjectDialog(Subject subject) {
    final nameController = TextEditingController(text: subject.name);
    final descController = TextEditingController(text: subject.description);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fanni tahrirlash'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Fan nomi')),
            const SizedBox(height: 16),
            TextField(controller: descController, decoration: const InputDecoration(labelText: 'Ta\'rif (qisqacha)'), maxLines: 3),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Bekor qilish')),
          ElevatedButton(
            onPressed: () async {
              final success = await _apiService.updateSubject(
                subject.id,
                nameController.text,
                descController.text,
                subject.isDisabled,
              );
              if (success && mounted) {
                Navigator.pop(context);
                _fetchSubjects();
              }
            },
            child: const Text('Saqlash'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteSubject(Subject subject) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Diqqat!'),
        content: Text('Siz rostdan ham "${subject.name}" fanini o\'chirmoqchimisiz? Barcha biriktirilgan materiallar o\'chib ketadi!'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Yo\'q')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final ok = await _apiService.deleteSubject(subject.id);
              if (ok && mounted) {
                Navigator.pop(ctx);
                _fetchSubjects();
              }
            },
            child: const Text('Ha, O\'chirish'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    final isAdmin = authState is AuthAuthenticated && authState.isAdmin;
    
    // Admins see everything, students see only enabled
    final displayedSubjects = isAdmin 
        ? _subjects 
        : _subjects?.where((s) => !s.isDisabled).toList();

    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (displayedSubjects == null || displayedSubjects.isEmpty) {
      return const Center(child: Text('Hozircha fanlar mavjud emas.'));
    }

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mening Fanlarim',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
          ).animate().fadeIn().slideY(begin: 0.2),
          const SizedBox(height: 8),
          Text(
            'Barcha o\'quv fanlari ro\'yxati va materiallar',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 32),
          
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: MediaQuery.of(context).size.width > 800 ? 350 : 500,
                childAspectRatio: 1.5,
                crossAxisSpacing: 24,
                mainAxisSpacing: 24,
              ),
              itemCount: displayedSubjects.length,
              itemBuilder: (context, index) {
                final subject = displayedSubjects[index];
                return _buildSubjectCard(subject, isAdmin, context).animate().fadeIn(delay: Duration(milliseconds: 100 * index)).scale(begin: const Offset(0.95, 0.95));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectCard(Subject subject, bool isAdmin, BuildContext context) {
    final isDisabled = subject.isDisabled;
    return Card(
      elevation: 0,
      color: isDisabled ? Colors.grey.shade50 : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isDisabled ? Colors.grey.shade300 : Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        hoverColor: const Color(0xFF1E3A8A).withOpacity(0.05),
        onTap: isDisabled && !isAdmin ? null : () {
          // Temporarily use MaterialPageRoute for details until details page uses GoRouter
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (ctx) => SubjectDetailsScreen(subject: subject),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDisabled ? Colors.grey.shade300 : const Color(0xFF1E3A8A).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.menu_book, color: isDisabled ? Colors.grey.shade500 : const Color(0xFF1E3A8A), size: 28),
                  ),
                  if (isAdmin)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.grey),
                      onSelected: (val) async {
                        if (val == 'edit') _editSubjectDialog(subject);
                        else if (val == 'toggle') {
                          await _apiService.toggleSubjectStatus(subject.id);
                          _fetchSubjects();
                        }
                        else if (val == 'delete') _confirmDeleteSubject(subject);
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18, color: Colors.blue), SizedBox(width: 8), Text('Tahrirlash')])),
                        PopupMenuItem(value: 'toggle', child: Row(children: [Icon(isDisabled ? Icons.visibility : Icons.visibility_off, size: 18, color: Colors.orange), SizedBox(width: 8), Text(isDisabled ? 'Faollashtirish' : 'Faolsizlashtirish')])),
                        const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 18, color: Colors.red), SizedBox(width: 8), Text('O\'chirish', style: TextStyle(color: Colors.red))])),
                      ]
                    ),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      subject.name,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDisabled ? Colors.grey.shade600 : Colors.black87),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isDisabled)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(4)),
                      child: const Text('Faolsiz', style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                    )
                ],
              ),
              const SizedBox(height: 8),
              Text(
                subject.description.isEmpty ? 'Ta\'rif yo\'q' : subject.description,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
