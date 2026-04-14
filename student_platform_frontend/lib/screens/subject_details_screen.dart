import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../logic/auth/auth_cubit.dart';
import '../logic/auth/auth_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'topic_player_screen.dart';

class SubjectDetailsScreen extends StatefulWidget {
  final Subject subject;
  const SubjectDetailsScreen({required this.subject, super.key});

  @override
  State<SubjectDetailsScreen> createState() => _SubjectDetailsScreenState();
}

class _SubjectDetailsScreenState extends State<SubjectDetailsScreen> {
  final ApiService _apiService = ApiService();
  List<Topic>? _topics;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTopics();
  }

  Future<void> _fetchTopics() async {
    final topics = await _apiService.getTopics(widget.subject.id);
    setState(() {
      _topics = topics;
      _isLoading = false;
    });
  }

  void _showAddTopicDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yangi mavzu qo\'shish'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Mavzu nomi')),
            TextField(controller: contentController, decoration: const InputDecoration(labelText: 'Dars matni (qisqacha)'), maxLines: 3),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Bekor qilish')),
          ElevatedButton(
            onPressed: () async {
              final success = await _apiService.createTopic(
                widget.subject.id,
                titleController.text,
                contentController.text,
              );
              if (success && mounted) {
                Navigator.pop(context);
                _fetchTopics();
              }
            },
            child: const Text('Saqlash'),
          ),
        ],
      ),
    );
  }

  void _editTopicDialog(Topic topic) {
    final titleController = TextEditingController(text: topic.title);
    final contentController = TextEditingController(text: topic.content);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mavzuni tahrirlash'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Mavzu nomi')),
            const SizedBox(height: 16),
            TextField(controller: contentController, decoration: const InputDecoration(labelText: 'Dars matni (qisqacha)'), maxLines: 3),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Bekor qilish')),
          ElevatedButton(
            onPressed: () async {
              final success = await _apiService.updateTopic(
                topic.id,
                titleController.text,
                contentController.text,
                topic.isDisabled,
              );
              if (success && mounted) {
                Navigator.pop(context);
                _fetchTopics();
              }
            },
            child: const Text('Saqlash'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteTopic(Topic topic) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Diqqat!'),
        content: Text('Siz rostdan ham "${topic.title}" mavzusini o\'chirmoqchimisiz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Yo\'q')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final ok = await _apiService.deleteTopic(topic.id);
              if (ok && mounted) {
                Navigator.pop(ctx);
                _fetchTopics();
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
    
    // Filter out disabled topics for students
    final displayedTopics = isAdmin 
        ? _topics 
        : _topics?.where((t) => !t.isDisabled).toList();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('${widget.subject.name} - Mavzular'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E3A8A),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey.shade300, height: 1.0),
        ),
        actions: [
          if (isAdmin)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 18),
                onPressed: _showAddTopicDialog,
                label: const Text('Mavzu qo\'shish'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : displayedTopics == null || displayedTopics.isEmpty
              ? const Center(child: Text('Bu fanda hali mavzular yo\'q.'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                  itemCount: displayedTopics.length,
                  itemBuilder: (context, index) {
                    final topic = displayedTopics[index];
                    final isDisabled = topic.isDisabled;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: isDisabled ? Colors.grey.shade50 : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDisabled ? Colors.grey.shade300 : Colors.indigo.shade50, width: 1.5),
                        boxShadow: isDisabled ? [] : [
                          BoxShadow(color: Colors.blue.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))
                        ],
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        hoverColor: Colors.indigo.withOpacity(0.02),
                        onTap: isDisabled && !isAdmin ? null : () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => LessonPlayerScreen(topic: topic)));
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: isDisabled ? Colors.grey.shade300 : const Color(0xFF1E3A8A).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: isDisabled ? Colors.grey.shade600 : const Color(0xFF1E3A8A),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 20,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      topic.title,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: isDisabled ? Colors.grey.shade500 : Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(Icons.ondemand_video_rounded, size: 16, color: isDisabled ? Colors.grey.shade400 : Colors.grey.shade600),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Video dars, Test va Materiallar',
                                          style: TextStyle(color: isDisabled ? Colors.grey.shade400 : Colors.grey.shade600, fontSize: 13),
                                        ),
                                        if (isDisabled) ...[
                                          const SizedBox(width: 16),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(6)),
                                            child: const Row(
                                              children: [
                                                Icon(Icons.block, size: 12, color: Colors.orange),
                                                SizedBox(width: 4),
                                                Text('Muzlatilgan', style: TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold)),
                                              ]
                                            ),
                                          ),
                                        ]
                                      ],
                                    )
                                  ],
                                ),
                              ),
                              if (isAdmin)
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert, color: Colors.grey),
                                  onSelected: (val) async {
                                    if (val == 'edit') _editTopicDialog(topic);
                                    else if (val == 'toggle') {
                                      await _apiService.toggleTopicStatus(topic.id);
                                      _fetchTopics();
                                    }
                                    else if (val == 'delete') _confirmDeleteTopic(topic);
                                  },
                                  itemBuilder: (ctx) => [
                                    const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18, color: Colors.blue), SizedBox(width: 8), Text('Tahrirlash')])),
                                    PopupMenuItem(value: 'toggle', child: Row(children: [Icon(isDisabled ? Icons.visibility : Icons.visibility_off, size: 18, color: Colors.orange), SizedBox(width: 8), Text(isDisabled ? 'Faollashtirish' : 'Faolsizlashtirish')])),
                                    const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 18, color: Colors.red), SizedBox(width: 8), Text('O\'chirish', style: TextStyle(color: Colors.red))])),
                                  ]
                                ),
                              if (!isAdmin && !isDisabled)
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.indigo.shade50,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.play_arrow_rounded, color: Colors.indigo),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: Duration(milliseconds: 50 * index)).slideX();
                  },
                ),
    );
  }
}
