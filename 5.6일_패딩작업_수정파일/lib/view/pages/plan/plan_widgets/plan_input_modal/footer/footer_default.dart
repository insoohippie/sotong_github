import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sotong_local/component/buttons/custom_button.dart';
import 'package:sotong_local/component/texts/paragraph_text.dart';
import 'package:sotong_local/component/theme/app_colors.dart';
import 'package:sotong_local/component/theme/app_spacing.dart';
import 'package:sotong_local/component/theme/padding/horizontal_padding_clamped_fraction.dart';

class FooterDefault extends StatefulWidget {
  final double total; // 고정소비/수입 합계 (수입일 땐 isOverBudget=false로 들어옴)
  final VoidCallback onComplete;
  final bool isOverBudget; // 예산 초과 여부 (고정소비가 월수입 초과일 때)
  final double monthlyIncome;

  /// true면 합계 0이어도 완료 가능, false면 합계 0이면 완료 버튼 비활성화 (월 수입 모달용)
  final bool allowZeroTotal;

  const FooterDefault({
    Key? key,
    required this.total,
    required this.onComplete,
    this.isOverBudget = false,
    this.monthlyIncome = 0,
    this.allowZeroTotal = true,
  }) : super(key: key);

  @override
  State<FooterDefault> createState() => _FooterDefaultState();
}

class _FooterDefaultState extends State<FooterDefault>
    with TickerProviderStateMixin {
  late AnimationController _shakeController;
  late Animation<double> _shake;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shake = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  @override
  void didUpdateWidget(covariant FooterDefault oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOverBudget && !oldWidget.isOverBudget) {
      _shakeController.forward().then((_) => _shakeController.reverse());
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final over = widget.isOverBudget;
    final canComplete = !over && (widget.allowZeroTotal || widget.total > 0);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: PaddingResponsive16_40Vw.horizontal(
          context,
          PaddingResponsive16_40Vw.fractionModal06,
        ),
        vertical: AppSpacing.screenPadding,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        border: const Border(top: BorderSide(color: Color(0xFFF0F0F0))),
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _shake,
            builder: (_, __) {
              return Transform.translate(
                offset: Offset(_shake.value, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const ParagraphText(
                      text: '총합:',
                      fontWeight: FontWeight.bold,
                    ),
                    ParagraphText(
                      text:
                      '${NumberFormat('#,###').format(widget.total.toInt())}원',
                      fontWeight: FontWeight.bold,
                      color: over ? const Color(0xFFF02121) : AppColors.primary,
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 40),
          CustomButton(
            text: over ? '예산을 초과했어요' : (canComplete ? '완료' : '월 수입을 입력해 주세요'),
            onPressed: canComplete ? widget.onComplete : () {},
            enabled: canComplete,
          ),
        ],
      ),
    );
  }
}
