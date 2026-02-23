import 'package:flutter/material.dart';

import '../../../component/appbars/back_only_app_bar.dart';

class TimeSummaryPage extends StatelessWidget {
  const TimeSummaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final iconColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: BackOnlyAppBar(title: '시간으로 변환', iconColor: iconColor),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '절약/초과 금액을 시간으로 환산',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Pretendard Variable',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '소비 패턴을 시간 단위로 분석해보세요',
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
                        Icons.access_time,
                        size: 80,
                        color: Colors.orange.withOpacity(0.3),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        '시간 기반 분석',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Pretendard Variable',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '절약한 금액을 시간으로 환산하여\n동기부여를 제공합니다.',
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
