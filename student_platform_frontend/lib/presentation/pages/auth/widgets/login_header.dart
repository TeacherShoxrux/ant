import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LoginHeader extends StatelessWidget {
  final bool isAdminMode;

  const LoginHeader({super.key, required this.isAdminMode});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          isAdminMode ? 'Admin Portal' : 'Talaba Kirish',
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E3A8A),
          ),
        ).animate().fadeIn(),
        const SizedBox(height: 8),
        Text(
          isAdminMode
              ? 'Boshqaruv paneliga kirish uchun ma\'lumotlarni kiriting'
              : 'Yuzingizni kamera markaziga qarating',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[600]),
        ),
      ],
    );
  }
}
