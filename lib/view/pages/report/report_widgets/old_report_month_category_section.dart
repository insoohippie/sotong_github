import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animated_toggle_switch/animated_toggle_switch.dart';

import '../../../../component/theme/app_colors.dart';
import '../../../../view_model/report/report_view_model.dart';

class ReportMonthCategorySection extends StatefulWidget {
  const ReportMonthCategorySection({super.key});

  @override
  State<ReportMonthCategorySection> createState() =>
      _ReportMonthCategorySectionState();
}

class _ReportMonthCategorySectionState extends State<ReportMonthCategorySection> {
  late final PageController _pageController;

  int _tabIndex = 0; // 0..3

  int _savingPrev = 0;
  int _incomePrev = 0;
  int _fixedPrev = 0;
  int _variablePrev = 0;

  bool _prevLoading = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _tabIndex);

    final vm = context.read<ReportViewModel>();
    _savingPrev = vm.savingTotal;
    _incomePrev = vm.incomeTotal;
    _fixedPrev = vm.fixedExpenseTotal;
    _variablePrev = vm.variableExpenseTotal;
    _prevLoading = vm.isLoading;
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

  void _syncPrevValuesAfterLoad(ReportViewModel vm) {
    if (_prevLoading && !vm.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _savingPrev = vm.savingTotal;
          _incomePrev = vm.incomeTotal;
          _fixedPrev = vm.fixedExpenseTotal;
          _variablePrev = vm.variableExpenseTotal;
        });
      });
    }
    _prevLoading = vm.isLoading;
  }

  void _jumpToTab(int index) {
    if (_tabIndex == index) return;
    setState(() => _tabIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReportViewModel>();
    _syncPrevValuesAfterLoad(vm);

    final items = <_MoneyTab>[
      _MoneyTab(
        label: '저축',
        icon: Icons.savings_outlined,
        prev: _savingPrev,
        value: vm.savingTotal,
      ),
      _MoneyTab(
        label: '수입',
        icon: Icons.payments_outlined,
        prev: _incomePrev,
        value: vm.incomeTotal,
      ),
      _MoneyTab(
        label: '고정소비',
        icon: Icons.receipt_long_outlined,
        prev: _fixedPrev,
        value: vm.fixedExpenseTotal,
      ),
      _MoneyTab(
        label: '변동소비',
        icon: Icons.shopping_bag_outlined,
        prev: _variablePrev,
        value: vm.variableExpenseTotal,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
            child: Column(
              children: [
                _buildMonthSelector(vm),
                const SizedBox(height: 14),
                _buildToggle(items),
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
                setState(() => _tabIndex = i);
              },
              itemBuilder: (context, index) {
                final t = items[index];
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 18),
                  child: _MoneySlideCard(
                    title: '${t.label}',
                    icon: t.icon,
                    from: t.prev,
                    to: t.value,
                    format: _formatAmount,
                    isLoading: vm.isLoading,
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

  Widget _buildToggle(List<_MoneyTab> items) {
    Widget iconBuilder(int i) {
      final tab = items[i];
      final selected = i == _tabIndex;

      return Center(
        child: Icon(
          tab.icon,
          size: 20,
          color: selected ? Colors.white : Colors.grey[600],
        ),
      );
    }

    return AnimatedToggleSwitch<int>.size(
      current: _tabIndex,
      values: const [0, 1, 2, 3],
      indicatorSize: const Size.fromWidth(74),
      borderWidth: 0,
      // style: ToggleStyle(
      //   // borderColor: Colors.grey[300]!,
      //   // borderRadius: BorderRadius.circular(999),
      //   // indicatorBorderRadius: BorderRadius.circular(999),
      // ),
      styleBuilder: (i) => ToggleStyle(
        backgroundColor: Colors.grey[100]!,
        indicatorColor: AppColors.primary,
      ),
      iconBuilder: iconBuilder,
      onChanged: (i) => _jumpToTab(i),
    );
  }

}

/* ───────────────── internal models/widgets ───────────────── */

class _MoneyTab {
  final String label;
  final IconData icon;
  final int prev;
  final int value;

  _MoneyTab({
    required this.label,
    required this.icon,
    required this.prev,
    required this.value,
  });
}

class _MoneySlideCard extends StatelessWidget {
  const _MoneySlideCard({
    required this.title,
    required this.icon,
    required this.from,
    required this.to,
    required this.format,
    required this.isLoading,
  });

  final String title;
  final IconData icon;
  final int from;
  final int to;
  final String Function(int) format;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                if (isLoading)
                  Container(
                    height: 18,
                    width: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(999),
                    ),
                  )
                else
                  TweenAnimationBuilder<int>(
                    key: ValueKey('${title}_${to}_${from}'),
                    tween: IntTween(begin: from, end: to),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) {
                      return FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${format(value)}원',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Colors.black87,
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
