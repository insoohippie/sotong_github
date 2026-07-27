import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:sotong/component/wrappers/keyboard_dismiss_scope.dart';
import 'package:sotong/component/buttons/custom_button.dart';
import 'package:sotong/component/inputs/custom_text_area.dart';
import 'package:sotong/component/inputs/selectable_emoji_selector.dart';
import '../../../../../view_model/record/today_spending_view_model.dart';

const _diarySheetDismissDelay = Duration(milliseconds: 320);

Future<void> _waitForDiarySheetDismissed() async {
  await WidgetsBinding.instance.endOfFrame;
  await Future<void>.delayed(_diarySheetDismissDelay);
}

Future<({String emotion, String comment})?>
showTodayRecordEditDiaryBottomSheet({
  required BuildContext context,
  required TodaySpendingViewModel vm,
}) async {
  const emotionOptions = ['평온', '좋음', '슬픔', '스트레스', '동기부여', '아무 감정 없음'];

  bool isClosing = false;

  String? selectedEmotion = emotionOptions.contains(vm.emotion.trim())
      ? vm.emotion.trim()
      : null;

  final diaryController = TextEditingController(text: vm.comment);

  bool canSubmit() {
    return (selectedEmotion ?? '').trim().isNotEmpty;
  }

  final result =
      await showModalBottomSheet<({String emotion, String comment})>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (BuildContext sheetContext) {
          return StatefulBuilder(
            builder: (context, setModalState) {
              void safeSetModalState(VoidCallback fn) {
                if (isClosing) return;
                if (!context.mounted) return;
                setModalState(fn);
              }

              final screenWidth = MediaQuery.of(context).size.width;
              final itemWidth = (screenWidth - 48 - 24) / 3;
              final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
              final keyboardInset = MediaQuery.of(context).viewInsets.bottom;
              final theme = Theme.of(context);

              return PopScope(
                canPop: true,
                onPopInvokedWithResult: (_, __) {
                  isClosing = true;
                  FocusManager.instance.primaryFocus?.unfocus();
                },
                child: Transform.translate(
                  offset: Offset(0, keyboardInset),
                  child: KeyboardDismissScope(
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                      ),
                      child: SafeArea(
                        top: false,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.fromLTRB(
                                24,
                                20,
                                24,
                                isKeyboardVisible ? keyboardInset : 0,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Center(
                                    child: Text(
                                      '감정 및 소비일지 수정',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    '오늘의 기분은 어떠셨나요?',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 12,
                                    children: emotionOptions.map((emotion) {
                                      final selected =
                                          (selectedEmotion ?? '') == emotion;

                                      return SizedBox(
                                        width: itemWidth,
                                        child: SelectableEmojiSelector(
                                          label: emotion,
                                          emojiWidget: Builder(
                                            builder: (context) {
                                              final path = _lottiePathForEmotion(
                                                emotion,
                                              );
                                              return Lottie.asset(
                                                path,
                                                key: ValueKey(path),
                                                width: 40,
                                                height: 40,
                                                fit: BoxFit.contain,
                                                errorBuilder:
                                                    (context, error, stackTrace) {
                                                  debugPrint(
                                                    'Lottie load failed: $path — $error',
                                                  );
                                                  return const Icon(
                                                    Icons.sentiment_neutral,
                                                    size: 40,
                                                  );
                                                },
                                              );
                                            },
                                          ),
                                          selected: selected,
                                          onTap: () {
                                            safeSetModalState(() {
                                              if (selected) {
                                                selectedEmotion = null;
                                              } else {
                                                selectedEmotion = emotion;
                                              }
                                            });
                                          },
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    '오늘의 소비에 대해 어떻게 생각하시나요?',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  CustomTextArea(
                                    controller: diaryController,
                                    hintText:
                                        '오늘 소비한 것들에 대한 생각이나 느낌을 자유롭게 적어보세요...',
                                  ),
                                  if (isKeyboardVisible) const SizedBox(height: 8),
                                ],
                              ),
                            ),
                            if (!isKeyboardVisible) ...[
                              const SizedBox(height: 24),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                                child: CustomButton(
                                  text: '확인',
                                  height: 56,
                                  enabled: canSubmit(),
                                  onPressed: () async {
                                    if (!canSubmit()) return;

                                    isClosing = true;
                                    FocusManager.instance.primaryFocus?.unfocus();

                                    if (context.mounted) {
                                      Navigator.of(context).pop((
                                        emotion: (selectedEmotion ?? '').trim(),
                                        comment: diaryController.text.trim(),
                                      ));
                                    }
                                  },
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ).whenComplete(() {
        isClosing = true;
        FocusManager.instance.primaryFocus?.unfocus();
      });

  await _waitForDiarySheetDismissed();
  diaryController.dispose();

  return result;
}

String _lottiePathForEmotion(String emotion) {
  switch (emotion) {
    case '평온':
      return 'assets/animations/emotion_calm.json';
    case '좋음':
      return 'assets/animations/emotion_good.json';
    case '슬픔':
      return 'assets/animations/emotion_sad.json';
    case '스트레스':
      return 'assets/animations/emotion_stress.json';
    case '동기부여':
      return 'assets/animations/emotion_motivation.json';
    case '아무 감정 없음':
      return 'assets/animations/emotion_none.json';
    default:
      return 'assets/animations/emotion_calm.json';
  }
}
