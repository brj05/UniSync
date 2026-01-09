import 'package:flutter/material.dart';
import '../services/session_service.dart';
import '../services/auth_service.dart';
import 'login.dart';
import 'home_shell.dart';
import 'interest.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final authService = AuthService();

  @override
  void initState() {
    super.initState();
    _decideNavigation();
  }

  Future<void> _decideNavigation() async {
    await Future.delayed(const Duration(seconds: 2));

    final session = await SessionService.getSession();

    if (!mounted) return;

    if (session == null) {
      _go(const LoginScreen());
      return;
    }

    final role = session['role']!;
    final phone = session['phone']!;

    if (role == 'student') {
      final hasInterests =
          await authService.hasSelectedInterests(phone);

      _go(
        hasInterests
            ? const HomeShell()
            : InterestSelectionScreen(phone: phone),
      );
    } else {
      _go(const HomeShell());
    }
  }

  void _go(Widget page) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6EC),
      body: Center(
        child: Image.asset(
          'assets/images/unisync_logo.png',
          height: 140,
        ),
      ),
    );
  }
}
