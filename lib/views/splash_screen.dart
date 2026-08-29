import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import 'app_shell.dart';
import 'auth/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _logoCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _blobCtrl;

  late Animation<double> _scale;
  late Animation<double> _fade;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();

    _logoCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _scale = Tween<double>(begin: 0.65, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOutCubic),
    );
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: const Interval(0.0, 0.5, curve: Curves.easeIn)),
    );

    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.15, end: 0.55).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _blobCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();

    _logoCtrl.forward();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final start = DateTime.now();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await auth.checkAuthStatus();
    final elapsed = DateTime.now().difference(start).inMilliseconds;
    if (elapsed < 1600) await Future.delayed(Duration(milliseconds: 1600 - elapsed));
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => auth.isAuthenticated ? const AppShell() : const LoginScreen(),
        transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 450),
      ),
    );
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _pulseCtrl.dispose();
    _blobCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final size = MediaQuery.of(context).size;
    final logoPath = isDark ? 'assets/images/logo-inverse.png' : 'assets/images/logo_o2desk.png';

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1117) : Colors.white,
      body: Stack(
        children: [
          // Background gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark
                      ? [const Color(0xFF0D1117), const Color(0xFF0A1628)]
                      : [Colors.white, const Color(0xFFEFF6FF)],
                ),
              ),
            ),
          ),

          // Top-right ambient blob
          AnimatedBuilder(
            animation: _blobCtrl,
            builder: (_, __) => Positioned(
              top: -size.width * 0.25,
              right: -size.width * 0.20,
              child: Transform.rotate(
                angle: _blobCtrl.value * 2 * math.pi * 0.7,
                child: Container(
                  width: size.width * 0.65,
                  height: size.width * 0.65,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppTheme.primary.withOpacity(isDark ? 0.20 : 0.12),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Bottom-left ambient blob
          AnimatedBuilder(
            animation: _blobCtrl,
            builder: (_, __) => Positioned(
              bottom: -size.width * 0.22,
              left: -size.width * 0.22,
              child: Transform.rotate(
                angle: -_blobCtrl.value * 2 * math.pi * 0.5,
                child: Container(
                  width: size.width * 0.58,
                  height: size.width * 0.58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF2A9DF4).withOpacity(isDark ? 0.15 : 0.10),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Logo centered
          Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([_logoCtrl, _pulseCtrl]),
              builder: (_, __) => FadeTransition(
                opacity: _fade,
                child: ScaleTransition(
                  scale: _scale,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Glow ring
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withOpacity(_pulse.value),
                              blurRadius: 50,
                              spreadRadius: 6,
                            ),
                          ],
                        ),
                      ),
                      // Logo — smaller and clean
                      Image.asset(
                        logoPath,
                        height: 64,
                        errorBuilder: (_, __, ___) => Icon(Icons.headset_mic, size: 64, color: AppTheme.primary),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Bottom loading
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _fade,
              builder: (_, __) => Opacity(
                opacity: _fade.value,
                child: Column(
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.8,
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary.withOpacity(0.65)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Chargement en cours...',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 0.3,
                        color: isDark ? Colors.white30 : Colors.black30,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}