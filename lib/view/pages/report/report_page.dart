import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:sotong_local/component/banner/sliding_banner.dart';
import 'package:sotong_local/view/pages/report/report_widgets/report_category_budget_chart_section.dart';
import 'package:sotong_local/view/pages/report/report_widgets/report_month_category_section.dart';
import '../../../view_model/report/report_view_model.dart';

class ReportPage extends StatelessWidget {
  const ReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ReportPageContent();
  }
}

class _ReportPageContent extends StatefulWidget {
  const _ReportPageContent();

  @override
  State<_ReportPageContent> createState() => _ReportPageContentState();
}

class _ReportPageContentState extends State<_ReportPageContent> {
  bool _requestedInit = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (_requestedInit) return;
      _requestedInit = true;

      // ✅ 내 VM 기준: loadInitial()
      await context.read<ReportViewModel>().loadInitial();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReportViewModel>();

    // 로딩/에러 처리(선택)
    if (vm.isLoading && vm.budgetChart == null) {
      return const SafeArea(
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (vm.error != null && vm.budgetChart == null) {
      return SafeArea(
        child: Center(
          child: Text(
            vm.error!,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      );
    }

    // ✅ 배너 인사이트: vm.insights
    final insights = vm.insights;

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),

                  // ✅ 배너(원래 쓰던 UI 유지)
                  SlidingBanner(
                    itemCount: insights.length,
                    itemBuilder: (context, index) {
                      final insight = insights[index];
                      final Color color = insight['color'] as Color;
                      final IconData icon = insight['icon'] as IconData;
                      final String title = insight['title'] as String;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: color.withOpacity(0.25),
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(icon, color: color, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                title,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    autoSlideDuration: const Duration(seconds: 3),
                    onPageChanged: vm.setInsightIndex,
                  ),

                  const SizedBox(height: 20),
                  const ReportCategoryBudgetChartSection(),
                  const SizedBox(height: 24),

                  // ✅ MonthCategorySection은 2차니까 일단 유지
                  const ReportMonthCategorySection(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}