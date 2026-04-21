import 'package:student_platform_frontend/widgets/app_toast.dart';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';
import '../subject_details_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/auth/auth_cubit.dart';
import '../../logic/auth/auth_state.dart';
import '../../widgets/responsive_dialog.dart';

class SubjectsScreen extends StatefulWidget {
  const SubjectsScreen({super.key});

  @override
  State<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends State<SubjectsScreen> {
  final ApiService _apiService = ApiService();
  List<Subject>? _subjects;
  bool _isLoading = true;

  // Pagination & Search
  int _currentPage = 1;
  int _pageSize = 9; 
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

  void _addSubjectDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => ResponsiveDialog(
        title: 'Yangi fan qo\'shish',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Fan nomi',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Ta\'rif (qisqacha)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Bekor qilish'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (nameController.text.isEmpty) return;
              final success = await _apiService.createSubject(
                nameController.text,
                descController.text,
              );
              if (success && mounted) {
                Navigator.pop(context);
                _fetchSubjects();
                AppToast.show(context, 'Fan muvaffaqiyatli qo\'shildi');
              }
            },
            child: const Text('Qo\'shish'),
          ),
        ],
      ),
    );
  }

  void _editSubjectDialog(Subject subject) {
    final nameController = TextEditingController(text: subject.name);
    final descController = TextEditingController(text: subject.description);

    showDialog(
      context: context,
      builder: (context) => ResponsiveDialog(
        title: 'Fanni tahrirlash',
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
      builder: (ctx) => ResponsiveDialog(
        title: 'Diqqat!',
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
            child: const Text('Ha, O\'chirish', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _attachSubjectGroupsDialog(Subject subject) async {
    final groupsMap = await _apiService.getGroups();
    final attachedGroupIdsList = await _apiService.getSubjectGroups(subject.id);
    
    Set<int> selectedIds = attachedGroupIdsList.toSet();

    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => ResponsiveDialog(
          title: '${subject.name} - Guruhlarga biriktirish',
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: groupsMap.isEmpty 
              ? const Center(child: Text('Guruhlar topilmadi.'))
              : ListView.builder(
              shrinkWrap: true,
              itemCount: groupsMap.length,
              itemBuilder: (context, index) {
                final g = groupsMap[index];
                return CheckboxListTile(
                  title: Text(g['name']),
                  value: selectedIds.contains(g['id']),
                  onChanged: (val) {
                    setDialogState(() {
                      if (val == true) selectedIds.add(g['id']);
                      else selectedIds.remove(g['id']);
                    });
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Bekor qilish'),
            ),
            ElevatedButton(
              onPressed: () async {
                final ok = await _apiService.attachSubjectToGroups(subject.id, selectedIds.toList());
                if (ok && mounted) {
                  Navigator.pop(ctx);
                  AppToast.show(context, 'Muvaffaqiyatli saqlandi');
                } else if (mounted) {
                   AppToast.show(context, 'Xatolik (yoki huquq yetarli emas)');
                }
              },
              child: const Text('Saqlash'),
            ),
          ],
        )
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    final isAdmin = authState is AuthAuthenticated && authState.isAdmin;
    
    final displayedSubjects = isAdmin 
        ? _subjects 
        : _subjects?.where((s) => !s.isDisabled).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final padding = isMobile ? 16.0 : 32.0;

        return Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              isMobile 
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mening Fanlarim',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                    ).animate().fadeIn().slideY(begin: 0.2),
                    const SizedBox(height: 12),
                    if (isAdmin)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _addSubjectDialog,
                          icon: const Icon(Icons.add),
                          label: const Text('Fan qo\'shish'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ).animate().fadeIn(delay: 200.ms).scale(),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
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
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ).animate().fadeIn(delay: 100.ms),
                        ],
                      ),
                    ),
                    if (isAdmin)
                      ElevatedButton.icon(
                        onPressed: _addSubjectDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Fan qo\'shish'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E3A8A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ).animate().fadeIn(delay: 200.ms).scale(),
                  ],
                ),
              
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
              ).animate().fadeIn(delay: 300.ms),
              const SizedBox(height: 32),

              if (_isLoading) 
                const Expanded(child: Center(child: CircularProgressIndicator()))
              else if (displayedSubjects == null || displayedSubjects.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.menu_book_outlined, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          'Fanlar topilmadi.',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                Expanded(
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: isMobile ? 600 : 350,
                      childAspectRatio: isMobile ? 1.8 : 1.5,
                      crossAxisSpacing: padding,
                      mainAxisSpacing: padding,
                    ),
                    itemCount: displayedSubjects.length,
                    itemBuilder: (context, index) {
                      final subject = displayedSubjects[index];
                      return _buildSubjectCard(subject, isAdmin, context).animate().fadeIn(delay: Duration(milliseconds: 100 * index)).scale(begin: const Offset(0.95, 0.95));
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
                        isMobile 
                        ? '$_currentPage / $_totalPages' 
                        : 'Sahifa $_currentPage / $_totalPages (${_totalCount} ta fan)',
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
                ).animate().fadeIn(delay: 400.ms),
              ],
            ],
          ),
        );
      },
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
                        else if (val == 'groups') _attachSubjectGroupsDialog(subject);
                        else if (val == 'toggle') {
                          await _apiService.toggleSubjectStatus(subject.id);
                          _fetchSubjects();
                        }
                        else if (val == 'delete') _confirmDeleteSubject(subject);
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(value: 'groups', child: Row(children: [Icon(Icons.group, size: 18, color: Colors.indigo), SizedBox(width: 8), Text('Guruhlarga biriktirish')])),
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
