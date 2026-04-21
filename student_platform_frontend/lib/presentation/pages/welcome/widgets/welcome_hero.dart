import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class WelcomeHero extends StatelessWidget {
  final VoidCallback onStartPressed;
  final VoidCallback onAboutPressed;

  const WelcomeHero({
    super.key,
    required this.onStartPressed,
    required this.onAboutPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 700,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Kelajak Ta'limi Bugun Boshlanadi",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.3),
                const SizedBox(height: 24),
                const Text(
                  "Interfeys — zamonaviy, interaktiv va masofaviy ta'lim platformasi.\nBilim olishni yanada qulay va samarali qiling.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.blueGrey,
                    height: 1.5,
                  ),
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3),
                const SizedBox(height: 48),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildHeroButton("Boshlash", Colors.white, const Color(0xFF1E3A8A), onStartPressed),
                    const SizedBox(width: 20),
                    _buildHeroButton("Platforma haqida", Colors.transparent, Colors.white, onAboutPressed, isOutlined: true),
                  ],
                ).animate().fadeIn(delay: 800.ms).scale(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroButton(String text, Color bgColor, Color textColor, VoidCallback onPressed, {bool isOutlined = false}) {
    return SizedBox(
      width: 200,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isOutlined ? Colors.transparent : bgColor,
          foregroundColor: textColor,
          side: isOutlined ? const BorderSide(color: Colors.white) : null,
          elevation: isOutlined ? 0 : 10,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
