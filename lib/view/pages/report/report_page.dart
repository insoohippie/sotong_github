// lib/view/pages/report/report_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:sotong_local/view/pages/report/report_widgets/report_category_budget_chart_section.dart';
import 'package:sotong_local/view/pages/report/report_widgets/report_month_category_section.dart';
import '../../../view_model/report/report_view_model.dart';

/// 1) 여기서 ReportViewModel 을 제공
class ReportPage extends StatelessWidget {
  const ReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ReportViewModel(),
      child: const _ReportPageContent(),
    );
  }
}

/// 2) 실제 UI + 인사이트 배너 / 섹션들
class _ReportPageContent extends StatefulWidget {
  const _ReportPageContent({super.key});

  @override
  State<_ReportPageContent> createState() => _ReportPageContentState();
}

class _ReportPageContentState extends State<_ReportPageContent> {
  late PageController _pageController;
  Timer? _autoSlideTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    /// Provider 가 이미 위에 있으니, 첫 프레임 이후에 vm 받아서 자동 슬라이드 시작
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final vm = context.read<ReportViewModel>();
      _startAutoSlide(vm);
    });
  }

  void _startAutoSlide(ReportViewModel vm) {
    _autoSlideTimer?.cancel();
    if (vm.insights.isEmpty) return;

    _autoSlideTimer =
        Timer.periodic(const Duration(seconds: 3), (Timer timer) {
          if (!_pageController.hasClients || vm.insights.isEmpty) return;

          final next =
              (vm.currentInsightIndex + 1) % vm.insights.length;

          _pageController.animateToPage(
            next,
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
          );
          vm.setInsightIndex(next);
        });
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  String _formatAmount(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
    );
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
                  /// 🔹 인사이트 배너 (테스트 파일의 AppBar 역할)
                  SizedBox(
                    height: 44,
                    child: PageView.builder(
                      controller: _pageController,
                      scrollDirection: Axis.vertical,
                      onPageChanged: vm.setInsightIndex,
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
                    ),
                  ),

                  const SizedBox(height: 16),

                  /// 🔹 첫 번째 카드: 월 / 카테고리 선택 + 금액 애니메이션
                  const ReportMonthCategorySection(),

                  const SizedBox(height: 24),

                  /// 🔹 두 번째 카드: 카테고리별 예산 차트
                  const ReportCategoryBudgetChartSection(),

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
