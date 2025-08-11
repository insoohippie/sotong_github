import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import './chat_widgets/input_modal_widget.dart';
import '../../../model/entry.dart';
import '../../../model/plan_info.dart';
import '../../../model/ref_data.dart';
import '../../../view_model/plan/plan_edit_viewmodel.dart';

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
  void _save(PlanEditViewModel viewModel) {
    print('=== 저장 버튼 클릭됨 ===');
    print('현재 context: $context');
    print('현재 mounted: $mounted');

    // 폼 검증
    final validationError = viewModel.getValidationError();
    if (validationError != null) {
      print('검증 오류: $validationError');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validationError), backgroundColor: Colors.red),
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

  Widget _sectionTitle(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 24),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF3B82F6)),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _minimalField(
    String label,
    TextEditingController controller, {
    bool isNumber = false,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: const TextStyle(fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          filled: true,
          fillColor: const Color(0xFFF6F8FA),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _purposeDropdown(PlanEditViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: DropdownButtonFormField<String>(
        value: viewModel.selectedPurpose,
        items: viewModel.purposeOptions
            .map((p) => DropdownMenuItem(value: p, child: Text(p)))
            .toList(),
        onChanged: (val) => viewModel.updateSelectedPurpose(val),
        decoration: InputDecoration(
          labelText: '플랜 목적',
          filled: true,
          fillColor: const Color(0xFFF6F8FA),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _editSummaryTile(
    String label,
    double total,
    VoidCallback onEdit, {
    String? unit,
    String? subtitle,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 0,
      color: const Color(0xFFF6F8FA),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: subtitle != null
            ? Text(subtitle)
            : Text('${total.toStringAsFixed(0)}${unit ?? '원'}'),
        trailing: TextButton(
          onPressed: onEdit,
          child: const Text(
            '세부 수정',
            style: TextStyle(color: Color(0xFF3B82F6)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => PlanEditViewModel(
        widget.initialPlan,
        initialRefData: widget.initialRefData,
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('플랜 정보 수정'),
          backgroundColor: const Color(0xFF3B82F6),
          elevation: 0,
        ),
        body: Consumer<PlanEditViewModel>(
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
                    hintText: '예: 월세, 통신비, 구독료 등',
                    type: EntryType.fixed,
                    initialEntries: viewModel.refData.fixedConsumptions,
                    // 기존 데이터 전달
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
                    title: '하루 소비 한도 항목 수정',
                    placeholder: '소비 항목',
                    hintText: '예: 식비, 여가비 등',
                    type: EntryType.daily,
                    initialEntries: viewModel.refData.dailyConsumptions,
                    // 기존 데이터 전달
                    onComplete: (items, total) {
                      viewModel.updateDailyCostEntries(items);
                    },
                  );
                },
              );
            }

            return Center(
              child: Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 24,
                ),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 24,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle('기본 정보', Icons.info_outline),
                        _minimalField(
                          '플랜 이름',
                          viewModel.planNameController,
                          hint: '예: 여름휴가 프로젝트',
                        ),
                        _purposeDropdown(viewModel),
                        _minimalField(
                          '목표 금액',
                          viewModel.targetAmountController,
                          isNumber: true,
                          hint: '예: 1000000',
                        ),
                        _minimalField(
                          '보유 자산',
                          viewModel.currentAssetController,
                          isNumber: true,
                          hint: '예: 500000',
                        ),
                        _sectionTitle('월별 정보', Icons.calendar_today),
                        _editSummaryTile(
                          '월 수입',
                          viewModel.monthlyIncome,
                          editIncome,
                          unit: null,
                          // 리스트 내용 추가
                          subtitle: viewModel.refData.fixedIncomes.isNotEmpty
                              ? viewModel.refData.fixedIncomes
                                    .map(
                                      (e) =>
                                          '${e.category}: ${e.amount.toStringAsFixed(0)}원',
                                    )
                                    .join(', ')
                              : '항목 없음',
                        ),
                        _editSummaryTile(
                          '고정 소비',
                          viewModel.monthlyFixedCost,
                          editFixedCost,
                          unit: null,
                          subtitle:
                              viewModel.refData.fixedConsumptions.isNotEmpty
                              ? viewModel.refData.fixedConsumptions
                                    .map(
                                      (e) =>
                                          '${e.category}: ${e.amount.toStringAsFixed(0)}원',
                                    )
                                    .join(', ')
                              : '항목 없음',
                        ),
                        _editSummaryTile(
                          '하루 소비 한도 금액',
                          viewModel.dailySpendingLimit,
                          editDailySpending,
                          unit: null,
                          subtitle:
                              viewModel.refData.dailyConsumptions.isNotEmpty
                              ? viewModel.refData.dailyConsumptions
                                    .map(
                                      (e) =>
                                          '${e.category}: ${e.amount.toStringAsFixed(0)}원',
                                    )
                                    .join(', ')
                              : '항목 없음',
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: viewModel.isValidForm()
                                ? () => _save(viewModel)
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: viewModel.isValidForm()
                                  ? const Color(0xFF3B82F6)
                                  : const Color(0xFFD1D5DB),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              '저장',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
