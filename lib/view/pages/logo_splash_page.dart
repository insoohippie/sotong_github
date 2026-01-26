import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum LogoIntroStyle { slide, pop } // slide: 스르르, pop: 팡 하고 자리잡기

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
  Animation<Offset>? _slide; // slide 전용
  Animation<double>? _scale; // pop 전용

  late Timer _timer;

  Future<void> _goNext() async {
    final user = FirebaseAuth.instance.currentUser;

    // ✅ 로그인 유지 중이면 홈으로, 아니면 로그인으로
    final nextRoute = (user != null) ? '/home_tab_navigator' : '/login';

    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      nextRoute,
          (route) => false,
    );
  }

  @override
  void initState() {
    super.initState();

    // 공통 컨트롤러
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    // 공통: 페이드 인
    _fade = CurvedAnimation(
      parent: _ctrl,
      curve: Curves.easeInOut,
    );

    // 스타일별 트윈 셋업
    if (widget.style == LogoIntroStyle.slide) {
      // 살짝 아래에서 스르르 올라오기
      _slide = Tween<Offset>(
        begin: const Offset(0, 0.18),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    } else {
      // 살짝 작게 시작해서 팡 하고 자리 잡기
      _scale = Tween<double>(begin: 0.82, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
      );
    }

    // ✅ 지정 시간 뒤 자동 로그인 분기
    _timer = Timer(widget.delay, _goNext);
  }

  @override
  void dispose() {
    _timer.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logo = Image.asset(
      'assets/images/bot_profile.png', // 로고 파일 경로
      width: widget.size,
      height: widget.size,
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
