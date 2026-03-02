import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../../../view_model/home/home_view_model.dart';

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

  Timer? _timer;
  bool _navigated = false;

  /// ✅ 핵심: auth 복원 완료 후 분기 + (로그인 상태면) 홈 refresh
  Future<void> _goNext() async {
    if (_navigated) return;
    _navigated = true;

    try {
      // 1) FirebaseAuth 세션 복원 완료를 "확정"으로 기다림
      // - 앱 재실행 직후 currentUser가 null이었다가 잠시 뒤 채워지는 문제 해결
      final user = await FirebaseAuth.instance.authStateChanges().first;

      if (!mounted) return;

      // 2) 로그인 상태면 홈 데이터 강제 리로드(로그인 버튼 루트와 동일 동작)
      if (user != null) {
        await context.read<HomeViewModel>().refresh();
        if (!mounted) return;

        Navigator.of(context).pushNamedAndRemoveUntil(
          '/home_tab_navigator',
              (route) => false,
        );
      } else {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
              (route) => false,
        );
      }
    } catch (_) {
      // 혹시 authStateChanges가 예외 나는 경우(드물지만) 안전하게 로그인으로 보냄
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/login',
            (route) => false,
      );
    }
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
      _slide = Tween<Offset>(
        begin: const Offset(0, 0.18),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    } else {
      _scale = Tween<double>(begin: 0.82, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
      );
    }

    // ✅ 지정 시간 뒤 이동 (delay는 "연출용"이고, 로그인 판단은 auth 확정 후)
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
      'assets/images/bot_profile.png',
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