import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../logic/auth/auth_cubit.dart';
import '../logic/auth/auth_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'topic_player_screen.dart';
import '../widgets/responsive_dialog.dart';

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
      builder: (context) => ResponsiveDialog(
        title: 'Yangi mavzu qo\'shish',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Mavzu nomi', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(controller: contentController, decoration: const InputDecoration(labelText: 'Dars matni (qisqacha)', border: OutlineInputBorder()), maxLines: 3),
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
      builder: (context) => ResponsiveDialog(
        title: 'Mavzuni tahrirlash',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Mavzu nomi', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(controller: contentController, decoration: const InputDecoration(labelText: 'Dars matni (qisqacha)', border: OutlineInputBorder()), maxLines: 3),
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
      builder: (ctx) => ResponsiveDialog(
        title: 'Diqqat!',
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
            child: const Text('Ha, O\'chirish', style: TextStyle(color: Colors.white)),
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
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                  itemCount: displayedTopics.length,
                  itemBuilder: (context, index) {
                    final topic = displayedTopics[index];
                    final isDisabled = topic.isDisabled;
                    final isLast = index == displayedTopics.length - 1;

                    return IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Timeline Column
                          Column(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: isDisabled ? Colors.grey.shade300 : const Color(0xFF1E3A8A),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    if (!isDisabled)
                                      BoxShadow(color: const Color(0xFF1E3A8A).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ),
                              ),
                              if (!isLast)
                                Expanded(
                                  child: Container(
                                    width: 2,
                                    color: Colors.grey.shade300,
                                    margin: const EdgeInsets.symmetric(vertical: 4),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 24),
                          // Content Card
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 32.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.grey.shade200),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.03),
                                      blurRadius: 15,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: InkWell(
                                    onTap: isDisabled && !isAdmin ? null : () {
                                      Navigator.push(context, MaterialPageRoute(builder: (_) => LessonPlayerScreen(topic: topic)));
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(24.0),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Text(
                                                      topic.title,
                                                      style: TextStyle(
                                                        fontSize: 20,
                                                        fontWeight: FontWeight.bold,
                                                        color: isDisabled ? Colors.grey : const Color(0xFF1E3A8A),
                                                      ),
                                                    ),
                                                    if (isDisabled) ...[
                                                      const SizedBox(width: 12),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                        decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(6)),
                                                        child: const Text('Muzlatilgan', style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                                                      ),
                                                    ]
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                if (topic.createdByName != null)
                                                  Text(
                                                    'Qo\'shdi: ${topic.createdByName}',
                                                    style: TextStyle(color: Colors.grey.shade500, fontSize: 10, fontStyle: FontStyle.italic),
                                                  ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  topic.content,
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14, height: 1.5),
                                                ),
                                                const SizedBox(height: 16),
                                                Wrap(
                                                  spacing: 12,
                                                  children: [
                                                    _buildTopicBadge(Icons.video_library_outlined, 'Video', Colors.red),
                                                    _buildTopicBadge(Icons.quiz_outlined, 'Test', Colors.purple),
                                                    _buildTopicBadge(Icons.description_outlined, 'Materiallar', Colors.blue),
                                                  ],
                                                )
                                              ],
                                            ),
                                          ),
                                          if (isAdmin)
                                            PopupMenuButton<String>(
                                              icon: const Icon(Icons.more_vert),
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
                                            )
                                          else
                                            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ).animate().fadeIn(delay: Duration(milliseconds: 100 * index)).slideX(begin: 0.1),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildTopicBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

}
