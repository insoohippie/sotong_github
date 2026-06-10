import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../component/buttons/multi_option_toggle.dart';
import '../../../../component/inputs/month_selector_row.dart';
import '../../../../view_model/report/report_view_model.dart';

class ReportMonthCategorySection extends StatefulWidget {
  const ReportMonthCategorySection({super.key});

  @override
  State<ReportMonthCategorySection> createState() =>
      _ReportMonthCategorySectionState();
}

class _ReportMonthCategorySectionState
    extends State<ReportMonthCategorySection> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();

    final initialIndex = context.read<ReportViewModel>().monthCategoryTabIndex;

    _pageController = PageController(initialPage: initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _formatAmount(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
    );
  }

  void _jumpToTab(int index) {
    final vm = context.read<ReportViewModel>();

    if (vm.monthCategoryTabIndex == index) return;

    vm.setMonthCategoryTabIndex(index);

    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReportViewModel>();
    final theme = Theme.of(context);

    final tabIndex = vm.monthCategoryTabIndex;

    final items = <_MoneyTab>[
      _MoneyTab(
        label: '저축',
        icon: Icons.savings_outlined,
        value: vm.savingTotal,
      ),
      _MoneyTab(
        label: '수입',
        icon: Icons.payments_outlined,
        value: vm.incomeTotal,
      ),
      _MoneyTab(
        label: '고정소비',
        icon: Icons.receipt_long_outlined,
        value: vm.fixedExpenseTotal,
      ),
      _MoneyTab(
        label: '변동소비',
        icon: Icons.shopping_bag_outlined,
        value: vm.variableExpenseTotal,
      ),
    ];

    final monthKey = '${vm.monthSectionYear}-${vm.monthSectionMonth}';

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              theme.brightness == Brightness.dark ? 0.2 : 0.12,
            ),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
            child: Column(
              children: [
                MonthSelectorRow(
                  month: vm.monthSectionMonth,
                  onPrev: () => vm.changeMonthSection(-1),
                  onNext: () => vm.changeMonthSection(1),
                ),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerRight,
                  child: _buildToggleWithLabels(items, tabIndex),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 76,
            child: PageView.builder(
              controller: _pageController,
              itemCount: items.length,
              onPageChanged: (i) {
                context.read<ReportViewModel>().setMonthCategoryTabIndex(i);
              },
              itemBuilder: (context, index) {
                final item = items[index];

                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
                  child: _MoneySlideCard(
                    amount: item.value,
                    monthKey: monthKey,
                    format: _formatAmount,
                    isLoading: false,
                    tabIndex: index,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleWithLabels(List<_MoneyTab> items, int tabIndex) {
    final labels = items.map((e) => e.label).toList();
    final viewWidth = MediaQuery.sizeOf(context).width;

    final toggleWidth = viewWidth <= 386
        ? 280.0
        : viewWidth < 412
        ? 300.0
        : 320.0;

    final toggleHeight = viewWidth <= 386
        ? 26.0
        : viewWidth < 412
        ? 28.0
        : 30.0;

    final toggleFontSize = viewWidth <= 386
        ? 10.0
        : viewWidth < 412
        ? 11.0
        : 12.0;

    return Center(
      child: MultiOptionToggle(
        labels: labels,
        selected: labels[tabIndex],
        width: toggleWidth,
        height: toggleHeight,
        fontSize: toggleFontSize,
        onChanged: (label) {
          final index = labels.indexOf(label);
          if (index < 0) return;
          _jumpToTab(index);
        },
      ),
    );
  }
}

class _MoneyTab {
  final String label;
  final IconData icon;
  final int value;

  _MoneyTab({
    required this.label,
    required this.icon,
    required this.value,
  });
}

class _MoneySlideCard extends StatelessWidget {
  const _MoneySlideCard({
    required this.amount,
    required this.monthKey,
    required this.format,
    required this.isLoading,
    required this.tabIndex,
  });

  final int amount;
  final String monthKey;
  final String Function(int) format;
  final bool isLoading;
  final int tabIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
      alignment: Alignment.center,
      child: Opacity(
        opacity: isLoading ? 0.4 : 1.0,
        child: TweenAnimationBuilder<int>(
          key: ValueKey('$monthKey-$tabIndex'),
          tween: IntTween(end: amount),
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) {
            return FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Text(
                '${format(value)}원',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}