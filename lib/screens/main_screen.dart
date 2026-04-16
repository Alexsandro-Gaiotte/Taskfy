import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'task_list_screen.dart';
import 'calendar_screen.dart';
import 'dashboard_screen.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/task_provider.dart';
import 'login_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 1; // Default to TaskList

  @override
  void initState() {
    super.initState();
    // Load tasks whenever the MainScreen is created (e.g., after login/register)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TaskProvider>(context, listen: false).loadTasks();
    });
  }


  final List<Widget> _screens = const [
    DashboardScreen(),
    TaskListScreen(),
    CalendarScreen(),
    _SettingsTab(), // Settings/Logout Screen
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Stack(
        children: [
          _screens[_currentIndex],
          
          // Bottom Navigation overlaps the active screen
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: _buildBottomNav(),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: const Color(0xFF14131B).withValues(alpha: 0.95), // Extra dark slightly transparent
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(0, Icons.dashboard_outlined),
          _buildNavItem(1, Icons.task_alt),
          _buildNavItem(2, Icons.calendar_month),
          _buildNavItem(3, Icons.settings_outlined),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon) {
    bool isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          border: isActive
              ? const Border(bottom: BorderSide(color: AppTheme.secondaryNeon, width: 3))
              : null,
        ),
        child: Icon(
          icon,
          color: isActive ? AppTheme.textWhite : AppTheme.textBody,
          size: 28,
        ),
      ),
    );
  }
}

class _SettingsTab extends StatelessWidget {
  const _SettingsTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.settings, size: 80, color: AppTheme.textBody),
          const SizedBox(height: 24),
          const Text(
            'Configurações',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textWhite,
            ),
          ),
          const SizedBox(height: 48),
          ElevatedButton.icon(
            onPressed: () async {
              await Provider.of<AuthProvider>(context, listen: false).logout();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            icon: const Icon(Icons.logout, color: AppTheme.textWhite),
            label: const Text(
              'Sair da Conta',
              style: TextStyle(color: AppTheme.textWhite, fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent.withValues(alpha: 0.8),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
