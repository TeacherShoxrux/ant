import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
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
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey = GlobalKey<ScaffoldMessengerState>();
  
  List<Topic>? _topics;
  List<OnlineMeeting>? _meetings;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final topics = await _apiService.getTopics(widget.subject.id);
    final meetings = await _apiService.getOnlineMeetings(widget.subject.id);
    if (mounted) {
      setState(() {
        _topics = topics;
        _meetings = meetings;
        _isLoading = false;
      });
    }
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
                _fetchData();
              }
            },
            child: const Text('Saqlash'),
          ),
        ],
      ),
    );
  }

  void _showAddMeetingDialog() {
    final titleController = TextEditingController();
    final urlController = TextEditingController();
    DateTime? selectedDate;
    TimeOfDay? selectedTime;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => ResponsiveDialog(
          title: 'Online Meet yoki Zoom qo\'shish',
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController, 
                  decoration: const InputDecoration(labelText: 'Mavzu (masalan: Ochiq dars)', border: OutlineInputBorder(), hintText: '1-darst...'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: urlController, 
                  decoration: const InputDecoration(labelText: 'Dars havolasi (Link)', border: OutlineInputBorder(), hintText: 'https://meet.google.com/...'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: Text(selectedDate == null ? 'Kuni' : DateFormat('dd.MM.yyyy').format(selectedDate!)),
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now().subtract(const Duration(days: 1)),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) setDialogState(() => selectedDate = date);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.access_time, size: 18),
                        label: Text(selectedTime == null ? 'Vaqti' : selectedTime!.format(context)),
                        onPressed: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (time != null) setDialogState(() => selectedTime = time);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Bekor qilish')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (titleController.text.trim().isEmpty || 
                    urlController.text.trim().isEmpty || 
                    selectedDate == null || 
                    selectedTime == null) {
                   ScaffoldMessenger.of(dialogCtx).showSnackBar(
                     const SnackBar(content: Text('Iltimos, barcha maydonlarni to\'ldiring!'), backgroundColor: Colors.orange)
                   );
                   return;
                }
                
                final startTime = DateTime(
                  selectedDate!.year, selectedDate!.month, selectedDate!.day,
                  selectedTime!.hour, selectedTime!.minute
                );

                try {
                  final success = await _apiService.createOnlineMeeting(
                    widget.subject.id,
                    titleController.text,
                    urlController.text,
                    startTime,
                  );
                  
                  if (success) {
                    if (mounted) {
                      Navigator.pop(dialogCtx);
                      _fetchData();
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(content: Text('Muvaffaqiyatli saqlandi!'), backgroundColor: Colors.green)
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(dialogCtx).showSnackBar(
                      const SnackBar(content: Text('Saqlashda xatolik! Server rad etdi.'), backgroundColor: Colors.red)
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(dialogCtx).showSnackBar(
                    SnackBar(content: Text('Xatolik: $e'), backgroundColor: Colors.red)
                  );
                }
              },
              child: const Text('Saqlash'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditMeetingDialog(OnlineMeeting meeting) {
    final titleController = TextEditingController(text: meeting.title);
    final urlController = TextEditingController(text: meeting.meetingUrl);
    DateTime? selectedDate = meeting.startTime;
    TimeOfDay? selectedTime = TimeOfDay.fromDateTime(meeting.startTime);

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => ResponsiveDialog(
          title: 'Online darsni tahrirlash',
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController, 
                  decoration: const InputDecoration(labelText: 'Mavzu nomi', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: urlController, 
                  decoration: const InputDecoration(labelText: 'Dars havolasi (Link)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: Text(DateFormat('dd.MM.yyyy').format(selectedDate!)),
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: selectedDate!,
                            firstDate: DateTime.now().subtract(const Duration(days: 365)),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) setDialogState(() => selectedDate = date);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.access_time, size: 18),
                        label: Text(selectedTime!.format(context)),
                        onPressed: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: selectedTime!,
                          );
                          if (time != null) setDialogState(() => selectedTime = time);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Bekor qilish')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (titleController.text.trim().isEmpty || urlController.text.trim().isEmpty) return;
                
                final startTime = DateTime(
                  selectedDate!.year, selectedDate!.month, selectedDate!.day,
                  selectedTime!.hour, selectedTime!.minute
                );

                try {
                  final success = await _apiService.updateOnlineMeeting(
                    meeting.id,
                    titleController.text,
                    urlController.text,
                    startTime,
                  );
                  
                  if (success) {
                    if (mounted) {
                      Navigator.pop(dialogCtx);
                      _fetchData();
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(content: Text('Muvaffaqiyatli yangilandi!'), backgroundColor: Colors.green)
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(dialogCtx).showSnackBar(
                      const SnackBar(content: Text('Yangilashda xatolik!'), backgroundColor: Colors.red)
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(dialogCtx).showSnackBar(
                    SnackBar(content: Text('Xatolik: $e'), backgroundColor: Colors.red)
                  );
                }
              },
              child: const Text('Saqlash'),
            ),
          ],
        ),
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
                _fetchData();
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
                _fetchData();
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
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.video_call_outlined, color: Colors.green, size: 28),
              tooltip: 'Online dars qo\'shish',
              onPressed: _showAddMeetingDialog,
            ),
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
          : _buildSliverBody(displayedTopics, isAdmin),
    );
  }

  Widget _buildSliverBody(List<Topic>? displayedTopics, bool isAdmin) {
    final now = DateTime.now();
    final upcomingMeetings = _meetings?.where((m) => m.startTime.isAfter(now.subtract(const Duration(minutes: 30)))).toList() ?? [];
    final historyMeetings = _meetings?.where((m) => m.startTime.isBefore(now.subtract(const Duration(minutes: 30)))).toList() ?? [];
    upcomingMeetings.sort((a, b) => a.startTime.compareTo(b.startTime));
    historyMeetings.sort((a, b) => b.startTime.compareTo(a.startTime));

    return CustomScrollView(
      slivers: [
        if (upcomingMeetings.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Yaqinlashib kelayotgan Online Darslar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                  const SizedBox(height: 12),
                  ...upcomingMeetings.map((m) => _buildMeetingCard(m, isAdmin, isActive: true)),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms),
          ),

        if (displayedTopics != null && displayedTopics.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final topic = displayedTopics[index];
                  final isDisabled = topic.isDisabled;
                  final isLast = index == displayedTopics.length - 1;
                  return _buildTopicTimelineItem(topic, index, isLast, isDisabled, isAdmin);
                },
                childCount: displayedTopics.length,
              ),
            ),
          )
        else
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Text(
                upcomingMeetings.isEmpty && historyMeetings.isEmpty ? 'Bu fanda hali o\'quv reja yoki darslar yo\'q.' : '',
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          ),

        if (historyMeetings.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const SizedBox(height: 12),
                  const Text('O\'tib ketgan onlayn darslar (Tarix)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 8),
                  ...historyMeetings.map((m) => _buildMeetingCard(m, isAdmin, isActive: false)),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMeetingCard(OnlineMeeting meeting, bool isAdmin, {required bool isActive}) {
    return Card(
      color: isActive ? Colors.white : Colors.grey[50],
      elevation: isActive ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isActive ? Colors.green.shade200 : Colors.grey.shade300),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Icon(Icons.video_camera_front, color: isActive ? Colors.green : Colors.grey, size: 32),
        title: Text(meeting.title, style: TextStyle(fontWeight: FontWeight.bold, color: isActive ? Colors.black87 : Colors.grey)),
        subtitle: Text(DateFormat('dd.MM.yyyy HH:mm').format(meeting.startTime)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isActive)
              ElevatedButton.icon(
                onPressed: () async {
                  final uri = Uri.parse(meeting.meetingUrl);
                  if (await canLaunchUrl(uri)) await launchUrl(uri);
                },
                icon: const Icon(Icons.link, size: 16),
                label: const Text('Qo\'shilish'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              ),
            if (isAdmin)
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                onPressed: () => _showEditMeetingDialog(meeting),
              ),
            if (isAdmin)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (c) => AlertDialog(
                      title: const Text('Diqqat'),
                      content: const Text('Ushbu darsni rostdan ham o\'chirmoqchimisiz?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Yo\'q')),
                        ElevatedButton(onPressed: () => Navigator.pop(c, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Ha, O\'chirish', style: TextStyle(color: Colors.white))),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await _apiService.deleteOnlineMeeting(meeting.id);
                    _fetchData();
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicTimelineItem(Topic topic, int index, bool isLast, bool isDisabled, bool isAdmin) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDisabled ? Colors.grey.shade300 : const Color(0xFF1E3A8A),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 2, color: Colors.grey.shade300, margin: const EdgeInsets.symmetric(vertical: 4)),
                ),
            ],
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 8))],
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
                                Text(topic.title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDisabled ? Colors.grey : const Color(0xFF1E3A8A))),
                                const SizedBox(height: 4),
                                Text(topic.content, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey.shade600)),
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
                                  _fetchData();
                                }
                                else if (val == 'delete') _confirmDeleteTopic(topic);
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(value: 'edit', child: Text('Tahrirlash')),
                                PopupMenuItem(value: 'toggle', child: Text(isDisabled ? 'Yoqish' : 'O\'chirish')),
                                const PopupMenuItem(value: 'delete', child: Text('O\'chirish')),
                              ],
                            )
                          else
                            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
