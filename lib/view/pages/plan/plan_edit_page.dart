import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sotong_local/view/pages/plan/plan_edit_widgets/edit_summary_tile.dart';
import 'package:sotong_local/view/pages/plan/plan_edit_widgets/minimal_field.dart';

import '../../../component/appbars/custom_app_bar.dart';
import '../../../component/containers/rounded_info_container.dart';
import '../../../component/texts/section_title.dart';
import '../../../component/theme/app_colors.dart';
import '../../../component/theme/app_spacing.dart';
import './chat_widgets/input_modal_widget.dart';
import '../../../model/entry.dart';
import '../../../model/plan_info.dart';
import '../../../model/ref_data.dart';
import '../../../view_model/plan/plan_edit_viewmodel.dart';
import '../../../component/appbars/custom_app_bar_title_subtitle.dart';
import '../../../component/inputs/custom_text_field.dart';
import '../../../component/buttons/custom_button.dart';
import '../../../component/texts/header_text.dart';
import '../../../component/texts/paragraph_text.dart';
import '../../../component/texts/subtext.dart';
import 'package:intl/intl.dart';

class PlanEditPage extends StatefulWidget {
  final PlanInfo initialPlan;
  final RefData initialRefData;

  const PlanEditPage({
    Key? key,
    required this.initialPlan,
    required this.initialRefData,
  }) : super(key: key);

  @override
  State<PlanEditPage> createState() => _PlanEditPageState();
}

class _PlanEditPageState extends State<PlanEditPage> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => PlanEditViewModel(
        widget.initialPlan,
        initialRefData: widget.initialRefData,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Consumer<PlanEditViewModel>(
            builder: (context, viewModel, child) {
              // Edit functions moved inside Consumer
              void editIncome() async {
                await showDialog(
                  context: context,
                  builder: (ctx) {
                    return InputModalWidget(
                      isOpen: true,
                      onClose: () => Navigator.of(ctx).pop(),
                      title: '월 수입 항목 수정',
                      placeholder: '수입 카테고리',
                      hintText: '예: 월급, 아르바이트, 용돈 등',
                      type: EntryType.fixed,
                      initialEntries: viewModel.refData.fixedIncomes,
                      // 기존 데이터 전달
                      onComplete: (items, total) {
                        viewModel.updateFixedIncomeEntries(items);
                      },
                    );
                  },
                );
              }

              void editFixedCost() async {
                await showDialog(
                  context: context,
                  builder: (ctx) {
                    return InputModalWidget(
                      isOpen: true,
                      onClose: () => Navigator.of(ctx).pop(),
                      title: '고정 소비 항목 수정',
                      placeholder: '고정 지출 항목',
                      hintText: '예: 월세, 핸드폰 요금, 보험료 등',
                      type: EntryType.fixed,
                      initialEntries: viewModel.refData.fixedConsumptions,
                      onComplete: (items, total) {
                        viewModel.updateFixedCostEntries(items);
                      },
                    );
                  },
                );
              }

              void editDailySpending() async {
                await showDialog(
                  context: context,
                  builder: (ctx) {
                    return InputModalWidget(
                      isOpen: true,
                      onClose: () => Navigator.of(ctx).pop(),
                      title: '하루 소비 한도 금액 수정',
                      placeholder: '소비 항목',
                      hintText: '예: 커피값, 점심값, 택시비 등',
                      type: EntryType.daily,
                      initialEntries: viewModel.refData.dailyConsumptions,
                      onComplete: (items, total) {
                        viewModel.updateDailyCostEntries(items);
                      },
                    );
                  },
                );
              }

              return Column(
                children: [
                  CustomAppBar(
                    title: '플랜 정보 수정',
                    onBack: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenPadding,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          MinimalField(
                            label: '플랜 이름',
                            controller: viewModel.planNameController,
                            hint: '예: 여름휴가 프로젝트',
                            onChanged: (_) =>
                                setState(() {}), // 기존 setState 유지 원하면
                          ),
                          MinimalField(
                            label: '플랜 목적',
                            dropdownOptions: viewModel.purposeOptions,
                            selectedValue: viewModel.selectedPurpose,
                            onDropdownChanged: (val) =>
                                viewModel.updateSelectedPurpose(val),
                          ),
                          MinimalField(
                            label: '목표 금액',
                            controller: viewModel.targetAmountController,
                            isNumber: true,
                            hint: '예: 1000000',
                            onChanged: (_) => setState(() {}),
                          ),

                          MinimalField(
                            label: '보유 자산',
                            controller: viewModel.currentAssetController,
                            isNumber: true,
                            hint: '예: 500000',
                            onChanged: (_) => setState(() {}),
                          ),
                          EditSummaryTile(
                            label: '월 수입',
                            total: viewModel.monthlyIncome,
                            onEdit: editIncome,
                            // subtitle: '세부 항목을 확인하세요', // 필요 시
                          ),

                          EditSummaryTile(
                            label: '고정 소비',
                            total: viewModel.monthlyFixedCost,
                            onEdit: editFixedCost,
                          ),

                          EditSummaryTile(
                            label: '하루 소비 한도 금액',
                            total: viewModel.dailySpendingLimit,
                            onEdit: editDailySpending,
                            unit: '원',
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  CustomButton(
                    text: '저장',
                    onPressed: viewModel.isValidForm()
                        ? () => _save(viewModel)
                        : () {},
                    enabled: viewModel.isValidForm(),
                  ),
                  const SizedBox(height: 40),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _save(PlanEditViewModel viewModel) {
    print('=== 저장 버튼 클릭됨 ===');
    print('현재 context: $context');
    print('현재 mounted: $mounted');

    // 폼 검증
    final validationError = viewModel.getValidationError();
    if (validationError != null) {
      print('검증 오류: $validationError');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validationError),
          backgroundColor: AppColors.redText,
        ),
      );
      return;
    }

    print('검증 통과, 업데이트된 플랜 생성 중...');
    final updated = viewModel.createUpdatedPlan(widget.initialPlan);
    print(
      '업데이트된 플랜: ${updated.planName}, ${updated.purpose}, ${updated.targetAmount}',
    );

    print('Navigator.pop 호출 중...');
    print('현재 Navigator: ${Navigator.of(context)}');
    print('현재 context: $context');

    try {
      Navigator.of(context).pop(updated);
      print('Navigator.pop 완료');
    } catch (e) {
      print('Navigator.pop 에러: $e');
    }
  }
}
