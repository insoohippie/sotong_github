import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LogoSplashPage extends StatefulWidget {
  const LogoSplashPage({super.key});

  @override
  State<LogoSplashPage> createState() => _LogoSplashPageState();
}

class _LogoSplashPageState extends State<LogoSplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);

    // 3초 후 로그인으로 이동
    Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/login',
            (route) => false,
      );
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: Lottie.asset(
            'assets/animations/UU.json',
            width: 180,
            height: 180,
            repeat: true,
          ),
        ),
      ),
    );
  }
}
