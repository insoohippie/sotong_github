import 'package:flutter/material.dart';

import 'package:sotong_local/component/buttons/custom_button.dart';
import 'package:sotong_local/component/theme/app_colors.dart';

class _AnimatedCenterPopup extends StatefulWidget {
  const _AnimatedCenterPopup({
    required this.child,
  });

  final Widget child;

  @override
  State<_AnimatedCenterPopup> createState() =>
      _AnimatedCenterPopupState();
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
      begin: 0,
      end: 1,
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

/// 화면 너비의 70%를 사용하되,
/// 작은 화면에서는 최소 260, 큰 화면에서는 최대 340으로 제한한다.
double _responsiveDialogWidth(BuildContext context) {
  final screenWidth = MediaQuery.sizeOf(context).width;

  return (screenWidth * 0.70)
      .clamp(260.0, 340.0)
      .toDouble();
}

/// Dialog가 지정된 너비로 정확히 중앙에 배치되도록 좌우 여백을 계산한다.
double _responsiveDialogInset(BuildContext context) {
  final screenWidth = MediaQuery.sizeOf(context).width;
  final dialogWidth = _responsiveDialogWidth(context);

  return ((screenWidth - dialogWidth) / 2)
      .clamp(12.0, screenWidth / 2)
      .toDouble();
}

/// 설정 화면 팝업의 공통 디자인 프레임
class _SettingsDialogFrame extends StatelessWidget {
  const _SettingsDialogFrame({
    required this.backgroundColor,
    required this.child,
  });

  final Color backgroundColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dialogWidth = _responsiveDialogWidth(context);
    final horizontalInset = _responsiveDialogInset(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: horizontalInset,
      ),
      child: _AnimatedCenterPopup(
        child: SizedBox(
          width: dialogWidth,
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: 28,
              horizontal: 24,
            ),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

TextStyle _titleStyle(
    Color color, {
      double fontSize = 22,
    }) {
  return TextStyle(
    fontFamily: 'Pretendard Variable',
    fontSize: fontSize,
    fontWeight: FontWeight.w700,
    color: color,
  );
}

TextStyle _bodyStyle(
    Color color, {
      double fontSize = 16,
    }) {
  return TextStyle(
    fontFamily: 'Pretendard Variable',
    fontSize: fontSize,
    fontWeight: FontWeight.w400,
    color: color,
    height: 1.4,
  );
}

/// 로그아웃 확인 팝업
Future<void> showSettingsLogoutDialog(
    BuildContext context,
    Future<void> Function() onConfirm, {
      bool isDark = false,
    }) {
  final bgColor = isDark
      ? AppColors.darkSurface
      : Colors.white;

  final textColor = isDark
      ? AppColors.darkText
      : Colors.black87;

  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black54,
    builder: (dialogContext) {
      return _SettingsDialogFrame(
        backgroundColor: bgColor,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '로그아웃',
              style: _titleStyle(textColor),
            ),
            const SizedBox(height: 12),
            Text(
              '정말 로그아웃 하시겠어요?',
              style: _bodyStyle(textColor),
            ),
            const SizedBox(height: 28),
            CustomButton(
              text: '로그아웃',
              height: 50,
              padding: EdgeInsets.zero,
              onPressed: () async {
                Navigator.pop(dialogContext);
                await onConfirm();
              },
            ),
            const SizedBox(height: 12),
            CustomButton(
              text: '닫기',
              height: 50,
              padding: EdgeInsets.zero,
              backgroundColor: AppColors.disabled,
              onPressed: () {
                Navigator.pop(dialogContext);
              },
            ),
          ],
        ),
      );
    },
  );
}

/// 플랜 삭제 확인 팝업
Future<void> showSettingsDeleteDataDialog(
    BuildContext context,
    String planName,
    VoidCallback onConfirm, {
      bool isDark = false,
    }) {
  final bgColor = isDark
      ? AppColors.darkSurface
      : Colors.white;

  final textColor = isDark
      ? AppColors.darkText
      : Colors.black87;

  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black54,
    builder: (dialogContext) {
      return _SettingsDialogFrame(
        backgroundColor: bgColor,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '플랜 지우기',
              style: _titleStyle(textColor),
            ),
            const SizedBox(height: 12),
            Text(
              planName == '플랜'
                  ? '플랜을 지우시겠습니까?'
                  : '$planName 플랜을 지우시겠습니까?',
              style: _bodyStyle(textColor),
            ),
            const SizedBox(height: 28),
            CustomButton(
              text: '플랜 지우기',
              height: 50,
              padding: EdgeInsets.zero,
              onPressed: () {
                Navigator.pop(dialogContext);
                onConfirm();
              },
            ),
            const SizedBox(height: 12),
            CustomButton(
              text: '닫기',
              height: 50,
              padding: EdgeInsets.zero,
              backgroundColor: AppColors.disabled,
              onPressed: () {
                Navigator.pop(dialogContext);
              },
            ),
          ],
        ),
      );
    },
  );
}

/// 계정 삭제 확인 및 비밀번호 입력 팝업
Future<void> showSettingsDeleteAccountDialog(
    BuildContext context,
    Future<void> Function(String password) onConfirm, {
      bool isDark = false,
    }) async {
  final bgColor = isDark
      ? AppColors.darkSurface
      : Colors.white;

  final textColor = isDark
      ? AppColors.darkText
      : Colors.black87;

  final controller = TextEditingController();

  try {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (dialogContext) {
        return _SettingsDialogFrame(
          backgroundColor: bgColor,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '계정 삭제',
                style: _titleStyle(textColor),
              ),
              const SizedBox(height: 12),
              Text(
                '계정을 삭제하면 프로필, 플랜, 소비 기록, 카테고리, '
                    '알림 설정 등 모든 데이터가 삭제되며 복구할 수 없습니다.'
                    '\n\n계정 삭제를 위해 비밀번호를 다시 입력해 주세요.',
                style: _bodyStyle(
                  textColor,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: controller,
                obscureText: true,
                style: TextStyle(
                  color: textColor,
                  fontFamily: 'Pretendard Variable',
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  hintText: '비밀번호 입력',
                  hintStyle: TextStyle(
                    color: isDark
                        ? AppColors.darkSubText
                        : Colors.grey,
                    fontFamily: 'Pretendard Variable',
                    fontSize: 15,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? AppColors.darkBackground
                      : const Color(0xFFF3F4F6),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.primary,
                      width: 1.2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              CustomButton(
                text: '계정 삭제',
                height: 50,
                padding: EdgeInsets.zero,
                backgroundColor: AppColors.redText,
                onPressed: () async {
                  final password = controller.text.trim();

                  Navigator.pop(dialogContext);
                  await onConfirm(password);
                },
              ),
              const SizedBox(height: 12),
              CustomButton(
                text: '닫기',
                height: 50,
                padding: EdgeInsets.zero,
                backgroundColor: AppColors.disabled,
                onPressed: () {
                  FocusScope.of(dialogContext).unfocus();
                  Navigator.pop(dialogContext);
                },
              ),
            ],
          ),
        );
      },
    );
  } finally {
    controller.dispose();
  }
}

/// 플랜 업로드 전 확인 팝업
Future<bool> showSettingsUploadConfirmDialog(
    BuildContext context, {
      bool isDark = false,
    }) async {
  final bgColor = isDark
      ? AppColors.darkSurface
      : Colors.white;

  final textColor = isDark
      ? AppColors.darkText
      : Colors.black87;

  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black54,
    builder: (dialogContext) {
      return _SettingsDialogFrame(
        backgroundColor: bgColor,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '플랜 업로드',
              style: _titleStyle(textColor),
            ),
            const SizedBox(height: 12),
            Text(
              '플랜과 기록을 업로드하시겠어요?\n'
                  '업로드한 데이터는 다른 기기에서도 불러와 사용할 수 있어요.',
              style: _bodyStyle(textColor),
            ),
            const SizedBox(height: 28),
            CustomButton(
              text: '확인',
              height: 50,
              padding: EdgeInsets.zero,
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
            ),
            const SizedBox(height: 12),
            CustomButton(
              text: '취소',
              height: 50,
              padding: EdgeInsets.zero,
              backgroundColor: AppColors.disabled,
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
            ),
          ],
        ),
      );
    },
  );

  return result ?? false;
}

/// 오프라인 상태에서 데이터 삭제를 시도했을 때
Future<void> showSettingsOfflineDeleteDialog(
    BuildContext context, {
      bool isDark = false,
    }) {
  final bgColor = isDark
      ? AppColors.darkSurface
      : Colors.white;

  final textColor = isDark
      ? AppColors.darkText
      : Colors.black87;

  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black54,
    builder: (dialogContext) {
      return _SettingsDialogFrame(
        backgroundColor: bgColor,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '인터넷 연결 필요',
              style: _titleStyle(textColor),
            ),
            const SizedBox(height: 12),
            Text(
              '데이터 삭제는 서버와 동기화가 필요해요.\n'
                  '인터넷에 연결한 후 다시 시도해주세요.',
              style: _bodyStyle(textColor),
            ),
            const SizedBox(height: 28),
            CustomButton(
              text: '확인',
              height: 50,
              padding: EdgeInsets.zero,
              onPressed: () {
                Navigator.pop(dialogContext);
              },
            ),
          ],
        ),
      );
    },
  );
}

/// 오프라인 상태에서 업로드를 시도했을 때
Future<void> showSettingsOfflineUploadDialog(
    BuildContext context, {
      bool isDark = false,
    }) {
  final bgColor = isDark
      ? AppColors.darkSurface
      : Colors.white;

  final textColor = isDark
      ? AppColors.darkText
      : Colors.black87;

  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black54,
    builder: (dialogContext) {
      return _SettingsDialogFrame(
        backgroundColor: bgColor,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '인터넷 연결 필요',
              style: _titleStyle(textColor),
            ),
            const SizedBox(height: 12),
            Text(
              '플랜 업로드는 서버와 동기화가 필요해요.\n'
                  '인터넷에 연결한 후 다시 시도해주세요.',
              style: _bodyStyle(textColor),
            ),
            const SizedBox(height: 28),
            CustomButton(
              text: '확인',
              height: 50,
              padding: EdgeInsets.zero,
              onPressed: () {
                Navigator.pop(dialogContext);
              },
            ),
          ],
        ),
      );
    },
  );
}

/// 준비 중 기능 안내 팝업
Future<void> showSettingsComingSoonDialog(
    BuildContext context, {
      required String title,
      required String message,
      bool isDark = false,
    }) {
  final bgColor = isDark
      ? AppColors.darkSurface
      : Colors.white;

  final textColor = isDark
      ? AppColors.darkText
      : Colors.black87;

  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black54,
    builder: (dialogContext) {
      return _SettingsDialogFrame(
        backgroundColor: bgColor,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: _titleStyle(textColor),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: _bodyStyle(textColor),
            ),
            const SizedBox(height: 28),
            CustomButton(
              text: '확인',
              height: 50,
              padding: EdgeInsets.zero,
              onPressed: () {
                Navigator.pop(dialogContext);
              },
            ),
          ],
        ),
      );
    },
  );
}