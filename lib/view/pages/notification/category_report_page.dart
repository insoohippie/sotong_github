import 'package:flutter/material.dart';

import '../../../component/appbars/back_only_app_bar.dart';

class CategoryReportPage extends StatelessWidget {
  const CategoryReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final iconColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: BackOnlyAppBar(title: '소비 리포트', iconColor: iconColor),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '주간/월간 소비 패턴 분석',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Pretendard Variable',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '카테고리별 소비 현황을 확인해보세요',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                  fontFamily: 'Pretendard Variable',
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.analytics,
                        size: 80,
                        color: Colors.green.withOpacity(0.3),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        '소비 분석 리포트',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Pretendard Variable',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '카테고리별 소비 패턴을 분석하여\n더 나은 재정 계획을 세울 수 있습니다.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodyMedium?.color?.withOpacity(
                            0.7,
                          ),
                          fontFamily: 'Pretendard Variable',
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
