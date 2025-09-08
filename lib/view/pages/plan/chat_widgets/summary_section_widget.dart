import 'package:flutter/material.dart';
import './plan_summary_chart_widget.dart';
import '../plan_edit_page.dart';
import '../../../../view_model/plan/chat_plan_viewmodel.dart';

Widget buildSummarySection(BuildContext context, ChatPlanViewModel viewModel) {
  final calc = viewModel.calculationResult ?? viewModel.calculate();
  final hasNoSaving = calc != null && calc.dailyNetSaving <= 0;

  if (hasNoSaving) {
    return _buildNoSavingWarning(context, viewModel);
  } else {
    return _buildSummaryChart(context, viewModel);
  }
}

Widget _buildNoSavingWarning(
  BuildContext context,
  ChatPlanViewModel viewModel,
) {
  return Column(
    children: [
      const Text(
        '저축할 수 있는 금액이 없어요.\n하루 소비 한도 금액을 수정해 주세요!',
        style: TextStyle(
          color: Color(0xFFD32F2F),
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 16),
      ElevatedButton(
        onPressed: () async {
          final updatedPlan = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PlanEditPage(
                initialPlan: viewModel.planInfo,
                initialRefData: viewModel.refData,
              ),
            ),
          );
          if (updatedPlan != null) {
            viewModel.updatePlanInfo(
              planName: updatedPlan.planName,
              // purpose: updatedPlan.purpose,
              targetAmount: updatedPlan.targetAmount,
              currentAsset: updatedPlan.currentAsset,
            );
            viewModel.calculate();
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0062FF),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          '플랜 수정하기',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    ],
  );
}

Widget _buildSummaryChart(BuildContext context, ChatPlanViewModel viewModel) {
  return Column(
    children: [
      PlanSummaryChartWidget(
        planInfo: viewModel.planInfo,
        calculation: viewModel.calculationResult!,
        userName: viewModel.userName,
        onEdit: () async {
          final updatedPlan = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PlanEditPage(
                initialPlan: viewModel.planInfo,
                initialRefData: viewModel.refData,
              ),
            ),
          );
          if (updatedPlan != null) {
            viewModel.updatePlanInfo(
              planName: updatedPlan.planName,
              // purpose: updatedPlan.purpose,
              targetAmount: updatedPlan.targetAmount,
              currentAsset: updatedPlan.currentAsset,
            );
            viewModel.calculate();
          }
        },
      ),
      const SizedBox(height: 16),
    ],
  );
}
