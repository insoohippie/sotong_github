import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../component/appbars/back_only_app_bar.dart';
import '../../../component/buttons/custom_button.dart';
import '../../../component/inputs/custom_text_field.dart';
import '../../../component/theme/app_colors.dart';
import '../../../repository/auth_repository.dart';
import '../plan/plan_widgets/plan_input_modal/single_value_input_modal.dart';

/// 개인정보 수정 페이지: 닉네임 / 비밀번호 수정 / 아이디
class PersonalInfoPage extends StatefulWidget {
  const PersonalInfoPage({Key? key}) : super(key: key);

  @override
  State<PersonalInfoPage> createState() => _PersonalInfoPageState();
}

class _PersonalInfoPageState extends State<PersonalInfoPage> {
  late final TextEditingController _nicknameController;

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController();
    _loadProfile();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final authRepo = context.read<AuthRepository>();
    final nickname = await authRepo.getUserName();

    if (mounted) {
      setState(() {
        _nicknameController.text = nickname == '회원' ? '' : nickname;
        _isLoading = false;
      });
    }
  }

  Future<void> _save() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      final authRepo = context.read<AuthRepository>();

      await authRepo.updateProfile(
        nickname: _nicknameController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('저장 실패: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _openNicknameModal() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: SingleValueInputModal(
          hintText: '닉네임을 입력하세요',
          buttonTextEmpty: '닉네임을 입력해주세요!',
          buttonTextFilled: '저장',
          initialValue: _nicknameController.text,
          onComplete: (value) {
            if (mounted) {
              setState(() => _nicknameController.text = value);
            }
          },
          onClose: () => Navigator.pop(ctx),
        ),
      ),
    );
  }

  Future<void> _openIdModal(String email) async {
    final displayId = _displayIdFromEmail(email);
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildInfoModal(
        ctx: ctx,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Builder(
              builder: (ctx) {
                final theme = Theme.of(ctx);
                final isDark = theme.brightness == Brightness.dark;

                return Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: isDark
                        ? theme.colorScheme.surface
                        : AppColors.greyBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    displayId.isEmpty ? '-' : displayId,
                    style: TextStyle(
                      fontSize: 15,
                      fontFamily: 'Pretendard Variable',
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            CustomButton(
              text: '확인',
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  String _displayIdFromEmail(String email) {
    final trimmed = email.trim();
    if (trimmed.isEmpty) return '';
    final atIndex = trimmed.indexOf('@');
    if (atIndex <= 0) return trimmed;
    return trimmed.substring(0, atIndex);
  }

  Widget _buildInfoModal({
    required BuildContext ctx,
    required Widget child,
  }) {
    final theme = Theme.of(ctx);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(40),
          topRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              theme.brightness == Brightness.dark ? 0.3 : 0.1,
            ),
            offset: const Offset(0, -4),
            blurRadius: 6,
            spreadRadius: 0,
          ),
        ],
      ),
      child: SafeArea(top: false, child: child),
    );
  }

  Future<void> _openPasswordChangeModal() async {
    await _showCurrentPasswordModal();
  }

  /// 1단계: 현재 비밀번호 확인
  Future<void> _showCurrentPasswordModal() async {
    final ctl = TextEditingController();
    String? errorMsg;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          Future<void> onConfirm() async {
            final cur = ctl.text.trim();

            if (cur.isEmpty) {
              setModalState(() => errorMsg = '현재 비밀번호를 입력해주세요.');
              return;
            }

            try {
              final authRepo = context.read<AuthRepository>();
              await authRepo.verifyCurrentPassword(cur);

              if (!mounted) return;
              Navigator.pop(ctx);

              if (!mounted) return;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                _showNewPasswordModal();
              });
            } catch (e) {
              setModalState(() {
                errorMsg =
                e.toString().contains('invalid-credential') ||
                    e.toString().contains('wrong-password')
                    ? '비밀번호가 일치하지 않습니다.'
                    : e.toString().contains('requires-recent-login')
                    ? '보안을 위해 다시 로그인한 후 시도해주세요.'
                    : '확인 실패: $e';
              });
            }
          }

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: _buildInfoModal(
              ctx: ctx,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CustomTextField(
                    controller: ctl,
                    hintText: '현재 비밀번호',
                    obscureText: true,
                    onChanged: (_) => setModalState(() => errorMsg = null),
                  ),
                  if (errorMsg != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      errorMsg!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  CustomButton(
                    text: '확인',
                    onPressed: ctl.text.trim().isEmpty ? () {} : onConfirm,
                    enabled: ctl.text.trim().isNotEmpty,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ).whenComplete(() => ctl.dispose());
  }

  /// 2단계: 새 비밀번호 입력
  Future<void> _showNewPasswordModal() async {
    final newCtl = TextEditingController();
    final confirmCtl = TextEditingController();
    String? errorMsg;
    final pageContext = context;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          bool isValid() {
            final n = newCtl.text.trim();
            final c = confirmCtl.text.trim();

            if (n.isEmpty || c.isEmpty) return false;
            if (n.length < 6) return false;
            if (n != c) return false;

            return true;
          }

          Future<void> onConfirm() async {
            final n = newCtl.text.trim();
            final c = confirmCtl.text.trim();

            if (n.length < 6) {
              setModalState(() => errorMsg = '비밀번호는 6자 이상이어야 합니다.');
              return;
            }

            if (n != c) {
              setModalState(() => errorMsg = '새 비밀번호가 일치하지 않습니다.');
              return;
            }

            try {
              final authRepo = pageContext.read<AuthRepository>();
              await authRepo.updatePasswordTo(n);

              Navigator.pop(ctx);

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (pageContext.mounted) {
                  ScaffoldMessenger.of(pageContext).showSnackBar(
                    const SnackBar(content: Text('비밀번호가 변경되었습니다.')),
                  );
                }
              });
            } catch (e) {
              setModalState(() {
                errorMsg = e.toString().contains('requires-recent-login')
                    ? '보안을 위해 다시 로그인한 후 시도해주세요.'
                    : '비밀번호 변경 실패: $e';
              });
            }
          }

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: _buildInfoModal(
              ctx: ctx,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CustomTextField(
                    controller: newCtl,
                    hintText: '새 비밀번호',
                    obscureText: true,
                    onChanged: (_) => setModalState(() => errorMsg = null),
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: confirmCtl,
                    hintText: '새 비밀번호 확인',
                    obscureText: true,
                    onChanged: (_) => setModalState(() => errorMsg = null),
                  ),
                  if (errorMsg != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      errorMsg!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  CustomButton(
                    text: '변경',
                    onPressed: isValid() ? onConfirm : () {},
                    enabled: isValid(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ).whenComplete(() {
      newCtl.dispose();
      confirmCtl.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authRepo = context.read<AuthRepository>();
    final email = authRepo.currentUserEmail;
    final displayId = _displayIdFromEmail(email);

    if (_isLoading) {
      return Scaffold(
        appBar: const BackOnlyAppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: const BackOnlyAppBar(),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  border: Border.all(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.person,
                  size: 52,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),

            const SizedBox(height: 20),

            _buildLabel('닉네임'),
            const SizedBox(height: 8),
            _buildTappableField(
              value: _nicknameController.text.isEmpty
                  ? '닉네임을 입력하세요'
                  : _nicknameController.text,
              hintStyle: _nicknameController.text.isEmpty,
              onTap: _openNicknameModal,
            ),

            const SizedBox(height: 24),

            _buildLabel('아이디'),
            const SizedBox(height: 8),
            _buildTappableField(
              value: displayId.isEmpty ? '-' : displayId,
              hintStyle: displayId.isEmpty,
              onTap: () => _openIdModal(email),
            ),

            const SizedBox(height: 24),

            _buildLabel('비밀번호'),
            const SizedBox(height: 8),
            _buildTappableField(
              value: '********',
              hintStyle: false,
              onTap: _openPasswordChangeModal,
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: CustomButton(
            text: '완료',
            onPressed: _isSaving ? () {} : _save,
            enabled: !_isSaving,
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        fontFamily: 'Pretendard Variable',
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  Widget _buildTappableField({
    required String value,
    required bool hintStyle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final hasValue = !hintStyle;

    final fieldBg = hasValue
        ? (isDark ? theme.colorScheme.surface : AppColors.lightBlue)
        : (isDark ? theme.colorScheme.surface : AppColors.greyBackground);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: fieldBg,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontFamily: 'Pretendard Variable',
                  fontWeight: FontWeight.w500,
                  color: hintStyle
                      ? theme.colorScheme.onSurfaceVariant
                      : theme.colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }
}