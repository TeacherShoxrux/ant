import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/auth/auth_cubit.dart';
import '../../services/api_service.dart';
import '../../logic/auth/auth_state.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:file_picker/file_picker.dart';
import 'package:student_platform_frontend/widgets/app_toast.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final padding = isMobile ? 16.0 : 32.0;

        return BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            if (state is! AuthAuthenticated) {
              return const Center(child: CircularProgressIndicator());
            }

            return SingleChildScrollView(
              padding: EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mening profilim',
                    style: TextStyle(fontSize: isMobile ? 24 : 28, fontWeight: FontWeight.bold, color: const Color(0xFF1E3A8A)),
                  ).animate().fadeIn().slideY(begin: 0.2),
                  const SizedBox(height: 8),
                  Text(
                    'Shaxsiy ma\'lumotlar va sozlamalar',
                    style: TextStyle(color: Colors.grey[600], fontSize: isMobile ? 14 : 16),
                  ).animate().fadeIn(delay: 100.ms),
                  const SizedBox(height: 32),
                  
                  Flex(
                    direction: isMobile ? Axis.vertical : Axis.horizontal,
                    crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                    children: [
                      // Profile Image & Actions
                      Column(
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: isMobile ? 60 : 80,
                                backgroundColor: const Color(0xFF1E3A8A).withOpacity(0.1),
                                backgroundImage: state.imagePath != null 
                                  ? NetworkImage('${ApiService.serverUrl}${state.imagePath}?v=${DateTime.now().millisecondsSinceEpoch}') 
                                  : null,
                                child: state.imagePath == null 
                                  ? Icon(Icons.person, size: isMobile ? 60 : 80, color: const Color(0xFF1E3A8A))
                                  : null,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  decoration: const BoxDecoration(color: Color(0xFF1E3A8A), shape: BoxShape.circle),
                                  child: IconButton(
                                    icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                                    onPressed: () => _pickAndUploadImage(context),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (isMobile) ...[
                             Text(
                               state.fullName, 
                               style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                               textAlign: TextAlign.center,
                             ),
                             Text(state.role, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                          ],
                        ],
                      ),
                      if (!isMobile) const SizedBox(width: 48) else const SizedBox(height: 32),
                      
                      // Details
                      Expanded(
                        flex: isMobile ? 0 : 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isMobile) ...[
                              Text(state.fullName, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(color: const Color(0xFF1E3A8A).withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                                child: Text(state.role, style: const TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(height: 32),
                            ],
                            _buildInfoCard(
                              title: 'Bog\'lanish ma\'lumotlari',
                              items: [
                                 {'label': 'Username', 'value': state.username, 'icon': Icons.alternate_email},
                                 {'label': 'ID', 'value': '#${state.username}', 'icon': Icons.badge_outlined},
                               ],
                            ),
                            const SizedBox(height: 24),
                             _buildInfoCard(
                               title: 'Tizim ma\'lumotlari',
                               items: [
                                 {'label': 'Status', 'value': 'Faol', 'icon': Icons.check_circle_outline},
                               ],
                             ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  SizedBox(
                    width: isMobile ? double.infinity : null,
                    child: const _ChangePasswordWidget(),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  Card(
                    elevation: 0,
                    color: Colors.red.shade50,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.red.shade200),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => context.read<AuthCubit>().logout(),
                      child: Padding(
                        padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
                        child: Row(
                          mainAxisAlignment: isMobile ? MainAxisAlignment.center : MainAxisAlignment.start,
                          children: [
                            const Icon(Icons.logout, color: Colors.red),
                            const SizedBox(width: 16),
                            Text(
                              'Tizimdan chiqish', 
                              style: TextStyle(
                                color: Colors.red, 
                                fontWeight: FontWeight.bold, 
                                fontSize: isMobile ? 14 : 16
                              )
                            ),
                          ],
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 200.ms),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _pickAndUploadImage(BuildContext context) async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );

    if (result != null && result.files.single.bytes != null) {
      final bytes = result.files.single.bytes!;
      final fileName = result.files.single.name;
      
      final apiService = ApiService();
      final newPath = await apiService.updateProfileImage(bytes, fileName);
      
      if (newPath != null) {
        if (context.mounted) {
          context.read<AuthCubit>().updateImage(newPath);
          AppToast.show(context, 'Profil rasmi muvaffaqiyatli yangilandi');
        }
      } else {
        if (context.mounted) {
          AppToast.show(context, 'Rasmni yuklashda xatolik yuz berdi. Server javobini tekshiring.', isError: true);
        }
      }
    }
  }

  Widget _buildInfoCard({required String title, required List<Map<String, dynamic>> items}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E3A8A))),
            const SizedBox(height: 16),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                children: [
                  Icon(item['icon'] as IconData, size: 20, color: Colors.grey),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['label'] as String, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      Text(item['value'] as String, style: const TextStyle(fontWeight: FontWeight.w500)),
                    ],
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}

class _ChangePasswordWidget extends StatefulWidget {
  const _ChangePasswordWidget();

  @override
  State<_ChangePasswordWidget> createState() => _ChangePasswordWidgetState();
}

class _ChangePasswordWidgetState extends State<_ChangePasswordWidget> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _apiService = ApiService();
  bool _isLoading = false;
  bool _isExpanded = false;

  Future<void> _changePassword() async {
    final oldPwd = _oldPasswordController.text.trim();
    final newPwd = _newPasswordController.text.trim();
    final confirmPwd = _confirmPasswordController.text.trim();

    if (oldPwd.isEmpty || newPwd.isEmpty || confirmPwd.isEmpty) {
      AppToast.show(context, 'Barcha maydonlarni to\'ldiring');
      return;
    }

    if (newPwd != confirmPwd) {
      AppToast.show(context, 'Yangi parollar mos kelmadi');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final result = await _apiService.changePassword(oldPwd, newPwd);
      if (mounted) {
        AppToast.show(context, result['message'], isError: !result['success']);
        if (result['success']) {
          _oldPasswordController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();
          setState(() => _isExpanded = false);
        }
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(context, 'Tizim xatoligi yuz berdi', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isExpanded) {
      return OutlinedButton.icon(
        onPressed: () => setState(() => _isExpanded = true),
        icon: const Icon(Icons.lock_reset),
        label: const Text('Parolni o\'zgartirish'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Parolni o\'zgartirish',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                ),
                IconButton(
                  onPressed: () => setState(() => _isExpanded = false),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _oldPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Eski parol',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Yangi parol',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.vpn_key_outlined),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Yangi parolni tasdiqlang',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.check_circle_outline),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _changePassword,
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Parolni saqlash'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
