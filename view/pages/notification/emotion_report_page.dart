import 'package:flutter/material.dart';

class EmotionReportPage extends StatelessWidget {
  const EmotionReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final iconColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: iconColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '감정 리포트',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.textTheme.bodyLarge?.color,
            fontFamily: 'Pretendard Variable',
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '감정 태그 기반 소비 분석',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Pretendard Variable',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '감정과 소비 패턴의 연결을 확인해보세요',
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
                        Icons.psychology,
                        size: 80,
                        color: Colors.purple.withOpacity(0.3),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        '감정 기반 분석',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Pretendard Variable',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '감정 태그를 기반으로 소비 패턴을\n분석하여 인사이트를 제공합니다.',
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
