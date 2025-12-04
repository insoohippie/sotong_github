//(월 선택 + 카테고리 드롭다운 + 금액 애니메이션)

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../view_model/report/report_view_model.dart';


class ReportMonthCategorySection extends StatefulWidget {
  const ReportMonthCategorySection({super.key});

  @override
  State<ReportMonthCategorySection> createState() =>
      _ReportMonthCategorySectionState();
}

class _ReportMonthCategorySectionState
    extends State<ReportMonthCategorySection>
    with SingleTickerProviderStateMixin {
  late AnimationController _amountController;
  late Animation<double> _amountAnimation;
  int _previousAmount = 0;
  int _currentAmount = 0;

  @override
  void initState() {
    super.initState();
    final vm =
    Provider.of<ReportViewModel>(context, listen: false);
    _currentAmount = vm.amountForSelectedCategory;
    _previousAmount = _currentAmount;

    _amountController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _amountAnimation = Tween<double>(
      begin: _previousAmount.toDouble(),
      end: _currentAmount.toDouble(),
    ).animate(
      CurvedAnimation(
        parent: _amountController,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _animateAmount(int newAmount) {
    setState(() {
      _previousAmount = _currentAmount;
      _currentAmount = newAmount;
      _amountAnimation = Tween<double>(
        begin: _previousAmount.toDouble(),
        end: _currentAmount.toDouble(),
      ).animate(
        CurvedAnimation(
          parent: _amountController,
          curve: Curves.easeOutCubic,
        ),
      );
      _amountController
        ..reset()
        ..forward();
    });
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

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildMonthSelector(vm),
          const SizedBox(height: 16),
          _buildCategorySelectorWithAmount(vm),
          if (vm.isCategoryDropdownOpen)
            Container(
              width: 120,
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border:
                Border.all(color: Colors.grey[300]!, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildDropdownOption(vm, '저축'),
                  _buildDropdownOption(vm, '수입'),
                  _buildDropdownOption(vm, '고정소비'),
                  _buildDropdownOption(vm, '변동소비'),
                ],
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildMonthSelector(ReportViewModel vm) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () {
            vm.changeMonth(-1);
            _animateAmount(vm.amountForSelectedCategory);
          },
          child: Container(
            padding: const EdgeInsets.all(4),
            child: Icon(Icons.chevron_left,
                size: 20, color: Colors.grey[700]),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${vm.selectedMonth}월',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () {
            vm.changeMonth(1);
            _animateAmount(vm.amountForSelectedCategory);
          },
          child: Container(
            padding: const EdgeInsets.all(4),
            child: Icon(Icons.chevron_right,
                size: 20, color: Colors.grey[700]),
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySelectorWithAmount(ReportViewModel vm) {
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: GestureDetector(
            onTap: vm.toggleCategoryDropdown,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border:
                Border.all(color: Colors.grey[300]!, width: 1),
              ),
              child: Row(
                children: [
                  Text(
                    vm.selectedCategory,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    vm.isCategoryDropdownOpen
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 18,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Center(
            child: AnimatedBuilder(
              animation: _amountAnimation,
              builder: (context, child) {
                return Text(
                  '${_formatAmount(_amountAnimation.value.toInt())}원',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownOption(
      ReportViewModel vm, String category) {
    final isSelected = vm.selectedCategory == category;
    return GestureDetector(
      onTap: () {
        vm.selectCategory(category);
        _animateAmount(vm.amountForSelectedCategory);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[50] : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          category,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.blue[700] : Colors.black87,
          ),
        ),
      ),
    );
  }
}
