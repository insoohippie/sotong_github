import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../view_model/plan/plan_chat_viewmodel.dart';
import '../../widgets/texts/header_text.dart';
import '../../widgets/texts/paragraph_text.dart';
import '../../widgets/inputs/custom_dropdown.dart';

class PlanChatPage extends StatelessWidget {
  const PlanChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PlanChatVM>();

    return Scaffold(
      appBar: AppBar(title: const HeaderText(text: '플랜 생성')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const ChatBubble(text: '새로운 플랜 이름을 알려주세요!'),
            TextField(
              onChanged: vm.setPlanName,
              style: const TextStyle(fontFamily: 'Pretendard'),
              decoration: const InputDecoration(hintText: '예: 여행 자금 만들기'),
            ),
            const SizedBox(height: 20),

            const ChatBubble(text: '이 플랜의 목적은 무엇인가요?'),
            CustomDropdown(
              value: vm.planPurpose.isEmpty ? null : vm.planPurpose,
              items: ['여행', '비상금', '저축', '기타'],
              hintText: '플랜 목적 선택',
              onChanged: (value) {
                if (value != null) vm.setPlanPurpose(value);
              },
            ),
            const SizedBox(height: 20),

            const ChatBubble(text: '목표 금액을 입력해주세요!'),
            TextField(
              keyboardType: TextInputType.number,
              onChanged: vm.setGoalAmount,
              style: const TextStyle(fontFamily: 'Pretendard'),
              decoration: const InputDecoration(hintText: '예: 1000000'),
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: vm.isComplete
                  ? () {
                final plan = vm.createPlan();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '플랜 저장 완료: ${plan.planName}, ${plan.goalAmount}원',
                      style: const TextStyle(fontFamily: 'Pretendard'),
                    ),
                  ),
                );
                vm.clear();
              }
                  : null,
              style: ElevatedButton.styleFrom(
                textStyle: const TextStyle(fontFamily: 'Pretendard'),
              ),
              child: const Text('플랜 저장'),
            )
          ],
        ),
      ),
    );
  }
}

class ChatBubble extends StatelessWidget {
  final String text;
  final bool isBot;

  const ChatBubble({
    super.key,
    required this.text,
    this.isBot = true,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isBot ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isBot ? Colors.grey[200] : Colors.blue[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: ParagraphText(text: text),
      ),
    );
  }
}
