import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

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
import '../../../services/local_notification_service.dart';
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
                    _NotificationSettingsRow(isDark: isDark),

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
                        showComingSoonDialog(
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
                      trailing: _settingsSwitch(
                        value: settingsVM.isDarkMode,
                        onChanged: (value) {
                          HapticFeedback.selectionClick();
                          settingsVM.toggleDarkMode(value);
                        },
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
                          showOfflineUploadBlockedDialog(
                            context,
                            isDark: isDark,
                          );
                          return;
                        }

                        try {
                          await vm.uploadAllData();

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('플랜과 데이터가 업로드되었습니다.'),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString())),
                            );
                          }
                        }
                      },
                    ),

                    _settingsRow(
                      context,
                      '계정 삭제',
                      isDark: isDark,
                      textColor: AppColors.redText,
                      onTap: () async {
                        final settingsVm = context.read<SettingViewModel>();
                        final navigator = Navigator.of(context);
                        final deleted = await showDeleteAccountDialog(
                          context,
                          onConfirm: (password) =>
                              settingsVm.deleteAccountCompletely(password),
                          isDark: isDark,
                        );
                        if (!deleted || !navigator.mounted) return;
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/login',
                              (_) => false,
                        );
                      },
                    ),

                    _settingsRow(
                      context,
                      '로그아웃',
                      isDark: isDark,
                      textColor: AppColors.primary,
                      onTap: () {
                        showLogoutDialog(
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

Widget _settingsSwitch({
  required bool value,
  required ValueChanged<bool>? onChanged,
}) {
  return Switch(
    value: value,
    onChanged: onChanged,
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return Colors.grey.shade400;
      }
      return Colors.grey.shade400;
    }),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return Colors.grey.shade400.withValues(alpha: 0.45);
      }
      return Colors.grey.shade300;
    }),
    trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
  );
}

class _NotificationSettingsRow extends StatefulWidget {
  const _NotificationSettingsRow({required this.isDark});

  final bool isDark;

  @override
  State<_NotificationSettingsRow> createState() => _NotificationSettingsRowState();
}

class _NotificationSettingsRowState extends State<_NotificationSettingsRow>
    with WidgetsBindingObserver {
  bool? _notificationsEnabled;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshPermission();
    }
  }

  Future<void> _refreshPermission() async {
    final granted =
        await LocalNotificationService.instance.isPermissionGranted();

    if (!granted) {
      await LocalNotificationService.instance.cancelAllScheduled();
    }

    if (!mounted) return;
    setState(() => _notificationsEnabled = granted);
  }

  Future<void> _openSystemNotificationSettings() async {
    HapticFeedback.selectionClick();
    await LocalNotificationService.instance.openSystemNotificationSettings();
  }

  void _openNotificationSettingPage() {
    if (_notificationsEnabled != true) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationSettingPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final enabled = _notificationsEnabled == true;
    final textColor = widget.isDark ? AppColors.darkText : Colors.black;
    final labelColor = enabled ? textColor : textColor.withValues(alpha: 0.35);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: enabled ? _openNotificationSettingPage : null,
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              hoverColor: Colors.transparent,
              child: Text(
                '알림 수신 설정',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Pretendard Variable',
                  color: labelColor,
                ),
              ),
            ),
          ),
          _settingsSwitch(
            value: _notificationsEnabled ?? false,
            onChanged: (_) => _openSystemNotificationSettings(),
          ),
        ],
      ),
    );
  }
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
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

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

double _responsiveDialogWidth(BuildContext context) {
  final screenWidth = MediaQuery.sizeOf(context).width;
  return (screenWidth * 0.70).clamp(260.0, 340.0).toDouble();
}

double _responsiveDialogInset(BuildContext context) {
  final screenWidth = MediaQuery.sizeOf(context).width;
  final dialogWidth = _responsiveDialogWidth(context);
  return ((screenWidth - dialogWidth) / 2).clamp(12.0, screenWidth / 2).toDouble();
}

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
      final dialogWidth = _responsiveDialogWidth(context);
      final horizontalInset = _responsiveDialogInset(context);
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: horizontalInset),
        child: _AnimatedCenterPopup(
          child: SizedBox(
            width: dialogWidth,
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
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '정말 로그아웃 하시겠어요?',
                    style: TextStyle(
                      fontFamily: 'Pretendard Variable',
                      fontSize: 16,
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

Future<bool> showDeleteAccountDialog(
  BuildContext context, {
  required Future<void> Function(String password) onConfirm,
  bool isDark = false,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black54,
    builder: (dialogContext) {
      return _DeleteAccountDialog(
        isDark: isDark,
        onConfirm: onConfirm,
      );
    },
  ).then((value) => value ?? false);
}

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog({
    required this.isDark,
    required this.onConfirm,
  });

  final bool isDark;
  final Future<void> Function(String password) onConfirm;

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  late final TextEditingController _controller;
  String? _errorMessage;
  bool _isSubmitting = false;
  double _shakeOffset = 0;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _bgColor =>
      widget.isDark ? AppColors.darkSurface : Colors.white;

  Color get _textColor =>
      widget.isDark ? AppColors.darkText : Colors.black87;

  Future<void> _runShake() async {
    if (!mounted) return;
    setState(() => _shakeOffset = 8);
    await Future.delayed(const Duration(milliseconds: 45));
    if (!mounted) return;
    setState(() => _shakeOffset = -8);
    await Future.delayed(const Duration(milliseconds: 45));
    if (!mounted) return;
    setState(() => _shakeOffset = 6);
    await Future.delayed(const Duration(milliseconds: 45));
    if (!mounted) return;
    setState(() => _shakeOffset = 0);
  }

  Future<void> _onDeletePressed() async {
    if (_isSubmitting) return;
    final password = _controller.text.trim();

    if (password.isEmpty) {
      HapticFeedback.mediumImpact();
      setState(() => _errorMessage = '비밀번호를 입력해주세요.');
      await _runShake();
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await widget.onConfirm(password);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      setState(() {
        _isSubmitting = false;
        _errorMessage =
            e.toString().contains('invalid-credential') ||
                    e.toString().contains('wrong-password')
                ? '비밀번호가 다릅니다.'
                : e.toString().contains('requires-recent-login')
                    ? '다시 로그인 후 시도해주세요.'
                    : '계정 삭제에 실패했습니다.';
      });
      await _runShake();
    }
  }

  void _close() {
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final dialogWidth = _responsiveDialogWidth(context);
    final horizontalInset = _responsiveDialogInset(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: horizontalInset),
      child: _AnimatedCenterPopup(
        child: SizedBox(
          width: dialogWidth,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
            decoration: BoxDecoration(
              color: _bgColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '계정 삭제',
                  style: TextStyle(
                    fontFamily: 'Pretendard Variable',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: _textColor,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '계정삭제를 진행하시겠습니까?',
                  style: TextStyle(
                    fontFamily: 'Pretendard Variable',
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: _textColor,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 70),
                  transform: Matrix4.translationValues(_shakeOffset, 0, 0),
                  child: TextField(
                    controller: _controller,
                    obscureText: true,
                    style: TextStyle(
                      color: _textColor,
                      fontFamily: 'Pretendard Variable',
                    ),
                    decoration: InputDecoration(
                      hintText: '비밀번호 입력',
                      hintStyle: TextStyle(
                        color: widget.isDark
                            ? AppColors.darkSubText
                            : Colors.grey,
                        fontFamily: 'Pretendard Variable',
                      ),
                      filled: true,
                      fillColor: widget.isDark
                          ? AppColors.darkBackground
                          : const Color(0xFFF3F4F6),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                    ),
                    onChanged: (_) {
                      if (_errorMessage != null) {
                        setState(() => _errorMessage = null);
                      }
                    },
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Color(0xFFDC2626),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Pretendard Variable',
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                CustomButton(
                  text: _isSubmitting ? '처리 중...' : '계정 삭제',
                  height: 50,
                  padding: EdgeInsets.zero,
                  backgroundColor: AppColors.redText,
                  onPressed: _onDeletePressed,
                ),
                const SizedBox(height: 12),
                CustomButton(
                  text: '닫기',
                  height: 50,
                  padding: EdgeInsets.zero,
                  backgroundColor: AppColors.disabled,
                  onPressed: _close,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
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
                text: '인터넷 연결 필요',
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
              const SizedBox(height: 12),
              ParagraphText(
                text: '데이터 삭제는 서버와 동기화가 필요해요.\n인터넷에 연결한 후 다시 시도해주세요.',
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
                  child: const Text('확인'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

void showOfflineUploadBlockedDialog(
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
                text: '인터넷 연결 필요',
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
              const SizedBox(height: 12),
              ParagraphText(
                text: '플랜 업로드는 서버와 동기화가 필요해요.\n인터넷에 연결한 후 다시 시도해주세요.',
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
                  child: const Text('확인'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

void showComingSoonDialog(
    BuildContext context, {
      required String title,
      required String message,
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
              padding: const EdgeInsets.symmetric(
                vertical: 28,
                horizontal: 24,
              ),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Pretendard Variable',
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    style: TextStyle(
                      fontFamily: 'Pretendard Variable',
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: textColor,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),
                  CustomButton(
                    text: '확인',
                    height: 50,
                    padding: EdgeInsets.zero,
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