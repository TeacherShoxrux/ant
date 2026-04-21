import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../logic/notification/notification_cubit.dart';
import '../logic/notification/notification_state.dart';
import '../logic/auth/auth_cubit.dart';
import '../logic/auth/auth_state.dart';
import '../models/models.dart' as model;
import '../services/api_service.dart';
import '../widgets/responsive_dialog.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<NotificationCubit>().fetchNotifications();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    final isAdmin = authState is AuthAuthenticated && (authState.role == 'Admin' || authState.role == 'Moderator');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Xabarnomalar', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF1E293B),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all, color: Colors.blue),
            tooltip: 'Barchasini o\'qilgan qilish',
            onPressed: () => context.read<NotificationCubit>().markAllAsRead(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.grey),
            onPressed: () => context.read<NotificationCubit>().fetchNotifications(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocBuilder<NotificationCubit, NotificationState>(
        builder: (context, state) {
          if (state is NotificationLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is NotificationError) {
            return Center(child: Text(state.message));
          }
          if (state is NotificationLoaded) {
            if (state.notifications.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications_none_rounded, size: 80, color: Colors.grey.withOpacity(0.3)),
                    const SizedBox(height: 16),
                    const Text('Hozircha xabarnomalar yo\'q', style: TextStyle(color: Colors.grey, fontSize: 16)),
                  ],
                ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: state.notifications.length,
              itemBuilder: (context, index) {
                final model.NotificationModel notification = state.notifications[index];
                return _NotificationCard(notification: notification, index: index);
              },
            );
          }
          return const SizedBox();
        },
      ),
      floatingActionButton: isAdmin 
          ? Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  )
                ],
              ),
              child: FloatingActionButton.extended(
                onPressed: _showSendNotificationDialog,
                icon: const Icon(Icons.send_rounded, color: Colors.white),
                label: const Text('Xabar yuborish', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                backgroundColor: Colors.transparent,
                elevation: 0,
                hoverElevation: 0,
                focusElevation: 0,
                highlightElevation: 0,
              ),
            ).animate().slideY(begin: 1, duration: 500.ms, curve: Curves.easeOutQuart)
          : null,
    );
  }

  void _showSendNotificationDialog() async {
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    String targetType = 'All';
    int? selectedGroupId;
    
    final apiService = ApiService();
    List<model.Group> groups = [];
    try {
      final groupsData = await apiService.getGroups();
      groups = (groupsData as List).map((g) => model.Group.fromJson(g as Map<String, dynamic>)).toList();
    } catch (e) {}

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => ResponsiveDialog(
          title: 'Yangi xabarnoma',
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Xabar ma\'lumotlarini kiriting', style: TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Mavzu',
                  hintText: 'Muhim xabar...',
                  prefixIcon: const Icon(Icons.title_rounded, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: messageController,
                decoration: InputDecoration(
                  labelText: 'Xabar matni',
                  hintText: 'Xabar tafsilotlarini kiriting...',
                  prefixIcon: const Icon(Icons.message_outlined, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              const Text('Kimlarga yuboriladi?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: targetType,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'All', child: Text('Barchaga (Hamma foydalanuvchilarga)')),
                      DropdownMenuItem(value: 'Admins', child: Text('Faqat Adminlarga')),
                      DropdownMenuItem(value: 'Group', child: Text('Muayyan guruhga')),
                    ],
                    onChanged: (val) {
                      setDialogState(() {
                        targetType = val!;
                        if (targetType != 'Group') selectedGroupId = null;
                      });
                    },
                  ),
                ),
              ),
              if (targetType == 'Group') ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: selectedGroupId,
                      hint: const Text('Guruhni tanlang'),
                      isExpanded: true,
                      items: groups.map<DropdownMenuItem<int>>((g) => DropdownMenuItem<int>(
                        value: g.id, 
                        child: Text(g.name),
                      )).toList(),
                      onChanged: (val) {
                        setDialogState(() => selectedGroupId = val);
                      },
                    ),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx), 
              child: const Text('Bekor qilish', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: () async {
                if (titleController.text.isEmpty || messageController.text.isEmpty) return;
                if (targetType == 'Group' && selectedGroupId == null) return;

                final success = await context.read<NotificationCubit>().sendNotification(
                  titleController.text,
                  messageController.text,
                  targetType,
                  selectedGroupId,
                );

                if (success && mounted) {
                  Navigator.pop(dialogCtx);
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(
                      content: Text('Xabarnoma muvaffaqiyatli yuborildi!'), 
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: const Text('Yuborish', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final model.NotificationModel notification;
  final int index;

  const _NotificationCard({required this.notification, required this.index});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: notification.isRead ? Colors.grey[100]! : Colors.blue.withOpacity(0.2)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (!notification.isRead) {
            context.read<NotificationCubit>().markAsRead(notification.id);
          }
          _showDetailsDialog(context);
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: notification.isRead ? const Color(0xFFF1F5F9) : const Color(0xFFE0F2FE),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  notification.isRead ? Icons.notifications_outlined : Icons.notifications_active_rounded,
                  color: notification.isRead ? const Color(0xFF64748B) : const Color(0xFF0284C7),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontWeight: notification.isRead ? FontWeight.w600 : FontWeight.bold,
                              fontSize: 16,
                              color: notification.isRead ? const Color(0xFF334155) : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(color: Color(0xFF0EA5E9), shape: BoxShape.circle),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: const Color(0xFF64748B), fontSize: 14, height: 1.4),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              notification.senderName ?? "Tizim",
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                        Text(
                          DateFormat('dd.MM HH:mm').format(notification.createdAt),
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: (index * 50).ms).slideX(begin: 0.1, duration: 300.ms, delay: (index * 50).ms);
  }

  void _showDetailsDialog(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Notification Details',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => const SizedBox(),
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(child: Text(notification.title)),
              ],
            ),
            content: SingleChildScrollView(
              child: Text(
                notification.message,
                style: const TextStyle(fontSize: 15, height: 1.5, color: Color(0xFF334155)),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context), 
                child: const Text('Tushunarli', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ],
          ),
        );
      },
    );
  }
}
