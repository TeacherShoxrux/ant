import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'widgets/welcome_app_bar.dart';
import 'widgets/welcome_hero.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      // Scaffhold appBar ishlatamiz, SliverAppBar emas
      appBar: const WelcomeAppBar(),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            WelcomeHero(
              onStartPressed: () => context.push('/login'),
              onAboutPressed: () {
                _scrollController.animateTo(750, 
                  duration: const Duration(milliseconds: 800), 
                  curve: Curves.easeInOut);
              },
            ),
            const SizedBox(height: 100, child: Center(child: Text("Xush kelibsiz!", style: TextStyle(color: Colors.white, fontSize: 24)))),
            // Qolgan sectionlarni shu yerga Column ichida qo'shish mumkin
          ],
        ),
      ),
    );
  }
}
