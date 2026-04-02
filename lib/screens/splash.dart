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

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  final authService = AuthService();
  late final AnimationController _controller;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoTilt;
  late final Animation<double> _ringScale;
  late final Animation<double> _ringOpacity;
  late final Animation<double> _burstScale;
  late final Animation<double> _burstOpacity;
  late final Animation<Offset> _creditSlide;
  late final Animation<double> _creditOpacity;

  Widget? _nextPage;
  bool _navigationStarted = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3900),
    );

    _logoScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.32, end: 1.18).chain(
          CurveTween(curve: Curves.easeOutBack),
        ),
        weight: 55,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.18, end: 1.0).chain(
          CurveTween(curve: Curves.easeInOut),
        ),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.72).chain(
          CurveTween(curve: Curves.easeInCubic),
        ),
        weight: 25,
      ),
    ]).animate(_controller);

    _logoOpacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0).chain(
          CurveTween(curve: Curves.easeOut),
        ),
        weight: 18,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 58,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0).chain(
          CurveTween(curve: Curves.easeIn),
        ),
        weight: 24,
      ),
    ]).animate(_controller);

    _logoTilt = Tween<double>(begin: -0.06, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.05, 0.42, curve: Curves.easeOutBack),
      ),
    );

    _ringScale = Tween<double>(begin: 0.55, end: 1.55).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.16, 0.72, curve: Curves.easeOutCubic),
      ),
    );

    _ringOpacity = Tween<double>(begin: 0.55, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.20, 0.76, curve: Curves.easeOut),
      ),
    );

    _burstScale = Tween<double>(begin: 0.8, end: 1.85).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.28, 0.82, curve: Curves.easeOutExpo),
      ),
    );

    _burstOpacity = Tween<double>(begin: 0.28, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.28, 0.84, curve: Curves.easeOut),
      ),
    );

    _creditSlide = Tween<Offset>(
      begin: const Offset(1.15, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.77, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _creditOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.77, 0.96, curve: Curves.easeOut),
      ),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigateIfReady();
      }
    });

    _controller.forward();
    _decideNavigation();
  }

  Future<void> _decideNavigation() async {
    final session = await SessionService.getSession();

    if (!mounted) return;

    if (session == null) {
      _nextPage = const LoginScreen();
      _navigateIfReady();
      return;
    }

    final role = session['role']!;
    final phone = session['phone']!;

    if (role == 'student') {
      final hasInterests =
          await authService.hasSelectedInterests(phone);

      _nextPage =
        hasInterests
            ? const HomeShell()
            : InterestSelectionScreen(phone: phone);
    } else {
      _nextPage = const HomeShell();
    }

    _navigateIfReady();
  }

  void _navigateIfReady() {
    if (!mounted || _navigationStarted || !_controller.isCompleted) {
      return;
    }

    final page = _nextPage;
    if (page == null) {
      return;
    }

    _navigationStarted = true;
    _go(page);
  }

  void _go(Widget page) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFF6EC),
                  Color(0xFFFFE3CB),
                  Color(0xFFF3E8FF),
                ],
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned(
                  top: -110,
                  right: -70,
                  child: Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.10),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -140,
                  left: -90,
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF60A5FA).withValues(alpha: 0.12),
                    ),
                  ),
                ),
                Center(
                  child: SizedBox(
                    width: 300,
                    height: 300,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Transform.scale(
                          scale: _burstScale.value,
                          child: Container(
                            width: 210,
                            height: 210,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  const Color(0xFF8B5CF6)
                                      .withValues(alpha: _burstOpacity.value),
                                  const Color(0xFF60A5FA).withValues(alpha: 0),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Transform.scale(
                          scale: _ringScale.value,
                          child: Container(
                            width: 165,
                            height: 165,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF8B5CF6)
                                    .withValues(alpha: _ringOpacity.value),
                                width: 3,
                              ),
                            ),
                          ),
                        ),
                        Transform.scale(
                          scale: _ringScale.value * 0.88,
                          child: Container(
                            width: 190,
                            height: 190,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF60A5FA).withValues(
                                  alpha: _ringOpacity.value * 0.75,
                                ),
                                width: 2.4,
                              ),
                            ),
                          ),
                        ),
                        Opacity(
                          opacity: _logoOpacity.value,
                          child: Transform.rotate(
                            angle: _logoTilt.value,
                            child: Transform.scale(
                              scale: _logoScale.value,
                              child: Container(
                                width: 156,
                                height: 156,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(40),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF8B5CF6)
                                          .withValues(alpha: 0.18),
                                      blurRadius: 36,
                                      spreadRadius: 8,
                                    ),
                                  ],
                                ),
                                child: Image.asset(
                                  'assets/images/unisync_logo.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        ),
                        FadeTransition(
                          opacity: _creditOpacity,
                          child: SlideTransition(
                            position: _creditSlide,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.82),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: const Color(0xFF8B5CF6)
                                      .withValues(alpha: 0.18),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF312E81)
                                        .withValues(alpha: 0.08),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: RichText(
                                textAlign: TextAlign.center,
                                text: const TextSpan(
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: 'Created by ',
                                      style: TextStyle(
                                        color: Color(0xFF1F2937),
                                      ),
                                    ),
                                    TextSpan(
                                      text: '~ Bhoomi R. J',
                                      style: TextStyle(
                                        color: Color(0xFF7C3AED),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
