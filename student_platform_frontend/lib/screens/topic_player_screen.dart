import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../logic/auth/auth_cubit.dart';
import '../logic/auth/auth_state.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import 'quiz_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

class LessonPlayerScreen extends StatefulWidget {
  final Topic topic;
  const LessonPlayerScreen({required this.topic, super.key});

  @override
  State<LessonPlayerScreen> createState() => _LessonPlayerScreenState();
}

class _LessonPlayerScreenState extends State<LessonPlayerScreen> {
  final ApiService _apiService = ApiService();
  Topic? _fullTopic;
  List<TopicQuiz>? _quizzes;
  List<Assignment>? _assignments;
  bool _isLoadingContent = true;

  @override
  void initState() {
    super.initState();
    _fetchTopicContent();
  }

  Future<void> _fetchTopicContent() async {
    final fullTopic = await _apiService.getTopic(widget.topic.id);
    final quizzes = await _apiService.getQuizzes(widget.topic.id);
    final assignments = await _apiService.getAssignments(widget.topic.id);
    setState(() {
      _fullTopic = fullTopic;
      _quizzes = quizzes;
      _assignments = assignments;
      _isLoadingContent = false;
    });
  }

  void _showVideoDialog(TopicVideo video) {
    final videoId = YoutubePlayerController.convertUrlToId(video.youtubeUrl);
    final controller = YoutubePlayerController.fromVideoId(
      videoId: videoId ?? '',
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        mute: false,
      ),
    );

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: Text(video.title, style: const TextStyle(color: Colors.white)),
                backgroundColor: Colors.transparent,
                leading: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Flexible(
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: YoutubePlayer(controller: controller),
                ),
              ),
            ],
          ),
        ),
      ),
    ).then((_) => controller.close());
  }

  void _showAddVideoDialog() {
    final titleController = TextEditingController();
    final urlController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mavzu uchun video qo\'shish'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Video nomi')),
            TextField(controller: urlController, decoration: const InputDecoration(labelText: 'YouTube URL')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Bekor qilish')),
          ElevatedButton(
            onPressed: () async {
              final success = await _apiService.addTopicVideo(widget.topic.id, titleController.text, urlController.text);
              if (success && mounted) {
                Navigator.pop(context);
                _fetchTopicContent();
              }
            },
            child: const Text('Qo\'shish'),
          ),
        ],
      ),
    );
  }

  void _showAddDocumentDialog() {
    final titleController = TextEditingController();
    Uint8List? fileBytes;
    String? fileName;
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Mavzu uchun hujjat (PDF) yuklash'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Hujjat nomi'),
                  enabled: !isUploading,
                ),
                const SizedBox(height: 16),
                if (fileName != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text('Tanlangan fayl: $fileName', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  ),
                OutlinedButton.icon(
                  onPressed: isUploading
                      ? null
                      : () async {
                          FilePickerResult? result = await FilePicker.pickFiles(
                            type: FileType.custom,
                            allowedExtensions: ['pdf'],
                            withData: true,
                          );
                          if (result != null) {
                            setDialogState(() {
                              fileBytes = result.files.first.bytes;
                              fileName = result.files.first.name;
                            });
                          }
                        },
                  icon: const Icon(Icons.attach_file),
                  label: Text(fileName == null ? 'PDF faylni tanlash' : 'Faylni almashtirish'),
                ),
                if (isUploading)
                  const Padding(
                    padding: EdgeInsets.only(top: 16.0),
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isUploading ? null : () => Navigator.pop(context),
                child: const Text('Bekor qilish'),
              ),
              ElevatedButton(
                onPressed: (isUploading || fileBytes == null || titleController.text.isEmpty)
                    ? null
                    : () async {
                        setDialogState(() => isUploading = true);
                        try {
                          final success = await _apiService.uploadTopicDocument(
                            widget.topic.id,
                            titleController.text,
                            fileBytes!,
                            fileName!,
                          );
                          if (success && mounted) {
                            Navigator.pop(context);
                            _fetchTopicContent();
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hujjat muvaffaqiyatli yuklandi.')));
                          }
                        } finally {
                          if (mounted) setDialogState(() => isUploading = false);
                        }
                      },
                child: const Text('Yuklash'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(widget.topic.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E3A8A),
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoadingContent
          ? const Center(child: CircularProgressIndicator())
          : DefaultTabController(
              length: 3,
              child: Column(
                children: [
                   Container(
                     color: Colors.white,
                     padding: const EdgeInsets.symmetric(horizontal: 16),
                     child: Container(
                       decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: Colors.black12, width: 1.0)),
                       ),
                       child: const TabBar(
                         indicatorColor: Color(0xFF1E3A8A),
                         indicatorWeight: 3,
                         labelColor: Color(0xFF1E3A8A),
                         unselectedLabelColor: Colors.grey,
                         labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                         tabs: [
                           Tab(text: 'Dars matni va Media', icon: Icon(Icons.menu_book)),
                           Tab(text: 'Nazorat Testi', icon: Icon(Icons.quiz)),
                           Tab(text: 'Topshiriq (Vazifa)', icon: Icon(Icons.upload_file)),
                         ],
                       ),
                     ),
                   ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildMainContent(),
                        _buildTestSection(),
                        _buildAssignmentSection(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildMainContent() {
    final authState = context.read<AuthCubit>().state;
    final isAdmin = authState is AuthAuthenticated && authState.isAdmin;
    final docs = _fullTopic?.documents ?? [];
    final videos = _fullTopic?.videos ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Lesson Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF1E3A8A).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                      child: const Text('DARSNING NAZARIY QISMI', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    ),
                    const SizedBox(height: 16),
                    Text(widget.topic.title, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                    if (widget.topic.createdByName != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('Mavzu muallifi: ${widget.topic.createdByName}', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12, fontStyle: FontStyle.italic)),
                      ),
                    const SizedBox(height: 12),
                    Text(widget.topic.content, style: TextStyle(fontSize: 16, color: Colors.indigo.shade50, height: 1.6)),
                  ],
                ),
              ),
              const SizedBox(height: 48),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   // Left Side: Videos
                   Expanded(
                     flex: 3,
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         _buildSectionHeader('Video darslar', Icons.play_circle_fill, isAdmin ? _showAddVideoDialog : null),
                         const SizedBox(height: 16),
                         if (videos.isEmpty)
                           _buildEmptyState('Ushbu mavzu uchun video darsliklar hali yuklanmagan.', Icons.videocam_off_outlined)
                         else
                           GridView.builder(
                             shrinkWrap: true,
                             physics: const NeverScrollableScrollPhysics(),
                             gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                               crossAxisCount: 2,
                               childAspectRatio: 1.5,
                               crossAxisSpacing: 16,
                               mainAxisSpacing: 16,
                             ),
                             itemCount: videos.length,
                             itemBuilder: (context, index) {
                               final video = videos[index];
                               return _buildVideoCard(video);
                             },
                           ),
                       ],
                     ),
                   ),
                   const SizedBox(width: 32),
                   // Right Side: Documents
                   Expanded(
                     flex: 2,
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         _buildSectionHeader('Qo\'shimcha materiallar', Icons.folder_open, isAdmin ? _showAddDocumentDialog : null),
                         const SizedBox(height: 16),
                         if (docs.isEmpty)
                            _buildEmptyState('Fayllar mavjud emas.', Icons.file_copy_outlined)
                         else
                           ListView.builder(
                             shrinkWrap: true,
                             physics: const NeverScrollableScrollPhysics(),
                             itemCount: docs.length,
                             itemBuilder: (context, index) {
                               final doc = docs[index];
                               return _buildDocumentItem(doc);
                             },
                           ),
                       ],
                     ),
                   ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, VoidCallback? onAdd) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFF1E3A8A), size: 24),
            const SizedBox(width: 12),
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
          ],
        ),
        if (onAdd != null)
          IconButton(
            onPressed: onAdd,
            icon: const Icon(Icons.add_circle, color: Colors.green),
            tooltip: 'Qo\'shish',
          ),
      ],
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.grey.shade300, size: 48),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildVideoCard(TopicVideo video) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _showVideoDialog(video),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      'https://img.youtube.com/vi/${YoutubePlayerController.convertUrlToId(video.youtubeUrl)}/hqdefault.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(color: Colors.black87),
                    ),
                    const Center(child: Icon(Icons.play_circle_fill, color: Colors.white, size: 48)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(video.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    if (video.createdByName != null)
                      Text('Qo\'shdi: ${video.createdByName}', style: TextStyle(color: Colors.grey.shade500, fontSize: 10, fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentItem(TopicDocument doc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.picture_as_pdf, color: Colors.red, size: 20),
        ),
        title: Text(doc.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.download, size: 18, color: Colors.grey),
        onTap: () async {
          final url = Uri.parse('http://localhost:5297${doc.filePath}');
          if (await canLaunchUrl(url)) {
            await launchUrl(url);
          }
        },
      ),
    );
  }

  void _showQuizDetailsDialog(TopicQuiz quiz) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800, maxHeight: 900),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: FutureBuilder<List<TestQuestion>>(
              future: _apiService.getQuizQuestions(quiz.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(height: 300, child: Center(child: CircularProgressIndicator()));
                }
                if (snapshot.hasError || !snapshot.hasData) {
                  return const SizedBox(height: 300, child: Center(child: Text('Savollarni yuklashda xatolik yuz berdi.')));
                }
                
                final questions = snapshot.data!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(quiz.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo)),
                        IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                      ],
                    ),
                    Text(quiz.content, style: const TextStyle(color: Colors.grey)),
                    const Divider(height: 32),
                    if (questions.isEmpty)
                      const Expanded(child: Center(child: Text('Ushbu testda hali savollar yo\'q.')))
                    else
                      Expanded(
                        child: ListView.builder(
                          itemCount: questions.length,
                          itemBuilder: (context, index) {
                            final q = questions[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 24.0),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5)),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (q.imagePath != null)
                                    ClipRRect(
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                      child: Container(
                                        width: double.infinity,
                                        height: 250,
                                        color: Colors.grey.shade100,
                                        child: Image.network(
                                          '${ApiService.serverUrl}${q.imagePath?.startsWith('/') == true ? q.imagePath : '/$q.imagePath'}',
                                          fit: BoxFit.cover,
                                          errorBuilder: (ctx, _, __) => const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey)),
                                        ),
                                      ),
                                    ),
                                  Padding(
                                    padding: const EdgeInsets.all(20.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                              decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(30)),
                                              child: Text('Savol ${index + 1}', style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold, fontSize: 13)),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Text(q.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black87)),
                                        if (q.question.isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          Text(q.question, style: TextStyle(fontSize: 15, color: Colors.grey.shade700, height: 1.5)),
                                        ],
                                        const SizedBox(height: 24),
                                        const Text('Varianlar:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1, color: Colors.blueGrey)),
                                        const SizedBox(height: 12),
                                        ...q.options.asMap().entries.map((e) {
                                          final opt = e.value;
                                          return Container(
                                            margin: const EdgeInsets.only(bottom: 10),
                                            padding: const EdgeInsets.all(14),
                                            decoration: BoxDecoration(
                                              color: opt.isCorrect ? Colors.green.shade50 : Colors.white,
                                              borderRadius: BorderRadius.circular(15),
                                              border: Border.all(color: opt.isCorrect ? Colors.green : Colors.grey.shade200, width: 1.5),
                                            ),
                                            child: Row(
                                              children: [
                                                CircleAvatar(
                                                  radius: 12,
                                                  backgroundColor: opt.isCorrect ? Colors.green : Colors.grey.shade200,
                                                  child: Text('${e.key + 1}', style: TextStyle(color: opt.isCorrect ? Colors.white : Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Text(opt.optionText, style: TextStyle(fontSize: 15, fontWeight: opt.isCorrect ? FontWeight.bold : FontWeight.normal, color: opt.isCorrect ? Colors.green.shade900 : Colors.black87)),
                                                ),
                                                if (opt.isCorrect) const Icon(Icons.check_circle, color: Colors.green, size: 20),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTestSection() {
    if (_isLoadingContent) return const Center(child: CircularProgressIndicator());
    final authState = context.read<AuthCubit>().state;
    final isAdmin = authState is AuthAuthenticated && authState.isAdmin;
    final quizzes = _quizzes ?? [];

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Mavzu bo\'yicha testlar', Icons.assignment_turned_in_outlined, isAdmin ? _showAddQuizDialog : null),
              const SizedBox(height: 24),
              if (quizzes.isEmpty)
                _buildEmptyState('Testlar belgilanmagan.', Icons.quiz_outlined)
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: quizzes.length,
                    itemBuilder: (context, index) {
                      final q = quizzes[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(color: const Color(0xFF1E3A8A).withOpacity(0.06), blurRadius: 24, offset: const Offset(0, 12))
                          ],
                          border: Border.all(color: Colors.grey.shade100),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: InkWell(
                            onTap: () => _showQuizDetailsDialog(q),
                            child: Row(
                              children: [
                                if (q.imagePath != null)
                                  Hero(
                                    tag: 'quiz_${q.id}',
                                    child: Container(
                                      width: 240,
                                      height: 200,
                                      decoration: BoxDecoration(
                                        image: DecorationImage(
                                          image: NetworkImage('${ApiService.serverUrl}${q.imagePath}'),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [Colors.black.withOpacity(0.4), Colors.transparent],
                                            begin: Alignment.bottomCenter,
                                            end: Alignment.topCenter,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(28),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(q.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                                                  if (q.createdByName != null)
                                                    Text('Test muallifi: ${q.createdByName}', style: TextStyle(color: Colors.grey.shade500, fontSize: 10, fontStyle: FontStyle.italic)),
                                                ],
                                              ),
                                            ),
                                            const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                                            const SizedBox(width: 4),
                                            const Text('Ekspert', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12)),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Text(q.content, maxLines: 2, style: TextStyle(color: Colors.blueGrey.shade600, fontSize: 15, height: 1.5)),
                                        const SizedBox(height: 20),
                                        Row(
                                          children: [
                                            _buildInfoChip(Icons.timer_outlined, '${q.timeLimitMinutes} daqiqa', Colors.orange),
                                            const SizedBox(width: 16),
                                            _buildInfoChip(Icons.help_outline_rounded, '${q.questions.length} ta savol', Colors.indigo),
                                            const SizedBox(width: 16),
                                            _buildInfoChip(Icons.check_circle_outline_rounded, 'Muvaffaqiyat 60%', Colors.green),
                                          ],
                                        ),
                                        const SizedBox(height: 24),
                                        Row(
                                          children: [
                                            ElevatedButton(
                                              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => QuizScreen(quiz: q))),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF1E3A8A),
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                                elevation: 8,
                                                shadowColor: const Color(0xFF1E3A8A).withOpacity(0.4),
                                              ),
                                              child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text('Testni boshlash', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                                  SizedBox(width: 12),
                                                  Icon(Icons.arrow_forward_rounded, size: 18),
                                                ],
                                              ),
                                            ),
                                            if (isAdmin) ...[
                                               const SizedBox(width: 16),
                                               _buildAdminActionBtn(Icons.add_task_rounded, 'Savol qo\'shish', Colors.green, () => _showAddQuestionDialog(q.id)),
                                               const SizedBox(width: 8),
                                               _buildAdminActionBtn(Icons.insights_rounded, 'Natijalar', Colors.indigo, () => _showQuizResultsDialog(q)),
                                            ]
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ).animate().fadeIn(delay: (index * 100).ms).slideX(begin: 0.1);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showQuizResultsDialog(TopicQuiz quiz) async {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800, maxHeight: 700),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: FutureBuilder<List<QuizResult>>(
              future: _apiService.getQuizResults(quiz.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(height: 300, child: Center(child: CircularProgressIndicator()));
                }
                if (snapshot.hasError) {
                  return SizedBox(height: 300, child: Center(child: Text('Xatolik: ${snapshot.error}')));
                }
                final results = snapshot.data ?? [];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(quiz.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo)),
                            const Text('Test natijalari va talabalar ro\'yxati', style: TextStyle(color: Colors.grey, fontSize: 14)),
                          ],
                        ),
                        IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                      ],
                    ),
                    const Divider(height: 48),
                    if (results.isEmpty)
                      const Expanded(child: Center(child: Text('Hozircha natijalar mavjud emas.')))
                    else
                      Expanded(
                        child: ListView.builder(
                          itemCount: results.length,
                          itemBuilder: (context, index) {
                            final r = results[index];
                             // Calculate percentage color
                             Color scoreColor = Colors.red;
                             if (r.score / r.totalQuestions >= 0.8) scoreColor = Colors.green;
                             else if (r.score / r.totalQuestions >= 0.5) scoreColor = Colors.orange;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                side: BorderSide(color: Colors.grey.shade200),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                leading: CircleAvatar(
                                  backgroundColor: Colors.indigo.shade50,
                                  child: Text(r.studentName[0].toUpperCase(), style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
                                ),
                                title: Text(r.studentName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text(r.takenAt.toString().split('.')[0].replaceAll('T', ' '), style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('${r.score} / ${r.totalQuestions}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: scoreColor)),
                                    Text('${(r.score / r.totalQuestions * 100).toStringAsFixed(0)}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: scoreColor.withOpacity(0.8))),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _showAddQuizDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    final timeController = TextEditingController();
    Uint8List? imageBytes;
    String? imageName;
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Yangi Test to\'plami',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Test nomi',
                        prefixIcon: const Icon(Icons.title_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: contentController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Tavsif',
                        prefixIcon: const Icon(Icons.description_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: timeController,
                      decoration: InputDecoration(
                        labelText: 'Vaqt (minutda)',
                        prefixIcon: const Icon(Icons.timer_rounded),
                        suffixText: 'min',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                    const SizedBox(height: 24),
                    
                    InkWell(
                      onTap: () async {
                        FilePickerResult? result = await FilePicker.pickFiles(type: FileType.image, withData: true);
                        if (result != null) {
                          setDialogState(() {
                            imageBytes = result.files.first.bytes;
                            imageName = result.files.first.name;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: imageName != null ? Colors.green.shade50 : Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: imageName != null ? Colors.green.shade200 : Colors.blue.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(imageName != null ? Icons.image_rounded : Icons.add_photo_alternate_rounded, 
                                 color: imageName != null ? Colors.green : Colors.blue),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                imageName ?? 'Test uchun rasm tanlang (ixtiyoriy)',
                                style: TextStyle(color: imageName != null ? Colors.green.shade700 : Colors.blue.shade700, fontWeight: FontWeight.w600),
                              ),
                            ),
                            if (imageName != null) const Icon(Icons.check_circle_rounded, color: Colors.green),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    if (isUploading) 
                      const Center(child: Padding(padding: EdgeInsets.only(bottom: 16), child: LinearProgressIndicator())),
                    
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context), 
                            child: const Text('Bekor qilish'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: isUploading ? null : () async {
                               if (titleController.text.isEmpty || timeController.text.isEmpty) {
                                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Iltimos test nomi va vaqtini kiriting.')));
                                 return;
                               }
                               setDialogState(() => isUploading = true);
                               final success = await _apiService.createQuiz(
                                 topicId: widget.topic.id,
                                 title: titleController.text,
                                 content: contentController.text,
                                 timeLimitMinutes: int.tryParse(timeController.text) ?? 10,
                                 imageBytes: imageBytes,
                                 imageName: imageName,
                                );
                               if (success && mounted) {
                                 Navigator.pop(context);
                                 _fetchTopicContent();
                               } else {
                                 setDialogState(() => isUploading = false);
                               }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E3A8A),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: const Text('Saqlash', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAddQuestionDialog(int quizId) {
    final titleController = TextEditingController();
    final qController = TextEditingController();
    List<TextEditingController> optionControllers = [TextEditingController(), TextEditingController()];
    int correctOptionIndex = 0;
    Uint8List? qImageBytes;
    String? qImageName;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700, maxHeight: 900),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Yangi Savol Qo\'shish', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.indigo)),
                          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                        ],
                      ),
                      const Divider(),
                      const SizedBox(height: 16),
                      TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Savol nomi (qisqa)', border: OutlineInputBorder())),
                      const SizedBox(height: 12),
                      TextField(controller: qController, decoration: const InputDecoration(labelText: 'Savol matni', border: OutlineInputBorder()), maxLines: 3),
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          if (qImageName != null)
                            Expanded(child: Text('Rasm: $qImageName', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
                          ElevatedButton.icon(
                            onPressed: () async {
                              FilePickerResult? result = await FilePicker.pickFiles(type: FileType.image, withData: true);
                              if (result != null) {
                                setDialogState(() {
                                  qImageBytes = result.files.first.bytes;
                                  qImageName = result.files.first.name;
                                });
                              }
                            },
                            icon: const Icon(Icons.add_a_photo),
                            label: const Text('Savol uchun rasm'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Variantlar:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          TextButton.icon(
                            onPressed: () => setDialogState(() => optionControllers.add(TextEditingController())),
                            icon: const Icon(Icons.add),
                            label: const Text('Variant qo\'shish'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      ...List.generate(optionControllers.length, (index) {
                        bool isCorrect = correctOptionIndex == index;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isCorrect ? Colors.green.shade50 : Colors.grey.shade50,
                            border: Border.all(color: isCorrect ? Colors.green : Colors.grey.shade300, width: 2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: isCorrect ? Colors.green : Colors.grey.shade400,
                                radius: 15,
                                child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: optionControllers[index],
                                  decoration: const InputDecoration(hintText: 'Variant matnini kiriting...', border: InputBorder.none),
                                ),
                              ),
                              IconButton(
                                icon: Icon(isCorrect ? Icons.check_circle : Icons.radio_button_off, color: isCorrect ? Colors.green : Colors.grey),
                                onPressed: () => setDialogState(() => correctOptionIndex = index),
                                tooltip: 'To\'g\'ri javob sifatida belgilash',
                              ),
                              if (optionControllers.length > 2)
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  onPressed: () => setDialogState(() {
                                    optionControllers.removeAt(index);
                                    if (correctOptionIndex >= optionControllers.length) correctOptionIndex = 0;
                                  }),
                                )
                            ],
                          ),
                        );
                      }),

                      const SizedBox(height: 32),
                      if (isSaving) const Center(child: CircularProgressIndicator()),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isSaving ? null : () async {
                            if (titleController.text.isEmpty || qController.text.isEmpty || optionControllers.any((c) => c.text.isEmpty)) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Iltimos barcha maydonlarni to\'ldiring.')));
                              return;
                            }
                            setDialogState(() => isSaving = true);
                            
                            final optionsList = optionControllers.asMap().entries.map((e) => {
                              'optionText': e.value.text,
                              'isCorrect': e.key == correctOptionIndex
                            }).toList();

                            final success = await _apiService.addQuestionToQuiz(
                              quizId: quizId,
                              title: titleController.text,
                              question: qController.text,
                              options: optionsList,
                              imageBytes: qImageBytes,
                              imageName: qImageName,
                            );
                            
                            if (success && mounted) {
                              Navigator.pop(context);
                              _fetchTopicContent();
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Savol muvaffaqiyatli qo\'shildi.')));
                            } else {
                              setDialogState(() => isSaving = false);
                            }
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          child: const Text('Savolni Saqlash', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  void _showAssignmentDialog({Assignment? assignment}) {
    final bool isEdit = assignment != null;
    final titleController = TextEditingController(text: assignment?.title ?? '');
    final descController = TextEditingController(text: assignment?.description ?? '');
    final scoreController = TextEditingController(text: assignment?.maxScore.toString() ?? '');
    DateTime? selectedDate = assignment?.deadline;
    Uint8List? fileBytes;
    String? fileName;
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(isEdit ? 'Topshiriqni tahrirlash' : 'Yangi mustaqil ish (Vazifa) qo\'shish', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController, 
                    decoration: InputDecoration(
                      labelText: 'Vazifa nomi *', 
                      prefixIcon: const Icon(Icons.title),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descController, 
                    decoration: InputDecoration(
                      labelText: 'Vazifa sharti / Content *', 
                      prefixIcon: const Icon(Icons.description),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ), 
                    maxLines: 4,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: scoreController, 
                    decoration: InputDecoration(
                      labelText: 'Maksimal ball *', 
                      prefixIcon: const Icon(Icons.star_outline),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ), 
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.event, color: Colors.blue),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                selectedDate == null 
                                  ? 'Muddati belgilanmagan' 
                                  : 'Muddati: ${DateFormat('yyyy-MM-dd HH:mm').format(selectedDate!.toLocal())}',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: selectedDate ?? DateTime.now(),
                                  firstDate: DateTime.now().subtract(const Duration(minutes: 5)),
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                );
                                if (date != null) {
                                  final time = await showTimePicker(
                                    context: context,
                                    initialTime: TimeOfDay.fromDateTime(selectedDate ?? DateTime.now()),
                                  );
                                  if (time != null) {
                                    setDialogState(() {
                                      selectedDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                                    });
                                  }
                                }
                              },
                              icon: const Icon(Icons.calendar_today, size: 18),
                              label: const Text('Sanani va vaqtni tanlash'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (fileName != null || (isEdit && assignment?.filePath != null && fileName == null))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              fileName ?? 'Mavjud fayl saqlangan',
                              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        FilePickerResult? result = await FilePicker.pickFiles(withData: true);
                        if (result != null) {
                          setDialogState(() {
                            fileBytes = result.files.first.bytes;
                            fileName = result.files.first.name;
                          });
                        }
                      },
                      icon: const Icon(Icons.attachment),
                      label: Text(isEdit ? 'Faylni yangilash' : 'Vazifa faylini yuklash'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  if (isUploading) 
                    const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: LinearProgressIndicator(),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context), 
                child: const Text('Bekor qilish' , style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: isUploading
                    ? null
                    : () async {
                        if (titleController.text.isEmpty || descController.text.isEmpty || scoreController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sarlavha, tavsif va ballni kiritish majburiy.')));
                          return;
                        }
                        if (selectedDate != null && selectedDate!.isBefore(DateTime.now().subtract(const Duration(minutes: 1)))) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Muddatni o\'tmishga qo\'yib bo\'lmaydi.')));
                          return;
                        }

                        setDialogState(() => isUploading = true);
                        bool success = false;
                        String? errorMessage;

                        if (isEdit) {
                          final result = await _apiService.updateAssignment(
                            id: assignment!.id,
                            title: titleController.text,
                            description: descController.text,
                            maxScore: int.tryParse(scoreController.text) ?? 100,
                            deadline: selectedDate,
                            fileBytes: fileBytes,
                            fileName: fileName,
                          );
                          success = result['success'];
                          errorMessage = result['message'];
                        } else {
                          success = await _apiService.createAssignment(
                            topicId: widget.topic.id,
                            title: titleController.text,
                            description: descController.text,
                            maxScore: int.tryParse(scoreController.text) ?? 100,
                            deadline: selectedDate,
                            fileBytes: fileBytes,
                            fileName: fileName,
                          );
                        }
                        
                        if (success && mounted) {
                          Navigator.pop(context);
                          _fetchTopicContent();
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isEdit ? 'O\'zgarishlar saqlandi.' : 'Vazifa yaratildi.')));
                        } else {
                          setDialogState(() => isUploading = false);
                          if (errorMessage != null && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage), backgroundColor: Colors.red));
                          }
                        }
                      },
                child: Text(isEdit ? 'Yangilash' : 'Yaratish'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildModernField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    bool enabled = true,
    TextInputType? keyboardType,
    List<TextInputFormatter>? formatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          enabled: enabled,
          keyboardType: keyboardType,
          inputFormatters: formatters,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            prefixIcon: Icon(icon, size: 20, color: const Color(0xFF1E3A8A).withOpacity(0.7)),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 2),
            ),
          ),
        ),
      ],
    );
  }


  void _showSubmitAssignmentDialog(Assignment assignment) {
    final commentController = TextEditingController();
    Uint8List? fileBytes;
    String? fileName;
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text('${assignment.title}ga javob yuborish'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: commentController,
                    decoration: const InputDecoration(labelText: 'Javob uchun izoh (ixtiyoriy)'),
                    maxLines: 2,
                    enabled: !isUploading,
                  ),
                  const SizedBox(height: 16),
                  if (fileName != null)
                    Text('Tanlangan fayl: $fileName', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: isUploading
                        ? null
                        : () async {
                            FilePickerResult? result = await FilePicker.pickFiles(withData: true);
                            if (result != null) {
                              setDialogState(() {
                                fileBytes = result.files.first.bytes;
                                fileName = result.files.first.name;
                              });
                            }
                          },
                    icon: const Icon(Icons.attach_file),
                    label: const Text('Javob faylini yuklash (PDF/Rasm) *'),
                  ),
                  if (isUploading) const LinearProgressIndicator(),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Bekor qilish')),
              ElevatedButton(
                onPressed: (isUploading || fileBytes == null)
                    ? null
                    : () async {
                        setDialogState(() => isUploading = true);
                        final success = await _apiService.submitAssignment(
                          assignmentId: assignment.id,
                          comment: commentController.text,
                          fileBytes: fileBytes!,
                          fileName: fileName!,
                        );
                        if (success && mounted) {
                          Navigator.pop(context);
                          _fetchTopicContent();
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vazifa muvaffaqiyatli topshirildi.')));
                        } else if (mounted) {
                          setDialogState(() => isUploading = false);
                        }
                      },
                child: const Text('Yuborish'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showSubmissionsMonitoringDialog() async {
    List<Submission> submissions = await _apiService.getTopicSubmissions(widget.topic.id);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900, maxHeight: 800),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Topshirilgan vazifalar monitoringi', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 16),
                    if (submissions.isEmpty)
                      const Expanded(child: Center(child: Text('Hozircha hech kim vazifa topshirmagan.')))
                    else
                      Expanded(
                        child: ListView.builder(
                          itemCount: submissions.length,
                          itemBuilder: (context, index) {
                            final s = submissions[index];
                            final gradeController = TextEditingController(text: s.grade?.toString() ?? '');
                            bool isGrading = false;

                            final bool isAlreadyGraded = s.grade != null;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              color: isAlreadyGraded ? Colors.green.shade50 : null,
                              shape: isAlreadyGraded 
                                ? RoundedRectangleBorder(side: BorderSide(color: Colors.green.shade200), borderRadius: BorderRadius.circular(12))
                                : null,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(s.studentName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                        if (isAlreadyGraded)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: _getGradeColor((s.grade! / (s.assignmentMaxScore ?? 100)) * 100),
                                              borderRadius: BorderRadius.circular(8)
                                            ),
                                            child: Column(
                                              children: [
                                                Text('Baholangan: ${s.grade} ball', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                                if (s.gradedByName != null)
                                                  Text('${s.gradedByName} tomonidan', style: const TextStyle(color: Colors.white70, fontSize: 10)),
                                              ],
                                            ),
                                          )
                                        else
                                          Text(s.submittedAt.toString().split('.')[0], style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                      ],
                                    ),
                                    Text('Vazifa: ${s.assignmentTitle}', style: const TextStyle(color: Colors.indigo)),
                                    const SizedBox(height: 8),
                                    if (s.studentComment != null && s.studentComment!.isNotEmpty)
                                      Text('Talaba izohi: ${s.studentComment}', style: const TextStyle(fontStyle: FontStyle.italic)),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        OutlinedButton.icon(
                                          onPressed: () async {
                                            final url = Uri.parse('http://localhost:5297${s.filePath}');
                                            if (await canLaunchUrl(url)) await launchUrl(url);
                                          },
                                          icon: const Icon(Icons.file_present),
                                          label: const Text('Faylni ko\'rish'),
                                        ),
                                        const Spacer(),
                                        if (!isAlreadyGraded) ...[
                                          SizedBox(
                                            width: 80,
                                            child: TextField(
                                              controller: gradeController,
                                              decoration: const InputDecoration(hintText: 'Baho', border: OutlineInputBorder()),
                                              keyboardType: TextInputType.number,
                                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          ElevatedButton(
                                            onPressed: isGrading
                                                ? null
                                                : () async {
                                                    final gradeValue = int.tryParse(gradeController.text) ?? 0;
                                                    final maxScore = s.assignmentMaxScore ?? 100;
                                                    
                                                    if (gradeValue > maxScore) {
                                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Baho maksimal balldan ($maxScore) yuqori bo\'lishi mumkin emas.')));
                                                      return;
                                                    }

                                                    setDialogState(() => isGrading = true);
                                                    final success = await _apiService.gradeSubmission(s.id, gradeValue, "");
                                                    if (success && mounted) {
                                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Baho qo\'yildi.')));
                                                      Navigator.pop(context);
                                                      _showSubmissionsMonitoringDialog(); // Refresh
                                                    }
                                                    setDialogState(() => isGrading = false);
                                                  },
                                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                            child: const Text('Baholash'),
                                          ),
                                        ] else ...[
                                          SizedBox(
                                            width: 80,
                                            child: TextField(
                                              controller: gradeController,
                                              decoration: const InputDecoration(hintText: 'Baho', border: OutlineInputBorder()),
                                              keyboardType: TextInputType.number,
                                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          TextButton(
                                            onPressed: isGrading
                                                ? null
                                                : () async {
                                                    final gradeValue = int.tryParse(gradeController.text) ?? 0;
                                                    final maxScore = s.assignmentMaxScore ?? 100;

                                                    if (gradeValue > maxScore) {
                                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Baho maksimal balldan ($maxScore) yuqori bo\'lishi mumkin emas.')));
                                                      return;
                                                    }

                                                    setDialogState(() => isGrading = true);
                                                    final success = await _apiService.gradeSubmission(s.id, gradeValue, "");
                                                    if (success && mounted) {
                                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Baho yangilandi.')));
                                                      Navigator.pop(context);
                                                      _showSubmissionsMonitoringDialog(); // Refresh
                                                    }
                                                    setDialogState(() => isGrading = false);
                                                  },
                                            child: const Text('O\'zgartirish'),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAssignmentSection() {
    if (_isLoadingContent) return const Center(child: CircularProgressIndicator());
    final authState = context.read<AuthCubit>().state;
    final isAdmin = authState is AuthAuthenticated && authState.isAdmin;
    final assignments = _assignments ?? [];

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionHeader('Mustaqil ishlar', Icons.history_edu_outlined, isAdmin ? () => _showAssignmentDialog() : null),
                  if (isAdmin)
                    TextButton.icon(
                      onPressed: _showSubmissionsMonitoringDialog,
                      icon: const Icon(Icons.people_alt_outlined),
                      label: const Text('Monitoring'),
                      style: TextButton.styleFrom(foregroundColor: Colors.orange.shade800),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              if (assignments.isEmpty)
                _buildEmptyState('Vazifalar belgilanmagan.', Icons.assignment_outlined)
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: assignments.length,
                    itemBuilder: (context, index) {
                      final a = assignments[index];
                      final bool isGraded = a.grade != null;
                      final bool isSubmitted = a.isSubmitted;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
                          border: isGraded ? Border.all(color: Colors.green.shade200, width: 2) : null,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(a.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                                        if (a.createdByName != null)
                                          Text('Muallif: ${a.createdByName}', style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontStyle: FontStyle.italic)),
                                        const SizedBox(height: 4),
                                        Text('Maksimal ball: ${a.maxScore}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                  if (isGraded) ...[
                                    _buildStatusTag('${a.grade} ball', _getGradeColor((a.grade! / a.maxScore) * 100)),
                                    if (a.gradedByName != null)
                                      Padding(
                                        padding: const EdgeInsets.only(left: 8),
                                        child: Text('${a.gradedByName} tomonidan baholandi', style: TextStyle(color: Colors.grey.shade600, fontSize: 11, fontStyle: FontStyle.italic)),
                                      ),
                                  ] else if (isSubmitted)
                                    _buildStatusTag('Yuborilgan', Colors.blue)
                                  else
                                    _buildStatusTag('Topshirilmagan', Colors.orange),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(a.description, style: TextStyle(color: Colors.black87, fontSize: 15, height: 1.6)),
                              const SizedBox(height: 16),
                              if (a.deadline != null)
                                Row(
                                  children: [
                                    Icon(Icons.event_note, size: 16, color: a.deadline!.isBefore(DateTime.now()) ? Colors.red : Colors.red.shade400),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Topshirish muddati: ${DateFormat('yyyy-MM-dd HH:mm').format(a.deadline!.toLocal())}', 
                                      style: TextStyle(
                                        color: a.deadline!.isBefore(DateTime.now()) ? Colors.red : Colors.red.shade700, 
                                        fontWeight: FontWeight.bold, 
                                        fontSize: 13
                                      )
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 24),
                              const Divider(),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  if (a.filePath != null)
                                    TextButton.icon(
                                      onPressed: () async {
                                        final url = Uri.parse('http://localhost:5297${a.filePath}');
                                        if (await canLaunchUrl(url)) await launchUrl(url);
                                      },
                                      icon: const Icon(Icons.attach_file, size: 18),
                                      label: const Text('Faylni yuklab olish'),
                                    ),
                                  const Spacer(),
                                  ElevatedButton.icon(
                                    onPressed: (a.deadline != null && a.deadline!.isBefore(DateTime.now())) 
                                      ? null 
                                      : () => _showSubmitAssignmentDialog(a),
                                    icon: Icon(isSubmitted 
                                      ? Icons.published_with_changes 
                                      : (a.deadline != null && a.deadline!.isBefore(DateTime.now()) ? Icons.lock : Icons.file_upload_outlined)),
                                    label: Text(isSubmitted 
                                      ? 'Qayta topshirish' 
                                      : (a.deadline != null && a.deadline!.isBefore(DateTime.now()) ? 'Muddati o\'tgan' : 'Vazifani topshirish')),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isSubmitted ? Colors.blue.shade700 : (a.deadline != null && a.deadline!.isBefore(DateTime.now()) ? Colors.red.shade50 : const Color(0xFF1E3A8A)),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                                ],
                              ),
                              if (isAdmin) ...[
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    _buildAdminActionBtn(Icons.edit_note_rounded, 'Tahrirlash', Colors.blue, () => _showAssignmentDialog(assignment: a)),
                                    const SizedBox(width: 8),
                                    _buildAdminActionBtn(Icons.assessment_outlined, 'Natijalar', Colors.green, () => _showSubmissionsMonitoringDialog()),
                                  ],
                                ),
                              ]
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(30), border: Border.all(color: color.withOpacity(0.3))),
      child: Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildAdminActionBtn(IconData icon, String tooltip, Color color, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }

  Color _getGradeColor(double percentage) {
    if (percentage < 60) return Colors.red;
    if (percentage < 70) return Colors.orange;
    if (percentage <= 86) return Colors.blue;
    return Colors.green;
  }
}


