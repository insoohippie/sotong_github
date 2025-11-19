import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../component/theme/app_border_radius.dart';
import '../../../model/plan/plan_edit_result.dart';
import '../../../view_model/plan/chat_plan_viewmodel.dart';
import '../../../view_model/setting/setting_view_model.dart';
import '../plan/plan_edit_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '설정',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black,
            fontFamily: 'Pretendard Variable',
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Consumer<SettingViewModel>(
            builder: (context, settingsVM, _) {
              return Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 18),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppBorderRadius.card,
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.dark_mode, color: Colors.black),
                            const SizedBox(width: 12),
                            const Text(
                              '다크모드',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Pretendard Variable',
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                        Switch(
                          value: settingsVM.isDarkMode,
                          onChanged: (value) {
                            settingsVM.toggleDarkMode(value);
                          },
                          activeColor: const Color(0xFF2563EB),
                          activeTrackColor: const Color(
                            0xFF2563EB,
                          ).withOpacity(0.4),
                          inactiveThumbColor: Colors.grey.shade400,
                          inactiveTrackColor: Colors.grey.shade300,
                        ),
                      ],
                    ),
                  ),
                  // 2. 플랜 수정하기
                  Container(
                    margin: const EdgeInsets.only(bottom: 18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppBorderRadius.card,
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: AppBorderRadius.card,
                        onTap: () async {
                          final chatVm = context.read<ChatPlanViewModel>();
                          final navigator = Navigator.of(context);

                          final result = await navigator.push<PlanEditResult>(
                            MaterialPageRoute(
                              builder: (_) => PlanEditPage(
                                initialPlan: chatVm.totalPlan,
                                initialRefData: chatVm.refData,
                                requireApplyDate: true,
                              ),
                            ),
                          );

                          if (!navigator.mounted || result == null) {
                            return;
                          }

                          chatVm.applyPlanEditResult(result);
                          final ok = await chatVm.savePlan();
                          if (!navigator.mounted) return;

                          final rootContext =
                              Navigator.of(context, rootNavigator: true).context;
                          ScaffoldMessenger.of(rootContext).showSnackBar(
                            SnackBar(
                              content: Text(
                                ok
                                    ? '플랜이 저장되었습니다.'
                                    : '플랜 저장에 실패했습니다. 잠시 후 다시 시도해주세요.',
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 18,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.edit, color: Colors.black),
                                  const SizedBox(width: 12),
                                  const Text(
                                    '플랜 수정하기',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Pretendard Variable',
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                              const Icon(
                                Icons.chevron_right,
                                color: Colors.black,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // 4. 자주묻는질문
                  Container(
                    margin: const EdgeInsets.only(bottom: 18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppBorderRadius.card,
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: AppBorderRadius.card,
                        onTap: () {
                          Navigator.pushNamed(context, '/faq');
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 18,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.help_outline,
                                    color: Colors.black,
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    '자주묻는질문 FAQ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Pretendard Variable',
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                              const Icon(
                                Icons.chevron_right,
                                color: Colors.black,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // 5. 앱 현재 버전
                  Container(
                    margin: const EdgeInsets.only(bottom: 0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppBorderRadius.card,
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: AppBorderRadius.card,
                        onTap: () async {
                          // 최신 버전 정보 다이얼로그 (임시)
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text(
                                '최신 버전',
                                style: TextStyle(
                                  fontFamily: 'Pretendard Variable',
                                ),
                              ),
                              content: const Text(
                                '최신 버전: 1.0.0',
                                style: TextStyle(
                                  fontFamily: 'Pretendard Variable',
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text(
                                    '확인',
                                    style: TextStyle(
                                      fontFamily: 'Pretendard Variable',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 18,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.info_outline,
                                    color: Colors.black,
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    '앱 현재 버전 1.0.0',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Pretendard Variable',
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                              const Icon(
                                Icons.chevron_right,
                                color: Colors.black,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
