import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sotong_local/component/texts/paragraph_text.dart';
import 'package:sotong_local/component/theme/app_colors.dart';

class FooterDefault extends StatelessWidget {
  final double total;
  final VoidCallback onComplete;

  const FooterDefault({
    Key? key,
    required this.total,
    required this.onComplete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        border: const Border(top: BorderSide(color: Color(0xFFF0F0F0))),
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: Offset(0, -2)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const ParagraphText(text: '총합:', fontWeight: FontWeight.bold),
              ParagraphText(
                text: '${NumberFormat('#,###').format(total.toInt())}원',
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCompleteButton(),
        ],
      ),
    );
  }

  Widget _buildCompleteButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onComplete,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0062FF),
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const ParagraphText(text: '완료', color: AppColors.whiteText, fontWeight: FontWeight.bold),
      ),
    );
  }
}
