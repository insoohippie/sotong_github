import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../component/buttons/custom_button.dart';
import '../../../../component/buttons/custom_dual_button.dart';
import '../../../../component/inputs/custom_text_field.dart';
import '../../../../component/texts/header_text.dart';
import '../../../../component/texts/paragraph_text.dart';
import '../../../../component/theme/app_colors.dart';
import '../../../../component/theme/app_spacing.dart';
import '../../../../view_model/home/home_view_model.dart';

/// 바텀시트를 띄우는 헬퍼 함수
Future<void> showPlanNameEditSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      // HomeViewModel 재사용 (새 Provider 생성 X)
      final vm = context.read<HomeViewModel>();
      return ChangeNotifierProvider.value(
        value: vm,
        child: const _PlanNameEditSheetBody(),
      );
    },
  );
}

class _PlanNameEditSheetBody extends StatefulWidget {
  const _PlanNameEditSheetBody({super.key});

  @override
  State<_PlanNameEditSheetBody> createState() => _PlanNameEditSheetBodyState();
}

class _PlanNameEditSheetBodyState extends State<_PlanNameEditSheetBody> {
  late final TextEditingController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    final vm = context.read<HomeViewModel>();
    _controller = TextEditingController(text: vm.latestPlan?.planName ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isValid {
    final t = _controller.text.trim();
    return t.length >= 2; // 간단 검증: 2자 이상
  }

  Future<void> _submit() async {
    final vm = context.read<HomeViewModel>();
    final name = _controller.text.trim();
    if (!_isValid) {
      setState(() => _error = '플랜 이름을 2글자 이상 입력해주세요.');
      return;
    }

    setState(() => _error = null);
    final ok = await vm.updatePlanName(name);
    if (!mounted) return;

    if (ok) {
      Navigator.pop(context); // 시트 닫기
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('플랜 이름이 변경되었어요!')),
      );
    } else {
      // vm.error 활용
      final msg = vm.error ?? '이름 변경에 실패했어요. 잠시 후 다시 시도해주세요.';
      setState(() => _error = msg);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.screenPadding,
        right: AppSpacing.screenPadding,
        top: 16,
        bottom: bottomInset + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상단 핸들
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          CustomTextField(
            controller: _controller,
            hintText: '예: 여름휴가 프로젝트',
            keyboardType: TextInputType.text,
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
              setState(() {}); // 버튼 활성화 갱신
            },
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],

          const SizedBox(height: 16),
          CustomDualButton(
            leftLabel: '취소',
            rightLabel: vm.isRenaming ? '변경 중...' : '저장',
            onLeftPressed: () => Navigator.pop(context),
            onRightPressed: () async {
              if (vm.isRenaming) return;
              final name = _controller.text.trim();
              if (name.length < 2) {
                setState(() => _error = '플랜 이름을 2글자 이상 입력해주세요.');
                return;
              }
              final ok = await vm.updatePlanName(name);
              if (!mounted) return;
              if (ok) {
                Navigator.pop(context);
              } else {
                setState(() => _error = vm.error ?? '이름 변경에 실패했어요.');
              }
            },
            leftEnabled: !vm.isRenaming,
            rightEnabled: !vm.isRenaming && _isValid,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
