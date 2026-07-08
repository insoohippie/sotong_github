import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../repository/auth_repository.dart';
import '../../../view_model/home/home_view_model.dart';
import 'auth/login_page.dart';

enum LogoIntroStyle { slide, pop }

class LogoSplashPage extends StatefulWidget {
  const LogoSplashPage({
    super.key,
    this.style = LogoIntroStyle.pop,
    this.delay = const Duration(seconds: 2),
    this.size = 180,
  });

  final LogoIntroStyle style;
  final Duration delay;
  final double size;

  @override
  State<LogoSplashPage> createState() => _LogoSplashPageState();
}

class _LogoSplashPageState extends State<LogoSplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  Animation<Offset>? _slide;
  Animation<double>? _scale;

  Timer? _timer;
  bool _navigated = false;

  Future<void> _goNext() async {
    if (_navigated) return;
    _navigated = true;

    final authRepo = context.read<AuthRepository>();
    final next = authRepo.nextRouteBySession();

    if (!mounted) return;

    if (next == '/home_tab_navigator') {
      await context.read<HomeViewModel>().refresh();
      if (!mounted) return;
    }

    if (next == '/login') {
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          settings: const RouteSettings(name: '/login'),
          pageBuilder: (_, __, ___) => const EmailLoginPage(),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
            (_) => false,
      );
      return;
    }

    Navigator.of(context).pushNamedAndRemoveUntil(
      next,
          (_) => false,
    );
  }

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);

    if (widget.style == LogoIntroStyle.slide) {
      _slide = Tween<Offset>(
        begin: const Offset(0, 0.18),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    } else {
      _scale = Tween<double>(begin: 0.82, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
      );
    }

    _timer = Timer(widget.delay, _goNext);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logo = Image.asset(
      'assets/images/sotong_logo.png',
      width: widget.size,
      height: widget.size,
      fit: BoxFit.contain,
    );

    final animated = FadeTransition(
      opacity: _fade,
      child: switch (widget.style) {
        LogoIntroStyle.slide => SlideTransition(position: _slide!, child: logo),
        LogoIntroStyle.pop => ScaleTransition(scale: _scale!, child: logo),
      },
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(child: animated),
    );
  }
}