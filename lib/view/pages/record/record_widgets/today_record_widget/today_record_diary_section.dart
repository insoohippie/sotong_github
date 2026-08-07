import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../../../../view_model/record/today_spending_view_model.dart';

class TodayRecordDiarySection extends StatelessWidget {
  final TodaySpendingViewModel vm;
  final bool hasUnsavedChanges;
  final Future<void> Function() onSave;
  final VoidCallback onEdit;
  final bool readOnly;

  const TodayRecordDiarySection({
    super.key,
    required this.vm,
    required this.hasUnsavedChanges,
    required this.onSave,
    required this.onEdit,
    this.readOnly = false,
  });

  static const Map<String, String> _emotionLottieMap = {
    '평온': 'assets/animations/emotion_calm.json',
    '좋음': 'assets/animations/emotion_good.json',
    '슬픔': 'assets/animations/emotion_sad.json',
    '스트레스': 'assets/animations/emotion_stress.json',
    '동기부여': 'assets/animations/emotion_motivation.json',
    '아무 감정 없음': 'assets/animations/emotion_none.json',
  };

  static String _emotionToLottie(String emotion) {
    return _emotionLottieMap[emotion] ??
        'assets/animations/emotion_calm.json';
  }

  @override
  Widget build(BuildContext context) {
    final emotion = vm.emotion.trim();
    final lottiePath = _emotionToLottie(emotion);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final subtleSurface = isDark
        ? theme.colorScheme.surfaceContainerHighest
        : const Color(0xFFF2F2F2);
    final editButtonBackground = isDark
        ? theme.colorScheme.surfaceContainerHighest
        : const Color(0xFFE0E0E0);

    return Stack(
      children: [
        Positioned.fill(
          bottom: _saveButtonReservedHeight(context),
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '오늘의 감정',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const Spacer(),
                      if (!readOnly)
                        GestureDetector(
                          onTap: onEdit,
                          child: Container(
                            width: 23,
                            height: 23,
                            decoration: BoxDecoration(
                              color: editButtonBackground,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Icon(
                                Icons.edit,
                                color: theme.colorScheme.onSurfaceVariant,
                                size: 10,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Column(
                      children: [
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: Lottie.asset(
                            lottiePath,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              debugPrint('Lottie load failed: $lottiePath');
                              debugPrint('emotion: $emotion');
                              debugPrint('error: $error');
                              return const Icon(
                                Icons.sentiment_neutral,
                                size: 60,
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          emotion.isEmpty ? '😊 감정 미기록' : '😊 $emotion',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '소비일지',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: subtleSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? theme.dividerColor
                            : Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      vm.comment.isEmpty ? '오늘의 소비일지가 없어요.' : vm.comment,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: readOnly ? const SizedBox.shrink() : _buildSaveButton(context),
          ),
        ),
      ],
    );
  }

  double _saveButtonReservedHeight(BuildContext context) {
    if (readOnly) return MediaQuery.paddingOf(context).bottom + 12;
    return MediaQuery.paddingOf(context).bottom +
        (hasUnsavedChanges ? 96.0 : 72.0);
  }

  Widget _buildSaveButton(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = hasUnsavedChanges
        ? const Color(0xFF4A90E2)
        : isDark
        ? theme.colorScheme.surface
        : const Color(0xFFE5E7EB);
    final textColor = hasUnsavedChanges
        ? Colors.white
        : isDark
        ? theme.colorScheme.onSurfaceVariant
        : Colors.grey[500]!;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: hasUnsavedChanges ? () => onSave() : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: backgroundColor,
              disabledBackgroundColor: backgroundColor,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              '저장하기',
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
