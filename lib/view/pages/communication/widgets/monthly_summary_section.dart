import 'package:flutter/material.dart';
import '../../../../view_model/communication/communication_view_model.dart';

class MonthlySummarySection extends StatelessWidget {
  final CommunicationViewModel vm;

  const MonthlySummarySection({super.key, required this.vm});

  @override
  Widget build(BuildContext context) {
    final summary = vm.monthlyEmotionSummary();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _box,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '이번 달 감정 요약',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              _card('😊', '행복한 날', summary['happy']),
              const SizedBox(width: 12),
              _card('😐', '평범한 날', summary['normal']),
              const SizedBox(width: 12),
              _card('😢', '우울한 날', summary['gloomy']),
            ],
          ),

          const SizedBox(height: 20),
          _summaryMessage(summary['message']),
        ],
      ),
    );
  }

  Widget _card(String emoji, String label, int count) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text(label),
            const SizedBox(height: 4),
            Text('$count일',
                style:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _summaryMessage(String msg) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        msg,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        textAlign: TextAlign.center,
      ),
    );
  }

  BoxDecoration get _box => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(color: Colors.black12, blurRadius: 8),
    ],
  );
}
