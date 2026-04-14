import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'logic/auth/auth_cubit.dart';
import 'logic/auth/auth_state.dart';
import 'screens/login_screen.dart';
import 'layout/main_layout.dart';
import 'screens/home_screen.dart';
import 'screens/dashboard_views/subjects_view.dart';
import 'screens/dashboard_views/grades_view.dart';
import 'screens/dashboard_views/students_view.dart';
import 'screens/dashboard_views/profile_view.dart';

void main() {
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(create: (_) => AuthCubit()),
      ],
      child: const StudentPlatformApp(),
    ),
  );
}

class StudentPlatformApp extends StatefulWidget {
  const StudentPlatformApp({super.key});

  @override
  State<StudentPlatformApp> createState() => _StudentPlatformAppState();
}

class _StudentPlatformAppState extends State<StudentPlatformApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = _createRouter(context.read<AuthCubit>());
  }

  GoRouter _createRouter(AuthCubit authCubit) {
    return GoRouter(
      initialLocation: '/home',
      refreshListenable: GoRouterRefreshStream(authCubit.stream),
      redirect: (context, state) {
        final authState = authCubit.state;
        final isLoggingIn = state.uri.toString() == '/login';

        if (authState is AuthInitial || authState is AuthLoading) {
          // You might prefer to show a splash screen here, but we pass through for now
          // to let GoRouter handle it or fall back to login
        } else if (authState is AuthUnauthenticated) {
          if (!isLoggingIn) return '/login';
        } else if (authState is AuthAuthenticated) {
          if (isLoggingIn) return '/home';
        }
        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        ShellRoute(
          builder: (context, state, child) {
            return MainLayout(child: child);
          },
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeScreen(),
            ),
            GoRoute(
              path: '/subjects',
              builder: (context, state) => const SubjectsScreen(),
            ),
            GoRoute(
              path: '/grades',
              builder: (context, state) => const GradesScreen(),
            ),
            GoRoute(
              path: '/students',
              builder: (context, state) => const StudentsScreen(),
            ),
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'HEMIS Platform (Student)',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E3A8A), // Navy blue tailored for HEMIS
          brightness: Brightness.light,
          primary: const Color(0xFF1E3A8A),
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E3A8A),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
        ),
      ),
      routerConfig: _router,
    );
  }
}

// Utility class to convert Cubit stream to Listenable for GoRouter
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }

  late final dynamic _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
