import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'dart:async';
import 'package:flutter_animate/flutter_animate.dart';
import '../../widgets/responsive_dialog.dart';
import 'package:uuid/uuid.dart';
import 'package:student_platform_frontend/widgets/app_toast.dart';

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

  // Pagination state
  int _pageNumber = 1;
  int _pageSize = 10;
  int _totalCount = 0;
  int _totalPages = 0;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _fetchGroups();
    _fetchStudents();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _fetchGroups() async {
    final groups = await _apiService.getGroups();
    if (mounted) {
      setState(() {
        _groups = groups;
      });
    }
  }

  Future<void> _fetchStudents() async {
    setState(() => _isLoading = true);
    final response = await _apiService.getStudents(
      pageNumber: _pageNumber,
      pageSize: _pageSize,
      searchTerm: _searchQuery,
      groupId: _selectedFilterGroupId,
    );
    
    if (mounted) {
      setState(() {
        _students = List<Map<String, dynamic>>.from(response['items'] ?? []);
        _totalCount = response['totalCount'] ?? 0;
        _pageNumber = response['pageNumber'] ?? 1;
        _pageSize = response['pageSize'] ?? 10;
        _totalPages = response['totalPages'] ?? 0;
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchQuery = query;
        _pageNumber = 1; // Reset to first page on search
      });
      _fetchStudents();
    });
  }

  void _onGroupFilterChanged(int? groupId) {
    setState(() {
      _selectedFilterGroupId = groupId;
      _pageNumber = 1;
    });
    _fetchStudents();
  }

  void _changePage(int page) {
    if (page >= 1 && page <= _totalPages) {
      setState(() {
        _pageNumber = page;
      });
      _fetchStudents();
    }
  }

  void _showAddStudentDialog() async {
    final nameController = TextEditingController();
    final surnameController = TextEditingController();
    final patronymicController = TextEditingController();
    final phoneController = TextEditingController();
    
    int? selectedGroupId;
    Uint8List? faceBytes;
    String? faceName;
    bool isSaving = false;

    List<Map<String, dynamic>> dialogGroups = _groups.isEmpty ? await _apiService.getGroups() : _groups;

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return ResponsiveDialog(
            title: 'Yangi Talaba Qo\'shish',
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
                            builder: (ctx) => ResponsiveDialog(
                              title: 'Yangi guruh',
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
                              _fetchGroups();
                            }
                          }
                        },
                        icon: const Icon(Icons.group_add, color: Color(0xFF1E3A8A)),
                        tooltip: 'Yangi guruh yaratish',
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              if (isSaving) const CircularProgressIndicator()
              else ...[
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Bekor qilish')),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isEmpty || surnameController.text.isEmpty) {
                      AppToast.show(context, 'Yulduzcha bilan belgilangan maydonlarni to\'ldiring');
                      return;
                    }
                    if (selectedGroupId == null) {
                      AppToast.show(context, 'Guruhni tanlash majburiy!');
                      return;
                    }
                    if (faceBytes == null) {
                      AppToast.show(context, 'Talaba yuz rasmini yuklash majburiy!');
                      return;
                    }
                    
                    setDialogState(() => isSaving = true);
                    final String generatedUuid = const Uuid().v4();
                    final success = await _apiService.createStudent(
                      fullName: '${nameController.text} ${surnameController.text}',
                      patronymic: patronymicController.text,
                      username: generatedUuid,
                      password: generatedUuid,
                      phoneNumber: phoneController.text,
                      groupId: selectedGroupId,
                      imageBytes: faceBytes,
                      imageName: faceName,
                    );
                    if (success && mounted) {
                      Navigator.pop(context);
                      _fetchStudents();
                      AppToast.show(context, 'Talaba muvaffaqiyatli qo\'shildi');
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

  void _showStudentDetails(Map<String, dynamic> student) {
    final gId = student['groupId'];
    final gMap = _groups.where((g) => g['id'] == gId).toList();
    final groupName = gMap.isNotEmpty ? gMap.first['name'] : 'Biriktirilmagan';
    final isDisabled = student['isDisabled'] ?? false;

    showDialog(
      context: context,
      builder: (context) => ResponsiveDialog(
        title: 'Talaba ma\'lumotlari',
        content: Column(
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
      builder: (ctx) => ResponsiveDialog(
        title: 'Diqqat!',
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
            child: const Text('Ha, O\'chirish', style: TextStyle(color: Colors.white)),
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
    
    int? selectedGroupId = student['groupId'];
    Uint8List? faceBytes;
    String? faceName;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return ResponsiveDialog(
            title: 'Talaba ma\'lumotlarini tahrirlash',
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
                  items: _groups.map((g) => DropdownMenuItem<int>(value: g['id'], child: Text(g['name']))).toList(),
                  onChanged: (val) => setDialogState(() => selectedGroupId = val),
                ),
              ],
            ),
            actions: [
              if (isSaving) const CircularProgressIndicator()
              else ...[
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Bekor qilish')),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isEmpty || surnameController.text.isEmpty) {
                      AppToast.show(context, 'Majburiy maydonlarni to\'ldiring');
                      return;
                    }
                    setDialogState(() => isSaving = true);
                    final success = await _apiService.updateStudent(
                      id: student['id'],
                      fullName: '${nameController.text} ${surnameController.text}',
                      patronymic: patronymicController.text,
                      username: student['username'],
                      phoneNumber: phoneController.text,
                      groupId: selectedGroupId,
                      imageBytes: faceBytes,
                      imageName: faceName,
                    );
                    if (success && mounted) {
                      Navigator.pop(context);
                      _fetchStudents();
                      AppToast.show(context, 'O\'zgarishlar saqlandi');
                    } else {
                      setDialogState(() => isSaving = false);
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

  List<Widget> _buildPageNumberButtons() {
    List<Widget> buttons = [];
    int startPage = _pageNumber > 2 ? _pageNumber - 1 : 1;
    int endPage = _pageNumber < _totalPages - 1 ? _pageNumber + 1 : _totalPages;

    if (startPage > 1) {
      buttons.add(_buildPageButton(1));
      if (startPage > 2) {
        buttons.add(const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Text('...')));
      }
    }

    for (int i = startPage; i <= endPage; i++) {
        buttons.add(_buildPageButton(i));
    }

    if (endPage < _totalPages) {
      if (endPage < _totalPages - 1) {
        buttons.add(const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Text('...')));
      }
      buttons.add(_buildPageButton(_totalPages));
    }

    return buttons;
  }

  Widget _buildPageButton(int page) {
    final isActive = _pageNumber == page;
    return InkWell(
      onTap: () => _changePage(page),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF1E3A8A) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isActive ? const Color(0xFF1E3A8A) : Colors.grey.shade300),
        ),
        child: Text(
          '$page',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isActive ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                      'Talabalar ro\'yxati',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                    ).animate().fadeIn().slideY(begin: 0.2),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _showAddStudentDialog,
                        icon: const Icon(Icons.person_add),
                        label: const Text('Talaba qo\'shish'),
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
                          'Talabalar ro\'yxati',
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                        ).animate().fadeIn().slideY(begin: 0.2),
                        const SizedBox(height: 8),
                        Text(
                          _isLoading ? 'Yuklanmoqda...' : 'Jami: $_totalCount ta talaba',
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
              
              // Search & Filter Row
              Flex(
                direction: isMobile ? Axis.vertical : Axis.horizontal,
                children: [
                  Expanded(
                    flex: isMobile ? 0 : 2,
                    child: SizedBox(
                      width: isMobile ? double.infinity : null,
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Ism bo\'yicha qidirish...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        onChanged: _onSearchChanged,
                      ),
                    ),
                  ),
                  if (isMobile) const SizedBox(height: 12) else const SizedBox(width: 16),
                  Expanded(
                    flex: isMobile ? 0 : 1,
                    child: SizedBox(
                      width: isMobile ? double.infinity : null,
                      child: DropdownButtonFormField<int?>(
                        isExpanded: true,
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
                        onChanged: _onGroupFilterChanged,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
          
          if (_isLoading && (_students == null || _students!.isEmpty))
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_students == null || _students!.isEmpty)
            const Expanded(child: Center(child: Text('Talabalar mavjud emas.')))
          else ...[
            Expanded(
              child: ListView.builder(
                itemCount: _students!.length,
                itemBuilder: (context, index) {
                  final student = _students![index];
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
            const SizedBox(height: 16),
            // Pagination controls
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                runSpacing: 12,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Har sahifada: '),
                      DropdownButton<int>(
                        value: _pageSize,
                        items: [5, 10, 20, 50].map((int value) {
                          return DropdownMenuItem<int>(
                            value: value,
                            child: Text(value.toString()),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _pageSize = val;
                              _pageNumber = 1;
                            });
                            _fetchStudents();
                          }
                        },
                      ),
                    ],
                  ),
                  if (_totalPages > 0)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: _pageNumber > 1 ? () => _changePage(_pageNumber - 1) : null,
                          icon: const Icon(Icons.chevron_left),
                        ),
                        ..._buildPageNumberButtons(),
                        IconButton(
                          onPressed: _pageNumber < _totalPages ? () => _changePage(_pageNumber + 1) : null,
                          icon: const Icon(Icons.chevron_right),
                        ),
                      ],
                    ),
                    Text('Jami: $_totalCount ta', style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ]],
          )
        );
      },
    );
  }
}

