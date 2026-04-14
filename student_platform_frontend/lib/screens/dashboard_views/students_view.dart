import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'package:flutter_animate/flutter_animate.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>>? _students;
  bool _isLoading = true;

  List<Map<String, dynamic>> _groups = [];
  String _searchQuery = '';
  int? _selectedFilterGroupId;

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  Future<void> _fetchStudents() async {
    setState(() => _isLoading = true);
    final students = await _apiService.getStudents();
    final groups = await _apiService.getGroups();
    if (mounted) {
      setState(() {
        _students = students;
        _groups = groups;
        _isLoading = false;
      });
    }
  }

  // Same logic from the old HomeScreen...
  void _showAddStudentDialog() async {
    final nameController = TextEditingController();
    final surnameController = TextEditingController();
    final patronymicController = TextEditingController();
    final phoneController = TextEditingController();
    final userController = TextEditingController();
    final passController = TextEditingController();
    
    int? selectedGroupId;
    Uint8List? faceBytes;
    String? faceName;
    bool isSaving = false;

    // Use fetched groups or refetch
    List<Map<String, dynamic>> dialogGroups = _groups.isEmpty ? await _apiService.getGroups() : _groups;

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Yangi Talaba Qo\'shish', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                      const SizedBox(height: 32),
                      
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
                      TextField(controller: patronymicController, decoration: const InputDecoration(labelText: 'Sharifi', border: OutlineInputBorder())),
                      const SizedBox(height: 16),
                      TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Telefon raqami', border: OutlineInputBorder())),
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              value: selectedGroupId,
                              decoration: const InputDecoration(labelText: 'Guruh', border: OutlineInputBorder()),
                              items: dialogGroups.map((g) => DropdownMenuItem<int>(value: g['id'], child: Text(g['name']))).toList(),
                              onChanged: (val) => setDialogState(() => selectedGroupId = val),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(color: const Color(0xFF1E3A8A).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                            child: IconButton(
                              onPressed: () async {
                                final gController = TextEditingController();
                                final name = await showDialog<String>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Yangi guruh'),
                                    content: TextField(controller: gController, decoration: const InputDecoration(labelText: 'Guruh nomi')),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Bekor qilish')),
                                      ElevatedButton(onPressed: () => Navigator.pop(ctx, gController.text), child: const Text('Qo\'shish')),
                                    ],
                                  ),
                                );
                                if (name != null && name.isNotEmpty) {
                                  final newG = await _apiService.createGroup(name);
                                  if (newG != null) {
                                    final updatedGroups = await _apiService.getGroups();
                                    setDialogState(() {
                                      dialogGroups = updatedGroups;
                                      selectedGroupId = newG['id'];
                                    });
                                  }
                                }
                              },
                              icon: const Icon(Icons.group_add, color: Color(0xFF1E3A8A)),
                              tooltip: 'Yangi guruh yaratish',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      const Text('Tizimga kirish ma\'lumotlari', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 16),
                      TextField(controller: userController, decoration: const InputDecoration(labelText: 'Login*', border: OutlineInputBorder())),
                      const SizedBox(height: 16),
                      TextField(controller: passController, decoration: const InputDecoration(labelText: 'Parol*', border: OutlineInputBorder()), obscureText: true),
                      
                      const SizedBox(height: 40),
                      if (isSaving) const Center(child: CircularProgressIndicator()),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: isSaving ? null : () async {
                            if (nameController.text.isEmpty || surnameController.text.isEmpty || userController.text.isEmpty || passController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Yulduzcha bilan belgilangan maydonlarni to\'ldiring')));
                              return;
                            }
                            if (selectedGroupId == null) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Guruhni tanlash majburiy!')));
                              return;
                            }
                            if (faceBytes == null) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Talaba yuz rasmini yuklash majburiy!')));
                              return;
                            }
                            
                            setDialogState(() => isSaving = true);
                            final success = await _apiService.createStudent(
                              fullName: '${nameController.text} ${surnameController.text}',
                              patronymic: patronymicController.text,
                              username: userController.text,
                              password: passController.text,
                              phoneNumber: phoneController.text,
                              groupId: selectedGroupId,
                              imageBytes: faceBytes,
                              imageName: faceName,
                            );
                            if (success && mounted) {
                              Navigator.pop(context);
                              _fetchStudents();
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Talaba muvaffaqiyatli qo\'shildi')));
                            } else {
                              setDialogState(() => isSaving = false);
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Xatolik yuz berdi. Iltimos barcha ma\'lumotlarni tekshiring.')));
                            }
                          },
                          child: const Text('Saqlash', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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

  void _showStudentDetails(Map<String, dynamic> student) {
    final gId = student['groupId'];
    final gMap = _groups.where((g) => g['id'] == gId).toList();
    final groupName = gMap.isNotEmpty ? gMap.first['name'] : 'Biriktirilmagan';
    final isDisabled = student['isDisabled'] ?? false;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Talaba ma\'lumotlari', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: const Color(0xFF1E3A8A).withOpacity(0.1),
              backgroundImage: student['imagePath'] != null 
                ? NetworkImage('http://localhost:5297${student['imagePath']}') 
                : null,
              child: student['imagePath'] == null 
                  ? const Icon(Icons.person, size: 60, color: Color(0xFF1E3A8A))
                  : null,
            ),
            const SizedBox(height: 16),
            Text(student['fullName'] ?? '', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            if (student['patronymic'] != null && student['patronymic'].isNotEmpty)
              Text(student['patronymic'], style: const TextStyle(fontSize: 18, color: Colors.grey)),
            const Divider(height: 32),
            _infoRow(Icons.group, 'Guruh:', groupName),
            _infoRow(Icons.account_circle, 'Login:', student['username']),
            _infoRow(Icons.phone, 'Telefon:', student['phoneNumber'] ?? 'Mavjud emas'),
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

  void _confirmDeleteStudent(Map<String, dynamic> student) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Diqqat!'),
        content: Text('Siz rostdan ham "${student['fullName']}" talabasini ro\'yxatdan o\'chirmoqchimisiz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Yo\'q')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final ok = await _apiService.deleteStudent(student['id']);
              if (ok && mounted) {
                Navigator.pop(ctx);
                _fetchStudents();
              }
            },
            child: const Text('Ha, O\'chirish'),
          ),
        ],
      ),
    );
  }

  void _editStudentDialog(Map<String, dynamic> student) async {
    final fullName = (student['fullName'] as String).split(' ');
    final nameController = TextEditingController(text: fullName.first);
    final surnameController = TextEditingController(text: fullName.length > 1 ? fullName.sublist(1).join(' ') : '');
    final patronymicController = TextEditingController(text: student['patronymic']);
    final phoneController = TextEditingController(text: student['phoneNumber']);
    final userController = TextEditingController(text: student['username']);
    
    int? selectedGroupId = student['groupId'];
    Uint8List? faceBytes;
    String? faceName;
    bool isSaving = false;

    List<Map<String, dynamic>> dialogGroups = _groups;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Talaba ma\'lumotlarini tahrirlash', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                      const SizedBox(height: 32),
                      
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
                            backgroundImage: faceBytes != null 
                              ? MemoryImage(faceBytes!) 
                              : (student['imagePath'] != null ? NetworkImage('http://localhost:5297${student['imagePath']}') : null),
                            child: (faceBytes == null && student['imagePath'] == null) ? const Icon(Icons.add_a_photo, size: 40, color: Colors.grey) : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Ism*', border: OutlineInputBorder())),
                      const SizedBox(height: 16),
                      TextField(controller: surnameController, decoration: const InputDecoration(labelText: 'Familiya*', border: OutlineInputBorder())),
                      const SizedBox(height: 16),
                      TextField(controller: patronymicController, decoration: const InputDecoration(labelText: 'Sharifi', border: OutlineInputBorder())),
                      const SizedBox(height: 16),
                      TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Telefon raqami', border: OutlineInputBorder())),
                      const SizedBox(height: 16),
                      
                      DropdownButtonFormField<int>(
                        value: selectedGroupId,
                        decoration: const InputDecoration(labelText: 'Guruh', border: OutlineInputBorder()),
                        items: dialogGroups.map((g) => DropdownMenuItem<int>(value: g['id'], child: Text(g['name']))).toList(),
                        onChanged: (val) => setDialogState(() => selectedGroupId = val),
                      ),
                      const SizedBox(height: 16),
                      TextField(controller: userController, decoration: const InputDecoration(labelText: 'Login*', border: OutlineInputBorder())),
                      
                      const SizedBox(height: 40),
                      if (isSaving) const Center(child: CircularProgressIndicator()),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: isSaving ? null : () async {
                            if (nameController.text.isEmpty || surnameController.text.isEmpty || userController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Majburiy maydonlarni to\'ldiring')));
                              return;
                            }
                            
                            setDialogState(() => isSaving = true);
                            final success = await _apiService.updateStudent(
                              id: student['id'],
                              fullName: '${nameController.text} ${surnameController.text}',
                              patronymic: patronymicController.text,
                              username: userController.text,
                              phoneNumber: phoneController.text,
                              groupId: selectedGroupId,
                              imageBytes: faceBytes,
                              imageName: faceName,
                            );
                            if (success && mounted) {
                              Navigator.pop(context);
                              _fetchStudents();
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('O\'zgarishlar saqlandi')));
                            } else {
                              setDialogState(() => isSaving = false);
                            }
                          },
                          child: const Text('O\'zgarishlarni saqlash', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    final filteredStudents = _students?.where((s) {
      final matchesQuery = s['fullName']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false;
      final matchesGroup = _selectedFilterGroupId == null || s['groupId'] == _selectedFilterGroupId;
      return matchesQuery && matchesGroup;
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Talabalar ro\'yxati',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                  ).animate().fadeIn().slideY(begin: 0.2),
                  const SizedBox(height: 8),
                  Text(
                    filteredStudents != null ? 'Jami: ${filteredStudents.length} ta talaba' : 'Yuklanmoqda...',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ).animate().fadeIn(delay: 100.ms),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _showAddStudentDialog,
                icon: const Icon(Icons.person_add),
                label: const Text('Talaba qo\'shish'),
              ).animate().fadeIn(delay: 200.ms).scale(),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Ism bo\'yicha qidirish...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (val) {
                    setState(() => _searchQuery = val);
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 1,
                child: DropdownButtonFormField<int?>(
                  value: _selectedFilterGroupId,
                  decoration: InputDecoration(
                    hintText: 'Barcha guruhlar',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: [
                    const DropdownMenuItem<int?>(value: null, child: Text('Barcha guruhlar')),
                    ..._groups.map((g) => DropdownMenuItem<int?>(value: g['id'], child: Text(g['name'])))
                  ],
                  onChanged: (val) {
                    setState(() => _selectedFilterGroupId = val);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          if (filteredStudents == null || filteredStudents.isEmpty)
            const Expanded(child: Center(child: Text('Talabalar mavjud emas.')))
          else
            Expanded(
              child: ListView.builder(
                itemCount: filteredStudents.length,
                itemBuilder: (context, index) {
                  final student = filteredStudents[index];
                  // Find group name
                  final gId = student['groupId'];
                  final gMap = _groups.where((g) => g['id'] == gId).toList();
                  final groupName = gMap.isNotEmpty ? gMap.first['name'] : 'Biriktirilmagan';
                  final isDisabled = student['isDisabled'] ?? false;

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
                      onTap: () => _showStudentDetails(student),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundColor: const Color(0xFF1E3A8A).withOpacity(0.1),
                          backgroundImage: student['imagePath'] != null 
                            ? NetworkImage('http://localhost:5297${student['imagePath']}') 
                            : null,
                          child: student['imagePath'] == null 
                              ? Text(student['fullName']?[0]?.toUpperCase() ?? 'S', style: const TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold)) 
                              : null,
                        ),
                        title: Row(
                          children: [
                            Text(student['fullName'] ?? 'Nomalum', style: TextStyle(fontWeight: FontWeight.bold, color: isDisabled ? Colors.grey : Colors.black)),
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
                        subtitle: Text('@${student['username']} | Tel: ${student['phoneNumber'] ?? 'Mavjud emas'} | Guruh: $groupName'),
                        trailing: PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          onSelected: (val) async {
                            if (val == 'edit') {
                              _editStudentDialog(student);
                            } else if (val == 'toggle') {
                              final ok = await _apiService.toggleStudentStatus(student['id']);
                              if (ok) _fetchStudents();
                            } else if (val == 'delete') {
                              _confirmDeleteStudent(student);
                            }
                          },
                          itemBuilder: (ctx) => [
                            const PopupMenuItem(
                              value: 'edit', 
                              child: Row(children: [
                                Icon(Icons.edit, size: 18, color: Colors.blue), 
                                SizedBox(width: 8), 
                                Text('Tahrirlash')
                              ])
                            ),
                            PopupMenuItem(
                              value: 'toggle', 
                              child: Row(children: [
                                Icon(isDisabled ? Icons.check_circle : Icons.block, size: 18, color: isDisabled ? Colors.green : Colors.orange), 
                                const SizedBox(width: 8), 
                                Text(isDisabled ? 'Faollashtirish' : 'Bloklash')
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
  }
}
