import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../logic/auth/auth_cubit.dart';
import '../../logic/auth/auth_state.dart';
import '../../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final stats = await _apiService.getStats();
    if (mounted) {
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Asosiy panel',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                  ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    'Bugungi ta\'lim jarayoni bo\'yicha qisqacha ma\'lumotlar',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ).animate().fadeIn(delay: 200.ms),
                  
                  const SizedBox(height: 32),
                  
                  GridView.count(
                    crossAxisCount: width > 1200 ? 4 : (width > 800 ? 2 : 1),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 24,
                    crossAxisSpacing: 24,
                    childAspectRatio: width > 800 ? 2.5 : 2.2,
                    children: [
                      _buildStatCard('Fanlar', _stats?['totalSubjects']?.toString() ?? '0', Icons.book_outlined, Colors.blue),
                      _buildStatCard('Mavzular', _stats?['totalTopics']?.toString() ?? '0', Icons.topic_outlined, Colors.orange),
                      _buildStatCard('Testlar', _stats?['totalQuizzes']?.toString() ?? '0', Icons.quiz_outlined, Colors.purple),
                      _buildStatCard('Topshiriqlar', _stats?['totalAssignments']?.toString() ?? '0', Icons.assignment_outlined, Colors.green),
                      if (context.read<AuthCubit>().state is AuthAuthenticated && (context.read<AuthCubit>().state as AuthAuthenticated).isAdmin)
                        _buildStatCard('Talabalar', _stats?['totalStudents']?.toString() ?? '0', Icons.group_outlined, Colors.red),
                    ].animate(interval: 100.ms).fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95)),
                  ),
                  
                  const SizedBox(height: 48),
                  
                  const Text(
                    'Tezkor Harakatlar',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                  ).animate().fadeIn(delay: 400.ms),
                  
                  const SizedBox(height: 24),
                  
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _buildQuickAction(context, 'Mening fanlarim', Icons.menu_book, '/subjects'),
                      if (context.read<AuthCubit>().state is AuthAuthenticated && (context.read<AuthCubit>().state as AuthAuthenticated).isAdmin)
                        _buildQuickAction(context, 'Fan qo\'shish', Icons.add_box_outlined, '/subjects'),
                      _buildQuickAction(context, 'O\'zlashtirish', Icons.bar_chart, '/grades'),
                      _buildQuickAction(context, 'Profil', Icons.person, '/profile'),
                    ].animate(interval: 100.ms).fadeIn(delay: 500.ms).slideX(begin: -0.1),
                  )
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(BuildContext context, String title, IconData icon, String path) {
    return InkWell(
      onTap: () => context.go(path),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: const Color(0xFF1E3A8A)),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}
