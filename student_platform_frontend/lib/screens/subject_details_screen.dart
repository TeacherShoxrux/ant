import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
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

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.subject.name} - Mavzular'),
        actions: [
          if (auth.isAdmin)
            IconButton(
              icon: const Icon(Icons.add_circle, color: Colors.indigo),
              onPressed: _showAddTopicDialog,
              tooltip: 'Mavzu qo\'shish',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _topics == null || _topics!.isEmpty
              ? const Center(child: Text('Bu fanda hali mavzular yo\'q.'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  itemCount: _topics!.length,
                  itemBuilder: (context, index) {
                    final topic = _topics![index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.indigo,
                          child: Text('${index + 1}', style: const TextStyle(color: Colors.white)),
                        ),
                        title: Text(topic.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text('Video dars, Test va Mustaqil ish'),
                        trailing: const Icon(Icons.play_circle_fill, color: Colors.indigo, size: 32),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => LessonPlayerScreen(topic: topic)),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
