import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import 'package:student_platform_frontend/widgets/app_toast.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final ApiService _apiService = ApiService();
  final _subjectNameController = TextEditingController();
  final _subjectDescController = TextEditingController();

  void _addSubject() async {
    final success = await _apiService.createSubject(
      _subjectNameController.text,
      _subjectDescController.text,
    );
    if (success) {
      _subjectNameController.clear();
      _subjectDescController.clear();
      AppToast.show(context, 'Fan muvaffaqiyatli qo\'shildi.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Panel')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Yangi Fan Qo\'shish', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: _subjectNameController,
              decoration: const InputDecoration(labelText: 'Fan nomi', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _subjectDescController,
              decoration: const InputDecoration(labelText: 'Tavsif', border: OutlineInputBorder()),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _addSubject, child: const Text('Saqlash')),
            const SizedBox(height: 40),
            const Divider(),
            const SizedBox(height: 20),
            const Text('Talabalar Topshiriqlari (Navbatda kutilayotgan)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text('Bu bo\'limda talabalar yuklagan PDF/Rasm fayllarini ko\'rib baholash mumkin.'),
            // Here would be a list of submissions fetched from API
            const Card(
              child: ListTile(
                title: Text('Talaba: Alijon Valiyev'),
                subtitle: Text('Fan: Matematika - Lesson 1 Assignment'),
                trailing: Text('Baholash', style: TextStyle(color: Colors.blue)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
