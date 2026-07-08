import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sotong_local/view/pages/setting/setting_widgets/settings_dialogs.dart';

import '../../../component/appbars/back_only_app_bar.dart';
import '../../../component/buttons/custom_button.dart';
import '../../../component/texts/header_text.dart';
import '../../../component/texts/paragraph_text.dart';
import '../../../component/theme/app_border_radius.dart';
import '../../../component/theme/app_colors.dart';
import '../../../model/plan/plan_edit_result.dart';
import '../../../repository/auth_repository.dart';
import '../../../view_model/plan/chat_plan_viewmodel.dart';
import '../../../view_model/setting/setting_view_model.dart';
import '../notification/notification_setting.dart';
import '../plan/plan_edit_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingViewModel>(
      builder: (context, settingsVM, _) {
        final isDark = settingsVM.isDarkMode;

        return Scaffold(
          backgroundColor: isDark ? AppColors.darkBackground : Colors.white,
          appBar: BackOnlyAppBar(
            backgroundColor: isDark ? AppColors.darkBackground : Colors.white,
            iconColor: isDark ? AppColors.darkText : Colors.black,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ProfileSection(isDark: isDark),
                    const SizedBox(height: 16),

                    _sectionHeader('알림 설정', isDark: isDark),
                    _settingsRow(
                      context,
                      '알림 수신 설정',
                      isDark: isDark,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationSettingPage(),
                        ),
                      ),
                    ),

                    _sectionDivider(isDark: isDark),

                    _sectionHeader('플랜 설정', isDark: isDark),
                    _settingsRow(
                      context,
                      '현재 플랜 수정',
                      isDark: isDark,
                      onTap: () async {
                        final chatVm = context.read<ChatPlanViewModel>();
                        final navigator = Navigator.of(context);

                        final result = await navigator.push<PlanEditResult>(
                          MaterialPageRoute(
                            builder: (_) => PlanEditPage(
                              useLocalDraft: false,
                            ),
                          ),
                        );

                        if (!navigator.mounted || result == null) return;

                        chatVm.applyPlanEditResult(result);
                        final ok = await chatVm.savePlan();

                        if (!navigator.mounted) return;

                        final rootContext = Navigator.of(
                          context,
                          rootNavigator: true,
                        ).context;

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
                    ),
                    _settingsRow(
                      context,
                      '지난 플랜 돌아보기',
                      isDark: isDark,
                      onTap: () {
                        showSettingsComingSoonDialog(
                          context,
                          title: '준비 중인 기능',
                          message: '지난 플랜 돌아보기 기능은\n추후 업데이트 예정입니다.',
                          isDark: isDark,
                        );
                      },
                    ),

                    _sectionDivider(isDark: isDark),

                    _sectionHeader('기타', isDark: isDark),
                    _settingsRow(
                      context,
                      '다크모드',
                      isDark: isDark,
                      trailing: Switch(
                        value: settingsVM.isDarkMode,
                        onChanged: (value) {
                          HapticFeedback.selectionClick();
                          settingsVM.toggleDarkMode(value);
                        },
                        activeColor: Colors.white,
                        activeTrackColor: Colors.white.withOpacity(0.5),
                        inactiveThumbColor: Colors.grey.shade400,
                        inactiveTrackColor: Colors.grey.shade300,
                        trackOutlineColor: WidgetStateProperty.all(
                          Colors.transparent,
                        ),
                      ),
                    ),
                    _settingsRow(
                      context,
                      '자주 묻는 질문 FAQ',
                      isDark: isDark,
                      onTap: () => Navigator.pushNamed(context, '/faq'),
                    ),
                    _settingsRow(
                      context,
                      '버전관리',
                      isDark: isDark,
                      onTap: () => Navigator.pushNamed(context, '/version'),
                    ),

                    _sectionDivider(isDark: isDark),

                    _settingsRow(
                      context,
                      '플랜 업로드',
                      isDark: isDark,
                      onTap: () async {
                        final vm = context.read<SettingViewModel>();

                        if (!vm.isOnline) {
                          await showSettingsOfflineUploadDialog(
                            context,
                            isDark: isDark,
                          );
                          return;
                        }

                        final confirmed = await showSettingsUploadConfirmDialog(
                          context,
                          isDark: isDark,
                        );

                        if (!confirmed || !context.mounted) return;

                        try {
                          await vm.uploadAllData();

                          if (!context.mounted) return;

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('플랜과 데이터가 업로드되었습니다.'),
                            ),
                          );
                        } catch (e) {
                          if (!context.mounted) return;

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(e.toString()),
                            ),
                          );
                        }
                      },
                    ),

                    _settingsRow(
                      context,
                      '계정 삭제',
                      isDark: isDark,
                      textColor: AppColors.redText,
                      onTap: () {
                        showSettingsDeleteAccountDialog(
                          context,
                              (password) async {
                            try {
                              await context
                                  .read<SettingViewModel>()
                                  .deleteAccountCompletely(password);

                              if (!context.mounted) return;

                              Navigator.pushNamedAndRemoveUntil(
                                context,
                                '/login',
                                    (_) => false,
                              );
                            } catch (e) {
                              if (!context.mounted) return;

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(e.toString()),
                                ),
                              );
                            }
                          },
                          isDark: isDark,
                        );
                      },
                    ),

                    _settingsRow(
                      context,
                      '로그아웃',
                      isDark: isDark,
                      textColor: AppColors.primary,
                      onTap: () {
                        showSettingsLogoutDialog(
                          context,
                              () async {
                            await context.read<SettingViewModel>().logout();

                            if (!context.mounted) return;

                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              '/login',
                                  (_) => false,
                            );
                          },
                          isDark: isDark,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

Widget _sectionDivider({bool isDark = false}) {
  return Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 8),
    child: Divider(
      height: 1,
      thickness: 1,
      color: isDark ? AppColors.darkDivider : Colors.grey[300],
    ),
  );
}

Widget _sectionHeader(String title, {bool isDark = false}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      title,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: isDark ? AppColors.darkSubText : Colors.black87,
        fontFamily: 'Pretendard Variable',
      ),
    ),
  );
}

Widget _settingsRow(
    BuildContext context,
    String title, {
      VoidCallback? onTap,
      Widget? trailing,
      Color? textColor,
      bool isDark = false,
    }) {
  final style = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    fontFamily: 'Pretendard Variable',
    color: textColor ?? (isDark ? AppColors.darkText : Colors.black),
  );

  final child = Padding(
    padding: const EdgeInsets.symmetric(vertical: 16),
    child: Row(
      children: [
        Text(title, style: style),
        const Spacer(),
        if (trailing != null) trailing,
      ],
    ),
  );

  if (onTap != null) {
    return InkWell(
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      child: child,
    );
  }

  return child;
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({this.isDark = false});

  final bool isDark;

  String _displayIdFromEmail(String email) {
    final trimmed = email.trim();
    if (trimmed.isEmpty) return '';

    final atIndex = trimmed.indexOf('@');
    if (atIndex <= 0) return trimmed;

    return trimmed.substring(0, atIndex);
  }

  @override
  Widget build(BuildContext context) {
    final authRepo = context.read<AuthRepository>();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, '/personal_info'),
        borderRadius: AppBorderRadius.card,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: AppBorderRadius.card,
            border: Border.all(
              color: isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB),
            ),
          ),
          child: FutureBuilder<String>(
            future: authRepo.getUserName(),
            builder: (context, snapshot) {
              final name = snapshot.hasData &&
                  snapshot.data != null &&
                  snapshot.data!.isNotEmpty
                  ? snapshot.data!
                  : '회원';

              final userId = _displayIdFromEmail(authRepo.currentUserEmail);

              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark
                          ? AppColors.darkBorder
                          : const Color(0xFFE5E7EB),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkDivider
                            : const Color(0xFFD1D5DB),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.person,
                      size: 36,
                      color: isDark ? AppColors.darkSubText : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkText : Colors.black,
                            fontFamily: 'Pretendard Variable',
                          ),
                        ),
                        if (userId.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            userId,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark
                                  ? AppColors.darkSubText
                                  : Colors.grey[600],
                              fontFamily: 'Pretendard Variable',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
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

