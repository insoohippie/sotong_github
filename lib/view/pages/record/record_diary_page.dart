import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

import '../../../component/appbars/back_only_app_bar.dart';
import '../../../component/buttons/custom_button.dart';
import '../../../component/inputs/custom_text_area.dart';
import '../../../component/inputs/selectable_emoji_selector.dart';
import '../../../component/theme/app_spacing.dart';
import '../../../view_model/record/record_spending_view_model.dart';

class RecordDiaryPage extends StatefulWidget {
  const RecordDiaryPage({super.key});

  @override
  State<RecordDiaryPage> createState() => _RecordDiaryPageState();
}

class _RecordDiaryPageState extends State<RecordDiaryPage> {
  bool _isLoading = false;
  bool _isDone = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecordSpendingViewModel>().resetEmotion();
    });
  }

  Future<void> _onSave(BuildContext context) async {
    final vm = context.read<RecordSpendingViewModel>();
    final args = ModalRoute.of(context)?.settings.arguments;
    final selectedDate = (args is DateTime) ? args : DateTime.now();

    setState(() => _isLoading = true);

    try {
      await vm.saveAllForDate(selectedDate);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _isDone = true;
      });

      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/home_tab_navigator',
              (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('저장 중 오류가 발생했어요: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<RecordSpendingViewModel>();

    return Stack(
      children: [
        Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: BackOnlyAppBar(
            title: '${viewModel.formattedTotal}원 소비',
            centerTitle: true,
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenPadding,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: AppSpacing.sectionSpacing),
                        Text(
                          '오늘의 기분은 어떠셨나요?',
                          style: TextStyle(
                            fontFamily: 'Pretendard Variable',
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            ...[
                              '평온',
                              '좋음',
                              '슬픔',
                              '스트레스',
                              '동기부여',
                              '아무 감정 없음',
                            ].map((emotion) {
                              final selected =
                                  (viewModel.selectedEmotion ?? '') == emotion;

                              return SizedBox(
                                width:
                                (MediaQuery.of(context).size.width -
                                    AppSpacing.screenPadding * 2 -
                                    24) /
                                    3,
                                child: SelectableEmojiSelector(
                                  label: emotion,
                                  emojiWidget: Builder(
                                    builder: (context) {
                                      final path = _lottiePathForEmotion(
                                        emotion,
                                      );
                                      try {
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
                                      } catch (e) {
                                        debugPrint(
                                          'Lottie exception: $path — $e',
                                        );
                                        return const Icon(
                                          Icons.sentiment_neutral,
                                          size: 40,
                                        );
                                      }
                                    },
                                  ),
                                  selected: selected,
                                  onTap: () {
                                    if (selected) {
                                      viewModel.resetEmotion();
                                    } else {
                                      viewModel.setEmotion(emotion);
                                    }
                                  },
                                ),
                              );
                            }),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sectionSpacing),
                        Text(
                          '오늘의 소비에 대해 어떻게 생각하시나요?',
                          style: TextStyle(
                            fontFamily: 'Pretendard Variable',
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        CustomTextArea(
                          controller: viewModel.commentController,
                          hintText: '오늘 소비한 것들에 대한 생각이나 느낌을 자유롭게 적어보세요...',
                        ),
                        const SizedBox(height: AppSpacing.bottomSpacing),
                      ],
                    ),
                  ),
                ),
                CustomButton(
                  text: '저장하기',
                  enabled: (viewModel.selectedEmotion ?? '').isNotEmpty,
                  onPressed: () {
                    if ((viewModel.selectedEmotion ?? '').isNotEmpty) {
                      _onSave(context);
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.bottomSpacing),
              ],
            ),
          ),
        ),

        if (_isLoading || _isDone)
          Container(
            color: Colors.white.withOpacity(0.9),
            child: Center(
              child: Lottie.asset(
                _isLoading
                    ? 'assets/animations/Loading.json'
                    : 'assets/animations/Done2.json',
                width: _isLoading ? 250 : 120,
                height: _isLoading ? 250 : 120,
                repeat: _isLoading,
              ),
            ),
          ),
      ],
    );
  }

  /// 감정별 Lottie JSON — 영문 파일명 사용 시 에셋 로드 안정 (한글 파일명 이슈 회피)
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
}
