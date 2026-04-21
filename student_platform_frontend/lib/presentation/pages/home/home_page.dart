import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/auth/auth_state.dart';
import '../../cubits/dashboard/dashboard_cubit.dart';
import '../../cubits/dashboard/dashboard_state.dart';
import 'widgets/stat_card.dart';
import 'widgets/quick_action_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    context.read<DashboardCubit>().fetchStats();
  }

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: BlocBuilder<DashboardCubit, DashboardState>(
        builder: (context, state) {
          if (state is DashboardLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is DashboardError) {
            return Center(child: Text(state.message));
          }
          if (state is DashboardLoaded) {
            final stats = state.stats;
            return SingleChildScrollView(
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
                      StatCard(title: 'Fanlar', value: stats['totalSubjects']?.toString() ?? '0', icon: Icons.book_outlined, color: Colors.blue),
                      StatCard(title: 'Mavzular', value: stats['totalTopics']?.toString() ?? '0', icon: Icons.topic_outlined, color: Colors.orange),
                      StatCard(title: 'Testlar', value: stats['totalQuizzes']?.toString() ?? '0', icon: Icons.quiz_outlined, color: Colors.purple),
                      StatCard(title: 'Topshiriqlar', value: stats['totalAssignments']?.toString() ?? '0', icon: Icons.assignment_outlined, color: Colors.green),
                      if (context.read<AuthCubit>().state is AuthAuthenticated && (context.read<AuthCubit>().state as AuthAuthenticated).authResponse.role == 'Admin')
                        StatCard(title: 'Talabalar', value: stats['totalStudents']?.toString() ?? '0', icon: Icons.group_outlined, color: Colors.red),
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
                      QuickActionCard(title: 'Mening fanlarim', icon: Icons.menu_book, onTap: () => context.go('/subjects')),
                      if (context.read<AuthCubit>().state is AuthAuthenticated && (context.read<AuthCubit>().state as AuthAuthenticated).authResponse.role == 'Admin')
                        QuickActionCard(title: 'Fan qo\'shish', icon: Icons.add_box_outlined, onTap: () => context.go('/subjects')),
                      QuickActionCard(title: 'O\'zlashtirish', icon: Icons.bar_chart, onTap: () => context.go('/grades')),
                      QuickActionCard(title: 'Profil', icon: Icons.person, onTap: () => context.go('/profile')),
                    ].animate(interval: 100.ms).fadeIn(delay: 500.ms).slideX(begin: -0.1),
                  )
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
