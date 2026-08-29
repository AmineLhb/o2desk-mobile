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
  late AnimationController _logoController;
  late AnimationController _pulseController;
  late AnimationController _blobController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Main logo entrance
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: const Interval(0.0, 0.6, curve: Curves.easeIn)),
    );

    // Glow pulse loop
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Blob rotation loop
    _blobController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _logoController.forward();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final startTime = DateTime.now();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.checkAuthStatus();
    final elapsed = DateTime.now().difference(startTime).inMilliseconds;
    if (elapsed < 1800) {
      await Future.delayed(Duration(milliseconds: 1800 - elapsed));
    }
    if (!mounted) return;
    final target = authProvider.isAuthenticated ? const AppShell() : const LoginScreen();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => target,
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _pulseController.dispose();
    _blobController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final size = MediaQuery.of(context).size;
    final logoPath = isDark ? 'assets/images/logo-inverse.png' : 'assets/images/logo_o2desk.png';

    final Color blobA = isDark
        ? const Color(0xFF0D47A1).withOpacity(0.28)
        : const Color(0xFF42A5F5).withOpacity(0.18);
    final Color blobB = isDark
        ? const Color(0xFF1565C0).withOpacity(0.20)
        : const Color(0xFF1E88E5).withOpacity(0.12);

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : Colors.white,
      body: Stack(
        children: [
          // Background gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [const Color(0xFF0D1117), const Color(0xFF0A1628)]
                      : [Colors.white, const Color(0xFFEFF6FF)],
                ),
              ),
            ),
          ),

          // Animated ambient blob — top right
          AnimatedBuilder(
            animation: _blobController,
            builder: (_, __) {
              return Positioned(
                top: -size.height * 0.12,
                right: -size.width * 0.18,
                child: Transform.rotate(
                  angle: _blobController.value * 2 * math.pi,
                  child: Container(
                    width: size.width * 0.72,
                    height: size.width * 0.72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [blobA, Colors.transparent],
                        stops: const [0.0, 1.0],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // Ambient blob — bottom left
          AnimatedBuilder(
            animation: _blobController,
            builder: (_, __) {
              return Positioned(
                bottom: -size.height * 0.10,
                left: -size.width * 0.20,
                child: Transform.rotate(
                  angle: -_blobController.value * 2 * math.pi,
                  child: Container(
                    width: size.width * 0.65,
                    height: size.width * 0.65,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [blobB, Colors.transparent],
                        stops: const [0.0, 1.0],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // Centered logo with glow + entrance animation
          Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([_logoController, _pulseController]),
              builder: (_, __) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Glow ring
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withOpacity(_pulseAnimation.value),
                                blurRadius: 60,
                                spreadRadius: 8,
                              ),
                            ],
                          ),
                        ),
                        // Logo
                        Image.asset(
                          logoPath,
                          height: 90,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.headset_mic,
                            size: 90,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Bottom loading indicator
          Positioned(
            bottom: 44,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (_, __) => Opacity(
                opacity: _fadeAnimation.value,
                child: Column(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.primary.withOpacity(0.7),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Chargement en cours...',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 0.4,
                        color: isDark ? Colors.white38 : Colors.black38,
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