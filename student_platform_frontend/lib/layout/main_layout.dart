import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';
import '../logic/auth/auth_cubit.dart';
import '../logic/auth/auth_state.dart';

class MainLayout extends StatefulWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  bool _isSidebarOpen = true;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isDesktop = mediaQuery.size.width > 900;
    
    // Automatically close sidebar on smaller screens
    if (!isDesktop && _isSidebarOpen) {
      _isSidebarOpen = false;
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      drawer: !isDesktop ? _buildSidebar(context, isDrawer: true) : null,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey.shade300, height: 1.0),
        ),
        leading: isDesktop
            ? IconButton(
                icon: const Icon(Icons.menu, color: Colors.black87),
                onPressed: () => setState(() => _isSidebarOpen = !_isSidebarOpen),
              )
            : Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu, color: Colors.black87),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
        title: const Text(
          'Student Platform',
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.black87),
            onPressed: () {},
          ),
          const SizedBox(width: 16),
          BlocBuilder<AuthCubit, AuthState>(
            builder: (context, state) {
              if (state is AuthAuthenticated) {
                return Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xFF1E3A8A).withOpacity(0.1),
                      backgroundImage: state.imagePath != null 
                        ? NetworkImage('${ApiService.serverUrl}${state.imagePath}') 
                        : null,
                      child: state.imagePath == null 
                        ? Text(
                            state.fullName[0].toUpperCase(),
                            style: const TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold),
                          )
                        : null,
                    ),
                    if (isDesktop) ...[
                      const SizedBox(width: 12),
                      Text(state.fullName, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 24),
                    ]
                  ],
                );
              }
              return const SizedBox();
            },
          ),
        ],
      ),
      body: Row(
        children: [
          if (isDesktop && _isSidebarOpen)
            _buildSidebar(context, isDrawer: false),
          
          Expanded(
            child: widget.child,
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context, {required bool isDrawer}) {
    final authState = context.read<AuthCubit>().state;
    final isAdmin = authState is AuthAuthenticated && authState.isAdmin;
    final currentPath = GoRouterState.of(context).uri.toString();

    final sidebar = Container(
      width: 260,
      color: const Color(0xFF1E3A8A),
      child: Column(
        children: [
          if (isDrawer)
            Container(
              height: 100,
              padding: const EdgeInsets.only(top: 40, left: 16),
              alignment: Alignment.centerLeft,
              child: const Text('HEMIS Menu', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            ),
          const SizedBox(height: 16),
          
          _buildNavItem(context, 'Asosiy sahifa', Icons.dashboard_outlined, '/home', currentPath, isDrawer: isDrawer),
          _buildNavItem(context, 'Mening fanlarim', Icons.menu_book_outlined, '/subjects', currentPath, isDrawer: isDrawer),
          _buildNavItem(context, 'O\'zlashtirish', Icons.bar_chart_outlined, '/grades', currentPath, isDrawer: isDrawer),
          
          if (isAdmin)
            _buildNavItem(context, 'Talabalar (Admin)', Icons.people_outline, '/students', currentPath, isDrawer: isDrawer),
            
          _buildNavItem(context, 'Profil', Icons.person_outline, '/profile', currentPath, isDrawer: isDrawer),
          
          const Spacer(),
          const Divider(color: Colors.white24),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.white70),
            title: const Text('Tizimdan chiqish', style: TextStyle(color: Colors.white70)),
            onTap: () {
              if (isDrawer) Navigator.pop(context);
              context.read<AuthCubit>().logout();
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );

    return isDrawer ? Drawer(child: sidebar) : sidebar;
  }

  Widget _buildNavItem(BuildContext context, String title, IconData icon, String path, String currentPath, {required bool isDrawer}) {
    final isSelected = currentPath.startsWith(path);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            // Close drawer if on mobile
            if (isDrawer) {
              Navigator.pop(context);
            }
            context.go(path);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: isSelected ? Colors.white.withOpacity(0.15) : Colors.transparent,
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 22),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
