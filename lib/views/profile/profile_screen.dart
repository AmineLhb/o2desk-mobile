import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _enable2FA = false;
  bool _isLoading2FA = false;

  @override
  void initState() {
    super.initState();
    _fetchUser2FAStatus();
  }

  Future<void> _fetchUser2FAStatus() async {
    try {
      final res = await ApiService.get('/me');
      if (res['success'] == true && res['user'] != null) {
        final otpStatus = res['user']['otp_status'];
        setState(() {
          _enable2FA = (otpStatus == 1 || otpStatus == true);
        });
      }
    } catch (_) {}
  }

  Future<void> _toggle2FA(bool value) async {
    setState(() {
      _isLoading2FA = true;
    });

    try {
      final res = await ApiService.post('/profile/2fa', {'enable': value});
      if (res['success'] == true) {
        setState(() {
          _enable2FA = value;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['message'] ?? (value ? 'Double authentification (Email 2FA) activée.' : 'Double authentification désactivée.'))),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['message'] ?? 'Erreur lors du changement de 2FA.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading2FA = false;
        });
      }
    }
  }

  void _handleLogout(AuthProvider auth) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2.5),
              ),
              SizedBox(width: 18),
              Text(
                'Déconnexion en cours...',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );

    await Future.delayed(const Duration(milliseconds: 600));
    await auth.logout();

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 400),
        ),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final user = auth.user;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // User Avatar & Name Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: AppTheme.primary.withOpacity(0.15),
                        child: Text(
                          user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'U',
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.primary),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(user?.name ?? 'Utilisateur', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? AppTheme.darkTextLight : AppTheme.lightTextDark)),
                      const SizedBox(height: 4),
                      Text(user?.email ?? '', style: const TextStyle(fontSize: 13, color: AppTheme.secondary)),
                      const SizedBox(height: 8),
                      Chip(
                        label: Text(auth.userRole.toUpperCase()),
                        backgroundColor: AppTheme.primary.withOpacity(0.1),
                        labelStyle: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Settings List
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.person_outline, color: AppTheme.primary),
                      title: Text('Modifier le profil', style: TextStyle(color: isDark ? AppTheme.darkTextLight : AppTheme.lightTextDark)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EditProfileScreen()));
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.lock_outline, color: AppTheme.primary),
                      title: Text('Changer le mot de passe', style: TextStyle(color: isDark ? AppTheme.darkTextLight : AppTheme.lightTextDark)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ChangePasswordScreen()));
                      },
                    ),
                    const Divider(height: 1),

                    // Active 2FA (Email OTP) Switch Item Linked to Backend API
                    SwitchListTile(
                      secondary: const Icon(Icons.security_outlined, color: AppTheme.primary),
                      title: Text('Double authentification (Email 2FA)', style: TextStyle(color: isDark ? AppTheme.darkTextLight : AppTheme.lightTextDark)),
                      subtitle: Text(
                        _enable2FA ? 'Double authentification Email (OTP) activée.' : 'Sécuriser votre compte avec un code Email à la connexion.',
                        style: const TextStyle(fontSize: 12, color: AppTheme.secondary),
                      ),
                      value: _enable2FA,
                      activeColor: AppTheme.primary,
                      onChanged: _isLoading2FA ? null : (val) => _toggle2FA(val),
                    ),
                    const Divider(height: 1),

                    // App Theme Mode Selector
                    ListTile(
                      leading: const Icon(Icons.palette_outlined, color: AppTheme.primary),
                      title: Text('Mode Apparence', style: TextStyle(color: isDark ? AppTheme.darkTextLight : AppTheme.lightTextDark)),
                      trailing: DropdownButton<ThemeMode>(
                        value: themeProvider.themeMode,
                        underline: const SizedBox.shrink(),
                        onChanged: (mode) {
                          if (mode != null) {
                            themeProvider.setThemeMode(mode);
                          }
                        },
                        items: const [
                          DropdownMenuItem(value: ThemeMode.system, child: Text('Système')),
                          DropdownMenuItem(value: ThemeMode.light, child: Text('Clair')),
                          DropdownMenuItem(value: ThemeMode.dark, child: Text('Sombre')),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Logout Button (Smooth Animated Non-blocking Logout)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
                  icon: const Icon(Icons.logout),
                  label: const Text('Déconnexion'),
                  onPressed: () => _handleLogout(auth),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}