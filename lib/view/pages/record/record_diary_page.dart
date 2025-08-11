import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

import '../../../component/appbars/custom_app_bar_title_subtitle.dart';
import '../../../component/buttons/custom_button.dart';
import '../../../component/inputs/custom_text_area.dart';
import '../../../component/inputs/selectable_emoji_selector.dart';
import '../../../component/texts/paragraph_text.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../view_model/record/record_view_model.dart';

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
      context.read<RecordViewModel>().resetEmotion();
    });
  }

  Future<void> _onSave(BuildContext context) async {
    setState(() => _isLoading = true);

    await Future.delayed(const Duration(seconds: 2)); // 저장 처리
    setState(() {
      _isLoading = false;
      _isDone = true;
    });

    await Future.delayed(const Duration(seconds: 2)); // 완료 애니메이션 표시 시간
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/home_tab_navigator', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<RecordViewModel>();
    final date = '2025년 7월 28일';

    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
              children: [
                CustomAppBarTitleSubtitle(
                  title: '감정과 소비 일지',
                  subtitle: '$date · ${viewModel.formattedTotal}원 소비',
                  onBack: () => Navigator.pop(context),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenPadding,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: AppSpacing.sectionSpacing),
                        ParagraphText(
                          text: '오늘의 기분은 어떠셨나요?',
                          fontWeight: FontWeight.bold,
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            ...['기쁨', '혼란', '슬픔', '피곤', '화남', '플렉스'].map((
                              emotion,
                            ) {
                              return SizedBox(
                                width:
                                    (MediaQuery.of(context).size.width -
                                        AppSpacing.screenPadding * 2 -
                                        24) /
                                    3,
                                child: SelectableEmojiSelector(
                                  label: emotion,
                                  emojiWidget: Lottie.asset(
                                    _lottiePathForEmotion(emotion),
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.contain,
                                  ),
                                  selected:
                                      viewModel.selectedEmotion == emotion,
                                  onTap: () {
                                    if (viewModel.selectedEmotion == emotion) {
                                      viewModel.setEmotion('');
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
                        ParagraphText(
                          text: '오늘의 소비에 대해 어떻게 생각하시나요?',
                          fontWeight: FontWeight.bold,
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
                  enabled: viewModel.selectedEmotion != '',
                  onPressed: () {
                    if (viewModel.selectedEmotion != '') {
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

  String _lottiePathForEmotion(String emotion) {
    switch (emotion) {
      case '기쁨':
        return 'assets/animations/Great.json';
      case '혼란':
        return 'assets/animations/UU.json';
      case '슬픔':
        return 'assets/animations/Great.json';
      case '피곤':
        return 'assets/animations/UU.json';
      case '화남':
        return 'assets/animations/Great.json';
      case '플렉스':
        return 'assets/animations/UU.json';
      default:
        return 'assets/lottie/default.json';
    }
  }
}
