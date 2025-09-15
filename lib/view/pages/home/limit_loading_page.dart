import 'package:flutter/material.dart';
import '../../../component/theme/app_colors.dart';
import '../../../component/theme/app_spacing.dart';

class LimitLoadingPage extends StatefulWidget {
  const LimitLoadingPage({super.key});

  @override
  State<LimitLoadingPage> createState() => _LimitLoadingPageState();
}

class _LimitLoadingPageState extends State<LimitLoadingPage> {
  @override
  void initState() {
    super.initState();
    // 3초 후 완료 페이지로 이동
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/limit_complete');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 로딩 스피너
              Container(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),

              const SizedBox(height: AppSpacing.sectionSpacing),

              // 로딩 텍스트
              const Text(
                '기다리시면 넘어갑니다',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}