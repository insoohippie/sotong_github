import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../component/appbars/back_only_app_bar.dart';
import '../../../component/buttons/custom_button.dart';
import '../../../component/buttons/custom_dual_button.dart';
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
                    // 1. 알림 설정
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
                    // 2. 플랜 설정
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
                              requireApplyDate: false,
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
                      onTap: () => Navigator.pushNamed(context, '/past_plans'),
                    ),
                    _sectionDivider(isDark: isDark),
                    // 3. 기타
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
                    // 플랜 지우기 / 로그아웃
                    _settingsRow(
                      context,
                      '플랜 지우기',
                      isDark: isDark,
                      textColor: AppColors.redText,
                      onTap: () async {
                        final vm = context.read<SettingViewModel>();
                        if (!vm.isOnline) {
                          showOfflineDeleteBlockedDialog(
                            context,
                            isDark: isDark,
                          );
                          return;
                        }
                        final name = context
                            .read<ChatPlanViewModel>()
                            .totalPlan
                            .planName
                            ?.trim();
                        final planName = (name != null && name.isNotEmpty)
                            ? name
                            : '플랜';
                        showDeleteDataDialog(context, planName, () async {
                          await vm.deleteAllMyData();
                          if (context.mounted) {
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              '/login',
                                  (_) => false,
                            );
                          }
                        }, isDark: isDark);
                      },
                    ),
                    _settingsRow(
                      context,
                      '로그아웃',
                      isDark: isDark,
                      textColor: AppColors.primary,
                      onTap: () {
                        showLogoutDialog(context, () async {
                          await context.read<SettingViewModel>().logout();
                          if (!context.mounted) return;
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/login',
                                (_) => false,
                          );
                        }, isDark: isDark);
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

/// 섹션 구분선 (당근 스타일)
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

/// 섹션 헤더: 진한 글씨, 텍스트 크기 작게
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

/// 당근 스타일: 텍스트 왼쪽 정렬 한 줄 (탭 시 동작 or trailing 위젯)
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

/// 카카오톡 스타일 프로필: 프로필 사진(기본), 이름, 아이디(이메일)
class _ProfileSection extends StatelessWidget {
  const _ProfileSection({this.isDark = false});
  final bool isDark;

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
              final name =
              snapshot.hasData &&
                  snapshot.data != null &&
                  snapshot.data!.isNotEmpty
                  ? snapshot.data!
                  : '회원';
              final email = authRepo.currentUserEmail.isNotEmpty
                  ? authRepo.currentUserEmail
                  : '';

              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 프로필 사진 (기본) — 왼쪽
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
                  // 이름, 이메일 — 오른쪽, 왼쪽 정렬
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
                        if (email.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            email,
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

/// 중앙에서 퍼지는 스케일 애니메이션 팝업
class _AnimatedCenterPopup extends StatefulWidget {
  final Widget child;

  const _AnimatedCenterPopup({required this.child});

  @override
  State<_AnimatedCenterPopup> createState() => _AnimatedCenterPopupState();
}

class _AnimatedCenterPopupState extends State<_AnimatedCenterPopup>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      alignment: Alignment.center,
      child: widget.child,
    );
  }
}

/// 로그아웃 확인 팝업: 중앙 팝업 + 스케일 애니메이션
void showLogoutDialog(
    BuildContext context,
    Future<void> Function() onConfirm, {
      bool isDark = false,
    }) {
  final bgColor = isDark ? AppColors.darkSurface : Colors.white;
  final textColor = isDark ? AppColors.darkText : Colors.black87;
  showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black54,
    builder: (context) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 56),
        child: _AnimatedCenterPopup(
          child: Transform.scale(
            scale: 0.7,
            alignment: Alignment.center,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '로그아웃',
                    style: TextStyle(
                      fontFamily: 'Pretendard Variable',
                      fontSize: 25,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '정말 로그아웃 하시겠어요?',
                    style: TextStyle(
                      fontFamily: 'Pretendard Variable',
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                      color: textColor,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 28),
                  CustomButton(
                    text: '로그아웃',
                    height: 50,
                    padding: EdgeInsets.zero,
                    onPressed: () async {
                      Navigator.pop(context);
                      await onConfirm();
                    },
                  ),
                  const SizedBox(height: 12),
                  CustomButton(
                    text: '닫기',
                    height: 50,
                    padding: EdgeInsets.zero,
                    backgroundColor: AppColors.disabled,
                    onPressed: () => Navigator.pop(context),
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

/// 플랜 지우기 확인 팝업: 중앙 팝업 + 스케일 애니메이션
void showDeleteDataDialog(
    BuildContext context,
    String planName,
    VoidCallback onConfirm, {
      bool isDark = false,
    }) {
  final bgColor = isDark ? AppColors.darkSurface : Colors.white;
  final textColor = isDark ? AppColors.darkText : Colors.black87;
  showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black54,
    builder: (context) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 56),
        child: _AnimatedCenterPopup(
          child: Transform.scale(
            scale: 0.7,
            alignment: Alignment.center,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '플랜 지우기',
                    style: TextStyle(
                      fontFamily: 'Pretendard Variable',
                      fontSize: 25,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    planName == '플랜'
                        ? '플랜을 지우시겠습니까?'
                        : '$planName 플랜을 지우시겠습니까?',
                    style: TextStyle(
                      fontFamily: 'Pretendard Variable',
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                      color: textColor,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 28),
                  CustomButton(
                    text: '플랜 지우기',
                    height: 50,
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      Navigator.pop(context);
                      onConfirm();
                    },
                  ),
                  const SizedBox(height: 12),
                  CustomButton(
                    text: '닫기',
                    height: 50,
                    padding: EdgeInsets.zero,
                    backgroundColor: AppColors.disabled,
                    onPressed: () => Navigator.pop(context),
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

void showOfflineDeleteBlockedDialog(
    BuildContext context, {
      bool isDark = false,
    }) {
  final bgColor = isDark ? AppColors.darkSurface : Colors.white;
  final textColor = isDark ? AppColors.darkText : Colors.black87;
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      return Dialog(
        backgroundColor: bgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HeaderText(
                text: "인터넷 연결 필요",
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
              const SizedBox(height: 12),
              ParagraphText(
                text:
                "플랜 삭제는 서버와 동기화가 필요해요.\n"
                    "인터넷에 연결한 후 다시 시도해주세요.",
                color: textColor,
              ),
              const SizedBox(height: 28),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text("확인"),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
