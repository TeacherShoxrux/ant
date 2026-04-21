import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/auth/auth_cubit.dart';
import '../../logic/auth/auth_state.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../widgets/responsive_dialog.dart';
import 'package:uuid/uuid.dart';
import 'package:student_platform_frontend/widgets/app_toast.dart';

class AdminsScreen extends StatefulWidget {
  const AdminsScreen({super.key});

  @override
  State<AdminsScreen> createState() => _AdminsScreenState();
}

class _AdminsScreenState extends State<AdminsScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>>? _admins;
  bool _isLoading = true;

  String _searchQuery = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _fetchAdmins();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _fetchAdmins() async {
    setState(() => _isLoading = true);
    final response = await _apiService.getAdmins(
      searchTerm: _searchQuery,
    );
    
    if (mounted) {
      setState(() {
        _admins = response;
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchQuery = query;
      });
      _fetchAdmins();
    });
  }

  bool _isSuperAdmin() {
    final state = context.read<AuthCubit>().state;
    if (state is AuthAuthenticated) {
      return state.username == 'admin';
    }
    return false;
  }

  void _showAddAdminDialog() async {
    final nameController = TextEditingController();
    final surnameController = TextEditingController();
    final phoneController = TextEditingController();
    final passController = TextEditingController();
    
    Uint8List? faceBytes;
    String? faceName;
    bool isSaving = false;
    bool isPasswordVisible = false;
    int roleId = 1;

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return ResponsiveDialog(
            title: 'Yangi Admin Qo\'shish',
            maxWidth: 700,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: InkWell(
                    onTap: () async {
                      FilePickerResult? result = await FilePicker.pickFiles(type: FileType.image, withData: true);
                      if (result != null) {
                        setDialogState(() {
                          faceBytes = result.files.first.bytes;
                          faceName = result.files.first.name;
                        });
                      }
                    },
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: faceBytes != null ? MemoryImage(faceBytes!) : null,
                      child: faceBytes == null ? const Icon(Icons.add_a_photo, size: 40, color: Colors.grey) : null,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Ism*', border: OutlineInputBorder())),
                const SizedBox(height: 16),
                TextField(controller: surnameController, decoration: const InputDecoration(labelText: 'Familiya*', border: OutlineInputBorder())),
                const SizedBox(height: 16),
                TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Telefon raqami (Login o\'rnida)*', border: OutlineInputBorder())),
                const SizedBox(height: 16),
                TextField(
                  controller: passController,
                  decoration: InputDecoration(
                    labelText: 'Parol*',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                      onPressed: () {
                        setDialogState(() {
                          isPasswordVisible = !isPasswordVisible;
                        });
                      },
                    ),
                  ),
                  obscureText: !isPasswordVisible,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: 1,
                  decoration: const InputDecoration(labelText: 'Rol*', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('Admin (To\'liq huquq)')),
                    DropdownMenuItem(value: 3, child: Text('Moderator (Admin qo\'sholmaydi)')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => roleId = val);
                    }
                  },
                ),
              ],
            ),
            actions: [
              if (isSaving) const CircularProgressIndicator()
              else ...[
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Bekor qilish')),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isEmpty || surnameController.text.isEmpty || phoneController.text.isEmpty || passController.text.isEmpty) {
                      AppToast.show(context, 'Barcha maydonlarni to\'ldiring');
                      return;
                    }
                    
                    setDialogState(() => isSaving = true);
                    final success = await _apiService.createAdmin(
                      fullName: '${nameController.text} ${surnameController.text}',
                      username: phoneController.text,
                      password: passController.text,
                      phoneNumber: phoneController.text,
                      roleId: roleId,
                      imageBytes: faceBytes,
                      imageName: faceName,
                    );
                    if (success && mounted) {
                      Navigator.pop(context);
                      _fetchAdmins();
                      AppToast.show(context, 'Admin muvaffaqiyatli qo\'shildi');
                    } else {
                      setDialogState(() => isSaving = false);
                      AppToast.show(context, 'Xatolik yuz berdi.');
                    }
                  },
                  child: const Text('Saqlash'),
                ),
              ]
            ],
          );
        },
      ),
    );
  }

  void _showAdminDetails(Map<String, dynamic> admin) {
    final isDisabled = admin['isDisabled'] ?? false;

    showDialog(
      context: context,
      builder: (context) => ResponsiveDialog(
        title: 'Admin ma\'lumotlari',
        content: Column(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: const Color(0xFF1E3A8A).withOpacity(0.1),
              backgroundImage: admin['imagePath'] != null 
                ? NetworkImage('http://localhost:5297${admin['imagePath']}') 
                : null,
              child: admin['imagePath'] == null 
                  ? const Icon(Icons.security, size: 60, color: Color(0xFF1E3A8A))
                  : null,
            ),
            const SizedBox(height: 16),
            Text(admin['fullName'] ?? '', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const Divider(height: 32),
            _infoRow(Icons.account_circle, 'Login:', admin['username']),
            _infoRow(Icons.phone, 'Telefon:', admin['phoneNumber'] ?? 'Mavjud emas'),
            _infoRow(Icons.info_outline, 'Holati:', isDisabled ? 'Faolsiz (Bloklangan)' : 'Faol'),
          ],
        ),
        actions: [
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Yopish')),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.indigo),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(child: Text(value, overflow: TextOverflow.ellipsis, textAlign: TextAlign.end)),
        ],
      ),
    );
  }

  void _confirmDeleteAdmin(Map<String, dynamic> admin) {
    if (admin['id'] == 1) {
      AppToast.show(context, 'Asosiy adminni o\'chirib bo\'lmaydi.');
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => ResponsiveDialog(
        title: 'Diqqat!',
        content: Text('Siz rostdan ham "${admin['fullName']}" adminni ro\'yxatdan o\'chirmoqchimisiz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Yo\'q')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final ok = await _apiService.deleteAdmin(admin['id']);
              if (ok && mounted) {
                Navigator.pop(ctx);
                _fetchAdmins();
              }
            },
            child: const Text('Ha, O\'chirish', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showResetPasswordDialog(Map<String, dynamic> admin) {
    final passController = TextEditingController();
    bool isSaving = false;
    bool isPasswordVisible = false;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => ResponsiveDialog(
          title: 'Parolni tiklash',
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('"${admin['fullName']}" (Login: ${admin['username']}) uchun yangi parolni kiriting:'),
              const SizedBox(height: 16),
              TextField(
                controller: passController,
                decoration: InputDecoration(
                  labelText: 'Yangi parol*',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                    onPressed: () {
                      setDialogState(() {
                        isPasswordVisible = !isPasswordVisible;
                      });
                    },
                  ),
                ),
                obscureText: !isPasswordVisible,
              ),
            ],
          ),
          actions: [
            if (isSaving) const CircularProgressIndicator()
            else ...[
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Bekor qilish')),
              ElevatedButton(
                onPressed: () async {
                  if (passController.text.isEmpty) return;
                  setDialogState(() => isSaving = true);
                  final ok = await _apiService.resetAdminPassword(admin['id'], passController.text);
                  if (ok && mounted) {
                    Navigator.pop(ctx);
                    AppToast.show(context, 'Parol muvaffaqiyatli yangilandi.');
                  } else {
                    setDialogState(() => isSaving = false);
                    AppToast.show(context, 'Xatolik yuz berdi.');
                  }
                },
                child: const Text('Saqlash'),
              ),
            ]
          ],
        ),
      ),
    );
  }

  void _showChangeRoleDialog(Map<String, dynamic> admin) {
    if (!mounted) return;
    
    int newRoleId = admin['roleName'] == 'Moderator' ? 3 : 1;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => ResponsiveDialog(
          title: 'Rolni O\'zgartirish',
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${admin['fullName']} uchun yangi rolni tanlang:'),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: newRoleId,
                decoration: const InputDecoration(labelText: 'Rol*', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('Admin (To\'liq huquq, qolgan hamma adminlarni ko\'radi)')),
                  DropdownMenuItem(value: 3, child: Text('Moderator (Faqat o\'zi ochgan fanlarni ko\'radi)')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setDialogState(() => newRoleId = val);
                  }
                },
              ),
            ],
          ),
          actions: [
            if (isSaving) const CircularProgressIndicator()
            else ...[
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Bekor qilish')),
              ElevatedButton(
                onPressed: () async {
                  setDialogState(() => isSaving = true);
                  final ok = await _apiService.changeAdminRole(admin['id'], newRoleId);
                  if (ok && mounted) {
                    Navigator.pop(ctx);
                    _fetchAdmins();
                    AppToast.show(context, 'Rol muvaffaqiyatli yangilandi!');
                  } else {
                    setDialogState(() => isSaving = false);
                    AppToast.show(context, 'Xatolik yuz berdi.');
                  }
                },
                child: const Text('Saqlash'),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUpdateAdminImage(Map<String, dynamic> admin) async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );

    if (result != null && result.files.single.bytes != null) {
      final bytes = result.files.single.bytes!;
      final fileName = result.files.single.name;
      
      final newPath = await _apiService.updateAdminImage(admin['id'], bytes, fileName);
      
      if (newPath != null && mounted) {
        _fetchAdmins();
        AppToast.show(context, 'Admin rasmi muvaffaqiyatli yangilandi');
      } else if (mounted) {
        AppToast.show(context, 'Xatolik yuz berdi', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSuperAdmin = _isSuperAdmin();
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final padding = isMobile ? 16.0 : 32.0;

        return Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              isMobile 
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Adminlar ro\'yxati',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                    ).animate().fadeIn().slideY(begin: 0.2),
                    const SizedBox(height: 12),
                    if (isSuperAdmin)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _showAddAdminDialog,
                          icon: const Icon(Icons.security),
                          label: const Text('Admin qo\'shish'),
                        ),
                      ).animate().fadeIn(delay: 200.ms).scale(),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Adminlar ro\'yxati',
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                        ).animate().fadeIn().slideY(begin: 0.2),
                        const SizedBox(height: 8),
                        Text(
                          _isLoading ? 'Yuklanmoqda...' : 'Jami: ${_admins?.length ?? 0} ta admin',
                          style: TextStyle(color: Colors.grey[600], fontSize: 16),
                        ).animate().fadeIn(delay: 100.ms),
                      ],
                    ),
                    if (isSuperAdmin)
                      ElevatedButton.icon(
                        onPressed: _showAddAdminDialog,
                        icon: const Icon(Icons.security),
                        label: const Text('Admin qo\'shish'),
                      ).animate().fadeIn(delay: 200.ms).scale(),
                  ],
                ),
              const SizedBox(height: 24),
          TextField(
            decoration: InputDecoration(
              hintText: 'Ism bo\'yicha qidirish...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: _onSearchChanged,
          ),
          const SizedBox(height: 24),
          
          if (_isLoading && (_admins == null || _admins!.isEmpty))
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_admins == null || _admins!.isEmpty)
            const Expanded(child: Center(child: Text('Adminlar mavjud emas.')))
          else
            Expanded(
              child: ListView.builder(
                itemCount: _admins!.length,
                itemBuilder: (context, index) {
                  final admin = _admins![index];
                  final isDisabled = admin['isDisabled'] ?? false;

                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 12),
                    color: isDisabled ? Colors.grey.shade50 : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: isDisabled ? Colors.grey.shade300 : Colors.grey.shade200),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _showAdminDetails(admin),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundColor: const Color(0xFF1E3A8A).withOpacity(0.1),
                          backgroundImage: admin['imagePath'] != null 
                            ? NetworkImage('http://localhost:5297${admin['imagePath']}') 
                            : null,
                          child: admin['imagePath'] == null 
                              ? const Icon(Icons.security, color: Color(0xFF1E3A8A))
                              : null,
                        ),
                        title: Row(
                          children: [
                            Text(admin['fullName'] ?? 'Nomalum', style: TextStyle(fontWeight: FontWeight.bold, color: isDisabled ? Colors.grey : Colors.black)),
                            if (admin['id'] == 1) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: Colors.blue.shade100, borderRadius: BorderRadius.circular(4)),
                                child: const Text('Asosiy Admin', style: TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ] else if (admin['roleName'] != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: admin['roleName'] == 'Moderator' ? Colors.purple.shade100 : Colors.teal.shade100, borderRadius: BorderRadius.circular(4)),
                                child: Text(admin['roleName'], style: TextStyle(color: admin['roleName'] == 'Moderator' ? Colors.purple : Colors.teal, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ],
                            if (isDisabled) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(4)),
                                child: const Text('Bloklangan', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ]
                          ],
                        ),
                        subtitle: Text('Tel/Login: ${admin['username']}'),
                        trailing: (admin['id'] == 1 || !isSuperAdmin) ? const SizedBox() : PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          onSelected: (val) async {
                            if (val == 'toggle') {
                              final ok = await _apiService.toggleAdminStatus(admin['id']);
                              if (ok) _fetchAdmins();
                            } else if (val == 'role') {
                              _showChangeRoleDialog(admin);
                            } else if (val == 'reset') {
                              _showResetPasswordDialog(admin);
                            } else if (val == 'delete') {
                              _confirmDeleteAdmin(admin);
                            } else if (val == 'image') {
                              _pickAndUpdateAdminImage(admin);
                            }
                          },
                          itemBuilder: (ctx) => [
                            PopupMenuItem(
                              value: 'toggle', 
                              child: Row(children: [
                                Icon(isDisabled ? Icons.check_circle : Icons.block, size: 18, color: isDisabled ? Colors.green : Colors.orange), 
                                const SizedBox(width: 8), 
                                Text(isDisabled ? 'Faollashtirish' : 'Bloklash')
                              ])
                            ),
                            const PopupMenuItem(
                              value: 'role', 
                              child: Row(children: [
                                Icon(Icons.manage_accounts, size: 18, color: Colors.purple), 
                                SizedBox(width: 8), 
                                Text('Rolni o\'zgartirish')
                              ])
                            ),
                            const PopupMenuItem(
                              value: 'reset', 
                              child: Row(children: [
                                Icon(Icons.lock_reset, size: 18, color: Colors.blue), 
                                SizedBox(width: 8), 
                                Text('Parolni tiklash')
                              ])
                            ),
                            const PopupMenuItem(
                              value: 'delete', 
                              child: Row(children: [
                                Icon(Icons.delete, size: 18, color: Colors.red), 
                                const SizedBox(width: 8), 
                                Text('O\'chirish', style: TextStyle(color: Colors.red))
                              ])
                            ),
                            const PopupMenuItem(
                              value: 'image', 
                              child: Row(children: [
                                Icon(Icons.camera_alt, size: 18, color: Colors.indigo), 
                                SizedBox(width: 8), 
                                Text('Rasmni yangilash')
                              ])
                            ),
                          ],
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: Duration(milliseconds: 50 * index)).slideX();
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}
}
