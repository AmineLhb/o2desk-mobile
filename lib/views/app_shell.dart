import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/notification_provider.dart';
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
  void initState() {
    super.initState();
    // Start polling for notifications
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationProvider>(context, listen: false).startPolling();
    });
  }

  @override
  void dispose() {
    Provider.of<NotificationProvider>(context, listen: false).stopPolling();
    super.dispose();
  }

  void _openNotificationsPanel() {
    final notifProvider = Provider.of<NotificationProvider>(context, listen: false);
    notifProvider.markAllRead();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _NotificationsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final notifProvider = Provider.of<NotificationProvider>(context);
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
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined, size: 20), activeIcon: Icon(Icons.dashboard, size: 20, color: AppTheme.primary), label: 'Dashboard'),
            BottomNavigationBarItem(icon: Icon(Icons.confirmation_number_outlined, size: 20), activeIcon: Icon(Icons.confirmation_number, size: 20, color: AppTheme.primary), label: 'Tickets'),
            BottomNavigationBarItem(icon: Icon(Icons.people_outline, size: 20), activeIcon: Icon(Icons.people, size: 20, color: AppTheme.primary), label: 'Agents'),
            BottomNavigationBarItem(icon: Icon(Icons.folder_outlined, size: 20), activeIcon: Icon(Icons.folder, size: 20, color: AppTheme.primary), label: 'Projets'),
            BottomNavigationBarItem(icon: Icon(Icons.flash_on_outlined, size: 20), activeIcon: Icon(Icons.flash_on, size: 20, color: AppTheme.primary), label: 'Auto Assign'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline, size: 20), activeIcon: Icon(Icons.person, size: 20, color: AppTheme.primary), label: 'Profil'),
          ]
        : const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined, size: 22), activeIcon: Icon(Icons.dashboard, size: 22, color: AppTheme.primary), label: 'Tableau de bord'),
            BottomNavigationBarItem(icon: Icon(Icons.confirmation_number_outlined, size: 22), activeIcon: Icon(Icons.confirmation_number, size: 22, color: AppTheme.primary), label: 'Tickets'),
            BottomNavigationBarItem(icon: Icon(Icons.help_outline, size: 22), activeIcon: Icon(Icons.help, size: 22, color: AppTheme.primary), label: 'FAQ'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline, size: 22), activeIcon: Icon(Icons.person, size: 22, color: AppTheme.primary), label: 'Profil'),
          ];

    return Scaffold(
      appBar: AppBar(
        title: Image.asset(logoAsset, height: 30, fit: BoxFit.contain),
        actions: [
          // Notification Bell with Badge
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                tooltip: 'Notifications',
                onPressed: _openNotificationsPanel,
              ),
              if (notifProvider.unreadCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: AppTheme.danger,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        notifProvider.unreadCount > 9 ? '9+' : '${notifProvider.unreadCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // Dark/Light Mode Toggle
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
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreateTicketScreen()));
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
          onTap: (index) => setState(() => _currentIndex = index),
          items: items,
        ),
      ),
    );
  }
}

class _NotificationsSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final notifProvider = Provider.of<NotificationProvider>(context);
    final notifications = notifProvider.notifications;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (ctx, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.notifications, color: AppTheme.primary, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      'Notifications',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppTheme.darkTextLight : AppTheme.lightTextDark,
                      ),
                    ),
                    const Spacer(),
                    if (notifications.isNotEmpty)
                      TextButton(
                        onPressed: () => notifProvider.markAllRead(),
                        child: const Text('Tout lire', style: TextStyle(fontSize: 12, color: AppTheme.primary)),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Notifications List
              Expanded(
                child: notifications.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.notifications_none, size: 48, color: isDark ? Colors.white24 : Colors.black12),
                            const SizedBox(height: 12),
                            Text(
                              'Aucune notification',
                              style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        itemCount: notifications.length,
                        separatorBuilder: (_, __) => Divider(height: 1, color: isDark ? Colors.white12 : Colors.black.withOpacity(0.06)),
                        itemBuilder: (_, i) {
                          final n = notifications[i];
                          return Container(
                            color: n.isRead
                                ? Colors.transparent
                                : (isDark ? AppTheme.primary.withOpacity(0.07) : AppTheme.primary.withOpacity(0.04)),
                            child: ListTile(
                              leading: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withOpacity(0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.notifications, color: AppTheme.primary, size: 18),
                              ),
                              title: Text(
                                n.title,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold,
                                  color: isDark ? AppTheme.darkTextLight : AppTheme.lightTextDark,
                                ),
                              ),
                              subtitle: n.body.isNotEmpty
                                  ? Text(n.body, style: const TextStyle(fontSize: 11, color: AppTheme.secondary), maxLines: 2, overflow: TextOverflow.ellipsis)
                                  : null,
                              trailing: Text(
                                _formatDate(n.createdAt),
                                style: const TextStyle(fontSize: 10, color: AppTheme.secondary),
                              ),
                              isThreeLine: n.body.isNotEmpty,
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}j';
    return DateFormat('d MMM', 'fr').format(dt);
  }
}