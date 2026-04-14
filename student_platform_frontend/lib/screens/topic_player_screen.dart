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
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.topic.title, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.indigo)),
              const SizedBox(height: 16),
              Text(widget.topic.content, style: const TextStyle(fontSize: 18, height: 1.6)),
              const SizedBox(height: 48),
              
              // Videos Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Video darslar', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  if (isAdmin)
                    TextButton.icon(
                      onPressed: _showAddVideoDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Video qo\'shish'),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (videos.isEmpty)
                const Text('Hozircha videolar mavjud emas.')
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 300,
                    childAspectRatio: 16 / 10,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: videos.length,
                  itemBuilder: (context, index) {
                    final video = videos[index];
                    return Card(
                      elevation: 4,
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => _showVideoDialog(video),
                        child: Stack(
                          children: [
                            Container(
                              color: Colors.black87,
                              child: Center(child: Icon(Icons.play_circle_fill, color: Colors.white, size: 50)),
                            ),
                            Positioned(
                              bottom: 0, left: 0, right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                color: Colors.black54,
                                child: Text(video.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              
              const SizedBox(height: 48),
              
              // Documents Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Fayllar (PDF)', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  if (isAdmin)
                    TextButton.icon(
                      onPressed: _showAddDocumentDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Fayl qo\'shish'),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (docs.isEmpty)
                const Text('Hujjatlar mavjud emas.')
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                        title: Text(doc.title),
                        trailing: const Icon(Icons.open_in_new),
                        onTap: () async {
                          final url = Uri.parse('http://localhost:5297${doc.filePath}');
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url);
                          }
                        },
                      ),
                    );
                  },
                ),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
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
                                          '${_apiService.baseUrl.replaceAll('/api', '')}${q.imagePath?.startsWith('/') == true ? q.imagePath : '/$q.imagePath'}',
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
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Testlar ro\'yxati', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo)),
                if (isAdmin)
                  ElevatedButton.icon(
                    onPressed: _showAddQuizDialog,
                    icon: const Icon(Icons.add_task),
                    label: const Text('Yangi Test qo\'shish'),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            if (quizzes.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.only(top: 100), child: Text('Hozircha testlar belgilanmagan.')))
            else
              Expanded(
                child: ListView.builder(
                  itemCount: quizzes.length,
                  itemBuilder: (context, index) {
                    final q = quizzes[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: InkWell(
                        onTap: () => _showQuizDetailsDialog(q),
                        borderRadius: BorderRadius.circular(16),
                        child: Row(
                          children: [
                            if (q.imagePath != null)
                              ClipRRect(
                                borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
                                child: Image.network(
                                  '${_apiService.baseUrl.replaceAll('/api', '')}${q.imagePath?.startsWith('/') == true ? q.imagePath : '/$q.imagePath'}',
                                  width: 150,
                                  height: 150,
                                  fit: BoxFit.cover,
                                  errorBuilder: (ctx, _, __) => Container(width: 150, height: 150, color: Colors.grey.shade200, child: const Icon(Icons.image)),
                                ),
                              ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(q.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8),
                                    Text(q.content, maxLines: 2, overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        const Icon(Icons.timer_outlined, size: 16, color: Colors.orange),
                                        const SizedBox(width: 4),
                                        Text('${q.timeLimitMinutes} daqiqa', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                                        const SizedBox(width: 16),
                                        const Icon(Icons.help_outline, size: 16, color: Colors.blue),
                                        const SizedBox(width: 4),
                                        Text('${q.questions.length} savol', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        ElevatedButton(
                                          onPressed: () {
                                            Navigator.push(context, MaterialPageRoute(builder: (context) => QuizScreen(quiz: q)));
                                          },
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                                          child: const Text('Testni boshlash'),
                                        ),
                                        const SizedBox(width: 12),
                                        OutlinedButton.icon(
                                          onPressed: () => _showQuizDetailsDialog(q),
                                          icon: const Icon(Icons.quiz_outlined),
                                          label: const Text('Test savollarni ko\'rish'),
                                          style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.indigo)),
                                        ),
                                        if (isAdmin) ...[
                                          const SizedBox(width: 8),
                                          IconButton(
                                            onPressed: () => _showAddQuestionDialog(q.id),
                                            icon: const Icon(Icons.add_circle, color: Colors.green, size: 30),
                                            tooltip: 'Savol qo\'shish',
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            onPressed: () => _showQuizResultsDialog(q),
                                            icon: const Icon(Icons.analytics, color: Colors.deepPurple, size: 30),
                                            tooltip: 'Natijalarni ko\'rish',
                                          ),
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
                    );
                  },
                ),
              ),
          ],
        ),
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
          return AlertDialog(
            title: const Text('Yangi Test to\'plami yaratish'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Test nomi')),
                  TextField(controller: contentController, decoration: const InputDecoration(labelText: 'Tavsif / Content'), maxLines: 2),
                  TextField(
                    controller: timeController,
                    decoration: const InputDecoration(labelText: 'Vaqt (jami minutda)', hintText: 'Masalan: 30'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  if (imageName != null)
                    Text('Rasm: $imageName', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  OutlinedButton.icon(
                    onPressed: () async {
                      FilePickerResult? result = await FilePicker.pickFiles(type: FileType.image, withData: true);
                      if (result != null) {
                        setDialogState(() {
                          imageBytes = result.files.first.bytes;
                          imageName = result.files.first.name;
                        });
                      }
                    },
                    icon: const Icon(Icons.image),
                    label: const Text('Test uchun rasm tanlash'),
                  ),
                  if (isUploading) const CircularProgressIndicator(),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Bekor qilish')),
              ElevatedButton(
                onPressed: isUploading ? null : () async {
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
                child: const Text('Saqlash'),
              ),
            ],
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
  void _showAddAssignmentDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final scoreController = TextEditingController();
    DateTime? selectedDate;
    Uint8List? fileBytes;
    String? fileName;
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Yangi mustaqil ish (Vazifa) qo\'shish'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Vazifa nomi')),
                  const SizedBox(height: 8),
                  TextField(controller: descController, decoration: const InputDecoration(labelText: 'Vazifa sharti / Content'), maxLines: 3),
                  const SizedBox(height: 8),
                  TextField(controller: scoreController, decoration: const InputDecoration(labelText: 'Maksimal ball'), keyboardType: TextInputType.number),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(selectedDate == null ? 'Muddati belgilanmagan' : 'Muddat: ${selectedDate!.toString().split(' ')[0]}'),
                      const Spacer(),
                      TextButton(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) setDialogState(() => selectedDate = date);
                        },
                        child: const Text('Sanani tanlash'),
                      ),
                    ],
                  ),
                  const Divider(),
                  if (fileName != null)
                    Text('Fayl: $fileName', style: const TextStyle(color: Colors.green)),
                  OutlinedButton.icon(
                    onPressed: () async {
                      FilePickerResult? result = await FilePicker.pickFiles(withData: true);
                      if (result != null) {
                        setDialogState(() {
                          fileBytes = result.files.first.bytes;
                          fileName = result.files.first.name;
                        });
                      }
                    },
                    icon: const Icon(Icons.attach_file),
                    label: const Text('Vazifa faylini yuklash (ixtiyoriy)'),
                  ),
                  if (isUploading) const LinearProgressIndicator(),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Bekor qilish')),
              ElevatedButton(
                onPressed: isUploading
                    ? null
                    : () async {
                        setDialogState(() => isUploading = true);
                        final success = await _apiService.createAssignment(
                          topicId: widget.topic.id,
                          title: titleController.text,
                          description: descController.text,
                          maxScore: int.tryParse(scoreController.text) ?? 100,
                          deadline: selectedDate,
                          fileBytes: fileBytes,
                          fileName: fileName,
                        );
                        if (success && mounted) {
                          Navigator.pop(context);
                          _fetchTopicContent();
                        } else {
                          setDialogState(() => isUploading = false);
                        }
                      },
                child: const Text('Saqlash'),
              ),
            ],
          );
        },
      ),
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
                                            decoration: BoxDecoration(color: Colors.green.shade700, borderRadius: BorderRadius.circular(8)),
                                            child: Text('Baholangan: ${s.grade} ball', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
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
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          ElevatedButton(
                                            onPressed: isGrading
                                                ? null
                                                : () async {
                                                    setDialogState(() => isGrading = true);
                                                    final success = await _apiService.gradeSubmission(s.id, int.tryParse(gradeController.text) ?? 0, "");
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
                                        ] else
                                          const Text('Baholangan ✅', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
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
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Mustaqil ishlar ro\'yxati', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo)),
                if (isAdmin)
                   Row(
                     children: [
                       ElevatedButton.icon(
                         onPressed: _showSubmissionsMonitoringDialog,
                         icon: const Icon(Icons.people),
                         label: const Text('Topshirganlar'),
                         style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade700),
                       ),
                       const SizedBox(width: 12),
                       ElevatedButton.icon(
                         onPressed: _showAddAssignmentDialog,
                         icon: const Icon(Icons.add),
                         label: const Text('Vazifa qo\'shish'),
                       ),
                     ],
                   ),
              ],
            ),
            const SizedBox(height: 24),
            if (assignments.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.only(top: 100), child: Text('Hozircha vazifalar belgilanmagan.')))
            else
              Expanded(
                child: ListView.builder(
                  itemCount: assignments.length,
                  itemBuilder: (context, index) {
                    final a = assignments[index];
                    final bool isGraded = a.grade != null;
                    final bool isSubmitted = a.isSubmitted;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 20),
                      elevation: isGraded ? 4 : 1,
                      shadowColor: isGraded ? Colors.green.withOpacity(0.3) : Colors.black12,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isGraded 
                              ? Colors.green.shade300 
                              : (isSubmitted ? Colors.blue.shade200 : Colors.transparent),
                          width: 1.5,
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: isGraded 
                            ? LinearGradient(
                                colors: [Colors.green.shade50, Colors.white],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : (isSubmitted 
                                ? LinearGradient(
                                    colors: [Colors.blue.shade50, Colors.white],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(a.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                                        const SizedBox(height: 4),
                                        Text('Maksimum: ${a.maxScore} ball', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                                      ],
                                    ),
                                  ),
                                  if (isGraded)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade600,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.stars, color: Colors.white, size: 18),
                                          const SizedBox(width: 6),
                                          Text('${a.grade} ball', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    )
                                  else if (isSubmitted)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(color: Colors.blue.shade600, borderRadius: BorderRadius.circular(10)),
                                      child: const Row(
                                        children: [
                                          Icon(Icons.access_time, color: Colors.white, size: 16),
                                          SizedBox(width: 6),
                                          Text('Tekshirilmoqda', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(a.description, style: TextStyle(color: Colors.black54, height: 1.5)),
                              const SizedBox(height: 16),
                              if (a.deadline != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.event_available, size: 16, color: Colors.red.shade700),
                                      const SizedBox(width: 8),
                                      Text('Muddat: ${a.deadline.toString().split(' ')[0]}', style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold, fontSize: 13)),
                                    ],
                                  ),
                                ),
                              const SizedBox(height: 20),
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
                                      icon: const Icon(Icons.description_outlined, color: Colors.indigo),
                                      label: const Text('Topshiriq fayli', style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.w600)),
                                    ),
                                  const Spacer(),
                                  if (isGraded)
                                    const Row(
                                      children: [
                                        Icon(Icons.check_circle, color: Colors.green),
                                        SizedBox(width: 8),
                                        Text('Baholangan', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                      ],
                                    )
                                  else
                                    ElevatedButton.icon(
                                      onPressed: isSubmitted ? null : () => _showSubmitAssignmentDialog(a),
                                      icon: Icon(isSubmitted ? Icons.done_all : Icons.cloud_upload_outlined),
                                      label: Text(isSubmitted ? 'Topshirilgan' : 'Javob yuborish'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isSubmitted ? Colors.grey.shade400 : Colors.indigo.shade600,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        elevation: isSubmitted ? 0 : 4,
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
              ),
          ],
        ),
      ),
    );
  }
}


