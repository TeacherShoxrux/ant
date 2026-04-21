import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
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
      body: Stack(
        children: [
          // Background subtle animation
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: Image.network(
                'https://www.transparenttextures.com/patterns/cubes.png',
                repeat: ImageRepeat.repeat,
              ),
            ),
          ),
          
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Sticky AppBar
              _buildAppBar(),
              
              // Hero Section
              SliverToBoxAdapter(child: _buildHeroSection()),
              
              // Features Sections
              SliverToBoxAdapter(child: _buildFeaturesSection()),
              
              // Stats Section
              SliverToBoxAdapter(child: _buildStatsSection()),
              
              // Call to Action Section
              SliverToBoxAdapter(child: _buildCTASection( context)),
              
              // Footer
              SliverToBoxAdapter(child: _buildFooter()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: const Color(0xFF0F172A).withOpacity(0.8),
      elevation: 0,
      centerTitle: false,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.school_rounded, color: Color(0xFF1E3A8A), size: 24),
          ),
          const SizedBox(width: 12),
          const Text(
            "Interfeys",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 24,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: _AnimatedButton(
            onPressed: () => context.push('/login'),
            child: ElevatedButton(
              onPressed: null, // handled by _AnimatedButton
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1E3A8A),
                disabledBackgroundColor: Colors.white,
                disabledForegroundColor: const Color(0xFF1E3A8A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24),
              ),
              child: const Text("Tizimga kirish", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroSection() {
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
          // Animated Background Elements
          ...List.generate(8, (index) => Positioned(
            left: index % 2 == 0 ? null : (index * 150.0 - 500),
            right: index % 2 == 0 ? (index * 150.0 - 500) : null,
            top: index * 80.0,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Colors.blue.withOpacity(0.08), Colors.transparent],
                ),
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true))
             .moveY(begin: 0, end: 100, duration: (3000 + index * 1000).ms, curve: Curves.easeInOut)
             .blur(begin: const Offset(10, 10), end: const Offset(50, 50)),
          )),

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
                    _buildHeroButton("Boshlash", Colors.white, const Color(0xFF1E3A8A), () => context.push('/login')),
                    const SizedBox(width: 20),
                    _buildHeroButton("Platforma haqida", Colors.transparent, Colors.white, () {
                      _scrollController.animateTo(750, duration: 800.ms, curve: Curves.easeInOut);
                    }, isOutlined: true),]
                ).animate().fadeIn(delay: 800.ms).scale(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroButton(String text, Color bgColor, Color textColor, VoidCallback onPressed, {bool isOutlined = false}) {
    return _AnimatedButton(
      onPressed: onPressed,
      child: Container(
        width: 200,
        height: 56,
        decoration: isOutlined ? BoxDecoration(
          border: Border.all(color: Colors.white.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(16),
        ) : null,
        child: ElevatedButton(
          onPressed: null, // handled by _AnimatedButton
          style: ElevatedButton.styleFrom(
            backgroundColor: bgColor,
            foregroundColor: textColor,
            disabledBackgroundColor: bgColor,
            disabledForegroundColor: textColor,
            elevation: isOutlined ? 0 : 10,
            shadowColor: Colors.blue.withOpacity(0.3),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildFeaturesSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 24),
      child: Column(
        children: [
          _buildSectionHeader("Platforma Imkoniyatlari"),
          const SizedBox(height: 80),
          _buildFeatureRow(
            Icons.video_library_rounded,
            "Sifatli Video Darslar",
            "Barcha fanlar bo'yicha yuqori sifatli video darslar to'plami. Istalgan vaqtda va istalgan joyda bilim oling.",
            true,
          ),
          const SizedBox(height: 100),
          _buildFeatureRow(
            Icons.quiz_rounded,
            "Interaktiv Testlar",
            "Mavzularni o'zlashtirish darajasini tekshirish uchun maxsus ishlab chiqilgan testlar va topshiriqlar.",
            false,
          ),
          const SizedBox(height: 100),
          _buildFeatureRow(
            Icons.face_retouching_natural_rounded,
            "Face ID Xavfsizligi",
            "Tizimga kirishda eng zamonaviy yuz identifikatsiyasi texnologiyasidan foydalaniladi. Xavfsiz va tezkor.",
            true,
          ),
          const SizedBox(height: 100),
          _buildFeatureRow(
            Icons.analytics_rounded,
            "Natijalar Monitoringi",
            "O'quvchilar va o'qituvchilar uchun o'zlashtirish ko'rsatkichlarini real vaqt rejimida kuzatish imkoniyati.",
            false,
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String title, String description, bool iconLeft) {
    return _AnimatedFeatureRow(
      icon: icon,
      title: title,
      description: description,
      iconLeft: iconLeft,
      scrollController: _scrollController,
    );
  }
}

class _AnimatedFeatureRow extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool iconLeft;
  final ScrollController scrollController;

  const _AnimatedFeatureRow({
    required this.icon,
    required this.title,
    required this.description,
    required this.iconLeft,
    required this.scrollController,
  });

  @override
  State<_AnimatedFeatureRow> createState() => _AnimatedFeatureRowState();
}

class _AnimatedFeatureRowState extends State<_AnimatedFeatureRow> {
  bool _isVisible = false;
  final GlobalKey _key = GlobalKey();

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_checkVisibility);
    // Initial check
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkVisibility());
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_checkVisibility);
    super.dispose();
  }

  void _checkVisibility() {
    if (!mounted || _isVisible) return;
    
    final RenderObject? renderObject = _key.currentContext?.findRenderObject();
    if (renderObject is RenderBox) {
      final offset = renderObject.localToGlobal(Offset.zero);
      final height = MediaQuery.of(context).size.height;
      if (offset.dy < height * 0.8) {
        setState(() => _isVisible = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = [
      Expanded(
        child: Column(
          crossAxisAlignment: widget.iconLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: [
            Text(
              widget.title,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              widget.description,
              textAlign: widget.iconLeft ? TextAlign.left : TextAlign.right,
              style: const TextStyle(fontSize: 18, color: Colors.blueGrey, height: 1.6),
            ),
          ],
        ),
      ),
      const SizedBox(width: 80),
      Container(
        width: 280,
        height: 280,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.1),
              blurRadius: 30,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: Icon(widget.icon, size: 100, color: Colors.blue.shade400),
      ),
    ];

    return Container(
      key: _key,
      margin: const EdgeInsets.only(bottom: 120),
      child: Opacity(
        opacity: _isVisible ? 1 : 0,
        child: Row(
          children: widget.iconLeft ? content : content.reversed.toList(),
        ),
      )
      .animate(target: _isVisible ? 1 : 0)
      .fadeIn(duration: 600.ms)
      .slideX(begin: widget.iconLeft ? -0.2 : 0.2, end: 0, curve: Curves.easeOutCubic),
    );
  }
}

  Widget _buildSectionHeader(String title) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 16),
        Container(
          width: 80,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 100),
      color: Colors.white.withOpacity(0.02),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem("10K+", "O'quvchilar"),
          _buildStatItem("500+", "Kurslar"),
          _buildStatItem("100+", "O'qituvchilar"),
          _buildStatItem("95%", "Muvaffaqiyat"),
        ],
      ),
    );
  }

  Widget _buildStatItem(String val, String label) {
    return Column(
      children: [
        Text(val, style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.blue)),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 18, color: Colors.blueGrey)),
      ],
    );
  }

  Widget _buildCTASection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 150, horizontal: 24),
      alignment: Alignment.center,
      child: Column(
        children: [
          const Text(
            "Tayyormisiz? Hoziroq boshlang!",
            style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 48),
          _AnimatedButton(
            onPressed: () => context.push('/login'),
            child: SizedBox(
              width: 300,
              height: 70,
              child: ElevatedButton(
                onPressed: null, // handled by _AnimatedButton
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.blue,
                  disabledForegroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text("Royxatdan o'tish", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Interfeys", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              Row(
                children: [
                  _buildFooterLink("Biz haqimizda"),
                  const SizedBox(width: 30),
                  _buildFooterLink("Yordam"),
                  const SizedBox(width: 30),
                  _buildFooterLink("Maxfiylik"),
                ],
              ),
            ],
          ),
          const SizedBox(height: 40),
          Text(
            "© 2026 Interfeys Digital Learning. Barcha huquqlar himoyalangan.",
            style: TextStyle(color: Colors.white.withOpacity(0.4)),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterLink(String text) {
    return Text(
      text,
      style: const TextStyle(color: Colors.blueGrey, fontSize: 16),
    );

}

class _AnimatedButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;
  const _AnimatedButton({required this.child, required this.onPressed});

  @override
  State<_AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<_AnimatedButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: widget.child,
      ),
    );
  }
}
