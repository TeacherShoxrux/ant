import 'package:student_platform_frontend/widgets/app_toast.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/auth/auth_state.dart';
import 'widgets/camera_view.dart';
import 'widgets/login_header.dart';
import '../../widgets/auth/login_form.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isAdminMode = false;
  bool _isCameraReady = false;
  bool _isPasswordVisible = false;
  
  CameraController? _cameraController;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        _cameraController = CameraController(
          cameras.first,
          ResolutionPreset.medium,
          enableAudio: false,
        );
        await _cameraController!.initialize();
        if (mounted) setState(() => _isCameraReady = true);
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

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          context.go('/home');
        } else if (state is AuthError) {
          AppToast.show(context, state.message, isError: true);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Row(
          children: [
            Expanded(
              flex: 3,
              child: _LeftBrandingSection(),
            ),
            Expanded(
              flex: 2,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        LoginHeader(isAdminMode: _isAdminMode),
                        const SizedBox(height: 48),
                        if (!_isAdminMode)
                          Column(
                            children: [
                              BlocBuilder<AuthCubit, AuthState>(
                                builder: (context, state) {
                                  return CameraView(
                                    isCameraReady: _isCameraReady,
                                    controller: _cameraController,
                                    isProcessing: state is AuthLoading,
                                  );
                                },
                              ),
                              const SizedBox(height: 40),
                              SizedBox(
                                width: 280,
                                height: 56,
                                child: ElevatedButton.icon(
                                  onPressed: _isCameraReady ? () async {
                                    final img = await _cameraController?.takePicture();
                                    if (img != null) {
                                      final bytes = await img.readAsBytes();
                                      context.read<AuthCubit>().faceLogin(bytes);
                                    }
                                  } : null,
                                  icon: const Icon(Icons.face),
                                  label: const Text('Face ID orqali kirish'),
                                ),
                              ),
                            ],
                          )
                        else
                          LoginForm(
                            usernameController: _usernameController,
                            passwordController: _passwordController,
                            isPasswordVisible: _isPasswordVisible,
                            onTogglePasswordVisibility: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                            onLoginPressed: () => context.read<AuthCubit>().login(
                              _usernameController.text,
                              _passwordController.text,
                            ),
                          ),
                        const SizedBox(height: 40),
                        TextButton(
                          onPressed: () => setState(() {
                            _isAdminMode = !_isAdminMode;
                            if (!_isAdminMode) _initializeCamera();
                          }),
                          child: Text(_isAdminMode ? 'Talaba sifatida kirish (Face ID)' : 'Admin bo\'lib kirish'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeftBrandingSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF1E40AF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school, size: 100, color: Colors.white),
            SizedBox(height: 24),
            Text('INTERFEYS', style: TextStyle(fontSize: 42, color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
