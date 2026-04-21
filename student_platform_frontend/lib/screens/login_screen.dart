import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:camera/camera.dart';
import '../logic/auth/auth_cubit.dart';
import '../logic/auth/auth_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isAdminMode = false;
  bool _isCameraReady = false;
  bool _isProcessingFace = false;
  bool _isPasswordVisible = false;
  
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _cameraController = CameraController(
          _cameras!.first,
          ResolutionPreset.medium,
          enableAudio: false,
        );
        await _cameraController!.initialize();
        if (mounted) {
          setState(() {
            _isCameraReady = true;
          });
        }
      }
    } catch (e) {
      debugPrint("Camera error: $e");
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _faceLogin() async {
    if (!_isCameraReady || _cameraController == null) return;

    setState(() => _isProcessingFace = true);
    
    try {
      final image = await _cameraController!.takePicture();
      final bytes = await image.readAsBytes();
      
      final success = await context.read<AuthCubit>().faceLogin(bytes, image.name);
      
      if (success && mounted) {
        context.go('/home');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Yuz aniqlanmadi yoki ruxsat berilmagan'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Xatolik: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessingFace = false);
    }
  }

  Future<void> _adminLogin() async {
    final success = await context.read<AuthCubit>().login(
      _usernameController.text.trim(),
      _passwordController.text.trim(),
    );
    
    if (success && mounted) {
      context.go('/home');
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login yoki parol noto\'g\'ri'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          // Left Side: Branding / Background
          Expanded(
            flex: 3,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1E3A8A), Color(0xFF1E40AF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.1,
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 10),
                        itemBuilder: (context, index) => const Icon(Icons.school, color: Colors.white),
                      ),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.school, size: 100, color: Colors.white)
                            .animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
                        const SizedBox(height: 24),
                        const Text(
                          'INTERFEYS',
                          style: TextStyle(fontSize: 42, color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2),
                        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
                        const Text(
                          'Masofaviy ta\'lim platformasi',
                          style: TextStyle(fontSize: 18, color: Colors.white70),
                        ).animate().fadeIn(delay: 500.ms),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Right Side: Login Form
          Expanded(
            flex: 2,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        _isAdminMode ? 'Admin Portal' : 'Talaba Kirish',
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                      ).animate().fadeIn(),
                      const SizedBox(height: 8),
                      Text(
                        _isAdminMode 
                          ? 'Boshqaruv paneliga kirish uchun ma\'lumotlarni kiriting' 
                          : 'Yuzingizni kamera markaziga qarating',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 48),

                      if (!_isAdminMode) ...[
                        // Face ID Camera Section
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 320,
                              height: 320,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.grey[200],
                                border: Border.all(color: const Color(0xFF1E3A8A), width: 4),
                              ),
                              child: ClipOval(
                                child: _isCameraReady && _cameraController != null
                                    ? CameraPreview(_cameraController!)
                                    : const Center(child: CircularProgressIndicator()),
                              ),
                            ),
                            // Scanning Animation / Guide
                            if (_isCameraReady)
                              Container(
                                width: 330,
                                height: 330,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _isProcessingFace ? Colors.cyan : const Color(0xFF1E3A8A).withOpacity(0.3),
                                    width: 2,
                                  ),
                                ),
                              ).animate(onPlay: (controller) => controller.repeat())
                               .shimmer(duration: 2.seconds, color: Colors.blue.withOpacity(0.4)),
                          ],
                        ),
                        const SizedBox(height: 40),
                        SizedBox(
                          width: 280,
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: (_isCameraReady && !_isProcessingFace) ? _faceLogin : null,
                            icon: const Icon(Icons.face),
                            label: _isProcessingFace 
                                ? const Text('Tekshirilmoqda...') 
                                : const Text('Face ID orqali kirish'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E3A8A),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: const Color(0xFF1E3A8A).withOpacity(0.6),
                              disabledForegroundColor: Colors.white70,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                            ),
                          ),
                        ),
                      ] else ...[
                        // Admin Text Login Section
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 400),
                          child: Column(
                            children: [
                              TextField(
                                controller: _usernameController,
                                decoration: InputDecoration(
                                  labelText: 'Login',
                                  prefixIcon: const Icon(Icons.person),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                              const SizedBox(height: 20),
                              TextField(
                                controller: _passwordController,
                                decoration: InputDecoration(
                                  labelText: 'Parol',
                                  prefixIcon: const Icon(Icons.lock),
                                  suffixIcon: IconButton(
                                    icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                                    onPressed: () {
                                      setState(() {
                                        _isPasswordVisible = !_isPasswordVisible;
                                      });
                                    },
                                  ),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                obscureText: !_isPasswordVisible,
                              ),
                              const SizedBox(height: 40),
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: _adminLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1E3A8A),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    elevation: 4,
                                    shadowColor: const Color(0xFF1E3A8A).withOpacity(0.4),
                                  ),
                                  child: const Text('Admin bo\'lib kirish', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 40),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isAdminMode = !_isAdminMode;
                            if (!_isAdminMode) _initializeCamera();
                          });
                        },
                        child: Text(
                          _isAdminMode ? 'Talaba sifatida kirish (Face ID)' : 'Admin bo\'lib kirish',
                          style: const TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
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
