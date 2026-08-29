import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../app_shell.dart';

class OtpScreen extends StatefulWidget {
  final String email;
  final String? password;
  final String? role;
  final String otpType; // 'email_otp' or 'google2fa'

  const OtpScreen({
    super.key,
    required this.email,
    this.password,
    this.role,
    this.otpType = 'email_otp',
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpController = TextEditingController();
  bool _isVerifying = false;
  bool _isResending = false;
  int _resendCountdown = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    setState(() {
      _resendCountdown = 60;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() {
          _resendCountdown--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _verifyOtp() async {
    final code = _otpController.text.trim();
    if (code.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez saisir un code OTP à 6 chiffres.')),
      );
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);

      Map<String, dynamic> res;
      if (widget.password != null && widget.password!.isNotEmpty) {
        res = await ApiService.post('/login', {
          'email': widget.email,
          'password': widget.password,
          'otp_code': code,
          'otp': code,
          if (widget.role != null) 'role': widget.role,
        });
      } else {
        res = await ApiService.post('/verify-otp', {
          'email': widget.email,
          'otp': code,
          'otp_code': code,
        });
      }

      if (res['success'] == true && res['token'] != null) {
        final token = res['token'] as String;
        final role = (res['role'] ?? widget.role ?? 'user').toString();
        final userData = res['user'] as Map<String, dynamic>? ?? {};

        await auth.saveAuthData(token, role, userData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Connexion réussie !')),
          );
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const AppShell()),
            (route) => false,
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['message'] ?? 'Code OTP invalide ou expiré.')),
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
          _isVerifying = false;
        });
      }
    }
  }

  Future<void> _resendOtp() async {
    if (_resendCountdown > 0 || _isResending) return;

    setState(() {
      _isResending = true;
    });

    try {
      final res = await ApiService.post('/send-otp', {'email': widget.email});
      if (res['success'] == true) {
        _startResendTimer();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['message'] ?? 'Un nouveau code OTP a été envoyé à votre email.')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['message'] ?? 'Erreur lors de l\'envoi du code OTP.')),
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
          _isResending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Validation 2FA / OTP'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              CircleAvatar(
                radius: 36,
                backgroundColor: AppTheme.primary.withOpacity(0.15),
                child: const Icon(Icons.lock_clock_outlined, size: 36, color: AppTheme.primary),
              ),
              const SizedBox(height: 20),
              Text(
                'Vérification 2FA',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? AppTheme.darkTextLight : AppTheme.lightTextDark),
              ),
              const SizedBox(height: 8),
              Text(
                widget.otpType == 'google2fa'
                    ? 'Entrez le code à 6 chiffres généré par votre application Google Authenticator.'
                    : 'Un code de sécurité à 6 chiffres a été envoyé à l\'adresse :\n${widget.email}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppTheme.secondary, height: 1.4),
              ),
              const SizedBox(height: 30),

              // OTP Code Input Field
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  letterSpacing: 8,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppTheme.darkTextLight : AppTheme.lightTextDark,
                ),
                decoration: const InputDecoration(
                  hintText: '000000',
                  counterText: '',
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 24),

              // Validate Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                  onPressed: _isVerifying ? null : _verifyOtp,
                  child: _isVerifying
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Valider le code', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 20),

              // Resend OTP Button (For Email OTP)
              if (widget.otpType != 'google2fa') ...[
                TextButton.icon(
                  onPressed: _resendCountdown == 0 && !_isResending ? _resendOtp : null,
                  icon: _isResending
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.refresh, size: 18),
                  label: Text(
                    _resendCountdown > 0
                        ? 'Renvoyer le code ($_resendCountdown s)'
                        : 'Renvoyer le code OTP par email',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _resendCountdown == 0 ? AppTheme.primary : AppTheme.secondary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}