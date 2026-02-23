import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animated_toggle_switch/animated_toggle_switch.dart';

import '../../../../component/buttons/multi_option_toggle.dart';
import '../../../../component/inputs/month_selector_row.dart';
import '../../../../component/theme/app_colors.dart';
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

  int _tabIndex = 3; // 0..3

  int _shownAmount = 0; // 지금 화면에 보여준 금액
  int _shownFromAmount = 0; // 애니메이션 begin용

  bool _prevLoading = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _tabIndex);

    final vm = context.read<ReportViewModel>();
    final itemsInit = [
      vm.savingTotal,
      vm.incomeTotal,
      vm.fixedExpenseTotal,
      vm.variableExpenseTotal,
    ];

    _shownAmount = itemsInit[_tabIndex];
    _shownFromAmount = _shownAmount;
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

  void _jumpToTab(int index, List<_MoneyTab> items) {
    if (_tabIndex == index) return;
    final newTo = items[index].value;

    setState(() {
      _shownFromAmount = _shownAmount;
      _shownAmount = newTo;
      _tabIndex = index;
    });

    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReportViewModel>();

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

    final nowLoading = vm.isLoading;

    if (_prevLoading && !nowLoading) {
      final newTo = items[_tabIndex].value;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        // 이미 같은 값이면 스킵
        if (_shownAmount == newTo) return;

        setState(() {
          _shownFromAmount = _shownAmount;
          _shownAmount = newTo;
        });
      });
    }

    _prevLoading = nowLoading;

    final theme = Theme.of(context);

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
          // Padding(
          //   padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
          //   child: Column(
          //     children: [
          //       _buildMonthSelector(vm),
          //       const SizedBox(height: 14),
          //       _buildToggleWithLabels(items),
          //     ],
          //   ),
          // ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
            child: Column(
              children: [
                MonthSelectorRow(
                  month: vm.selectedMonth,
                  onPrev: () => vm.changeMonth(-1),
                  onNext: () => vm.changeMonth(1),
                ),
                const SizedBox(height: 14),

                Align(
                  alignment: Alignment.centerRight,
                  child: _buildToggleWithLabels(items),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 120,
            child: PageView.builder(
              controller: _pageController,
              itemCount: items.length,
              onPageChanged: (i) {
                if (!mounted) return;
                if (vm.isLoading) return;
                final newTo = items[i].value;
                setState(() {
                  _shownFromAmount = _shownAmount;
                  _shownAmount = newTo;
                  _tabIndex = i;
                });
              },
              itemBuilder: (context, index) {
                final t = items[index];
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 18),
                  child: _MoneySlideCard(
                    title: items[_tabIndex].label,
                    icon: items[_tabIndex].icon,
                    from: _shownFromAmount,
                    to: _shownAmount,
                    format: _formatAmount,
                    isLoading: vm.isLoading,
                    tabIndex: _tabIndex,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector(ReportViewModel vm) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () => vm.changeMonth(-1),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(Icons.chevron_left, size: 20, color: Colors.grey[700]),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${vm.selectedMonth}월',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () => vm.changeMonth(1),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(Icons.chevron_right, size: 20, color: Colors.grey[700]),
          ),
        ),
      ],
    );
  }

  // Widget _buildToggleWithLabels(List<_MoneyTab> items) {
  //   const double cellW = 74;
  //
  //   Widget iconBuilder(int i) {
  //     final tab = items[i];
  //     final selected = i == _tabIndex;
  //     return Center(
  //       child: Icon(
  //         tab.icon,
  //         size: 20,
  //         color: selected ? Colors.white : Colors.grey[600],
  //       ),
  //     );
  //   }
  //
  //   return Column(
  //     children: [
  //       AnimatedToggleSwitch<int>.size(
  //         current: _tabIndex,
  //         values: const [0, 1, 2, 3],
  //         indicatorSize: const Size.fromWidth(cellW),
  //         borderWidth: 0,
  //         styleBuilder: (i) => ToggleStyle(
  //           backgroundColor: Colors.grey[100]!,
  //           indicatorColor: AppColors.primary,
  //         ),
  //         iconBuilder: iconBuilder,
  //         onChanged: (i) => _jumpToTab(i, items),
  //       ),
  //
  //       const SizedBox(height: 8),
  //
  //       Row(
  //         mainAxisAlignment: MainAxisAlignment.center,
  //         children: List.generate(items.length, (i) {
  //           final selected = i == _tabIndex;
  //           return SizedBox(
  //             width: cellW,
  //             child: Text(
  //               items[i].label,
  //               textAlign: TextAlign.center,
  //               maxLines: 1,
  //               overflow: TextOverflow.ellipsis,
  //               style: TextStyle(
  //                 fontSize: 12,
  //                 fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
  //                 color: selected ? Colors.black87 : Colors.grey[500],
  //               ),
  //             ),
  //           );
  //         }),
  //       ),
  //     ],
  //   );
  // }

  Widget _buildToggleWithLabels(List<_MoneyTab> items) {
    final labels = items.map((e) => e.label).toList();

    return Center(
      child: MultiOptionToggle(
        labels: labels,
        selected: labels[_tabIndex],
        width: 320,
        height: 30,
        onChanged: (label) {
          final index = labels.indexOf(label);
          if (index < 0) return;
          _jumpToTab(index, items);
        },
      ),
    );
  }
}

/* ───────────────── internal models/widgets ───────────────── */

class _MoneyTab {
  final String label;
  final IconData icon;
  final int value;

  _MoneyTab({required this.label, required this.icon, required this.value});
}

class _MoneySlideCard extends StatelessWidget {
  const _MoneySlideCard({
    required this.title,
    required this.icon,
    required this.from,
    required this.to,
    required this.format,
    required this.isLoading,
    required this.tabIndex,
  });

  final String title;
  final IconData icon;
  final int from;
  final int to;
  final String Function(int) format;
  final bool isLoading;
  final int tabIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Opacity(
                  opacity: isLoading ? 0.0 : 1.0,
                  child: TweenAnimationBuilder<int>(
                    key: ValueKey('$title-$to-$tabIndex'),
                    tween: IntTween(begin: from, end: to),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) {
                      return FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${format(value)}원',
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
