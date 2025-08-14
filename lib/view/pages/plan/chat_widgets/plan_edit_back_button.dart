// widgets/plan_edit_back_button.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../component/appbars/custom_app_bar.dart';
import '../../../../view_model/plan/chat_plan_viewmodel.dart';
import '../plan_edit_page.dart';

class PlanEditBackAppBar extends StatelessWidget {
  const PlanEditBackAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomAppBar(
      title: '',
      onBack: () async {
        final shouldEdit = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('플랜 수정'),
            content: const Text('플랜을 수정하시겠어요?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('아니요'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('네'),
              ),
            ],
          ),
        );

        if (shouldEdit == true && context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) {
                final vm = context.read<ChatPlanViewModel>();
                return PlanEditPage(
                  initialPlan: vm.planInfo,
                  initialRefData: vm.refData,
                );
              },
            ),
          );
        }
      },
    );
  }
}
