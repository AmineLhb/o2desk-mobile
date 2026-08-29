import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import 'dashboard/dashboard_screen.dart';
import 'dashboard/manager_dashboard_screen.dart';
import 'faqs/faq_screen.dart';
import 'manager/manager_agents_screen.dart';
import 'manager/manager_auto_assignment_screen.dart';
import 'manager/manager_projects_screen.dart';
import 'profile/profile_screen.dart';
import 'tickets/create_ticket_screen.dart';
import 'tickets/ticket_list_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final isManager = auth.userRole == 'manager';

    final logoAsset = isDark ? 'assets/images/logo-inverse.png' : 'assets/images/logo_o2desk.png';

    final List<Widget> screens = isManager
        ? const [
            ManagerDashboardScreen(),
            TicketListScreen(),
            ManagerAgentsScreen(),
            ManagerProjectsScreen(),
            ManagerAutoAssignmentScreen(),
            ProfileScreen(),
          ]
        : const [
            DashboardScreen(),
            TicketListScreen(),
            FaqScreen(),
            ProfileScreen(),
          ];

    final List<BottomNavigationBarItem> items = isManager
        ? const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined, size: 20),
              activeIcon: Icon(Icons.dashboard, size: 20, color: AppTheme.primary),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.confirmation_number_outlined, size: 20),
              activeIcon: Icon(Icons.confirmation_number, size: 20, color: AppTheme.primary),
              label: 'Tickets',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline, size: 20),
              activeIcon: Icon(Icons.people, size: 20, color: AppTheme.primary),
              label: 'Agents',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.folder_outlined, size: 20),
              activeIcon: Icon(Icons.folder, size: 20, color: AppTheme.primary),
              label: 'Projets',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.flash_on_outlined, size: 20),
              activeIcon: Icon(Icons.flash_on, size: 20, color: AppTheme.primary),
              label: 'Auto Assign',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline, size: 20),
              activeIcon: Icon(Icons.person, size: 20, color: AppTheme.primary),
              label: 'Profil',
            ),
          ]
        : const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined, size: 22),
              activeIcon: Icon(Icons.dashboard, size: 22, color: AppTheme.primary),
              label: 'Tableau de bord',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.confirmation_number_outlined, size: 22),
              activeIcon: Icon(Icons.confirmation_number, size: 22, color: AppTheme.primary),
              label: 'Tickets',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.help_outline, size: 22),
              activeIcon: Icon(Icons.help, size: 22, color: AppTheme.primary),
              label: 'FAQ',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline, size: 22),
              activeIcon: Icon(Icons.person, size: 22, color: AppTheme.primary),
              label: 'Profil',
            ),
          ];

    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          logoAsset,
          height: 30,
          fit: BoxFit.contain,
        ),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            tooltip: 'Changer de thème',
            onPressed: () => themeProvider.toggleTheme(),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex < screens.length ? _currentIndex : 0,
        children: screens,
      ),
      floatingActionButton: auth.userRole == 'user'
          ? FloatingActionButton(
              backgroundColor: AppTheme.primary,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CreateTicketScreen()),
                );
              },
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: isDark ? AppTheme.darkBorder : const Color(0xFFEBEBEB))),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex < items.length ? _currentIndex : 0,
          type: BottomNavigationBarType.fixed,
          backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
          selectedItemColor: AppTheme.primary,
          unselectedItemColor: isDark ? Colors.white60 : Colors.black54,
          selectedFontSize: isManager ? 10 : 11,
          unselectedFontSize: isManager ? 9 : 10,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: items,
        ),
      ),
    );
  }
}