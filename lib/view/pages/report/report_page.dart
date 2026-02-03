// lib/view/pages/report/report_page.dart

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
    // 이미 main 에서 ReportViewModel 주입됨
    return const _ReportPageContent();
  }
}

class _ReportPageContent extends StatefulWidget {
  const _ReportPageContent();

  @override
  State<_ReportPageContent> createState() => _ReportPageContentState();
}

class _ReportPageContentState extends State<_ReportPageContent> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final vm = context.read<ReportViewModel>();
      if (!vm.hasData) await vm.loadInitial();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReportViewModel>();

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
                  SlidingBanner(
                    itemCount: vm.insights.length,
                    itemBuilder: (context, index) {
                      final insight = vm.insights[index];
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
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
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
