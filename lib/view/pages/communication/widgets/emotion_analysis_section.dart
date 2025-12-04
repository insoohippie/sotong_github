import 'package:flutter/material.dart';

import '../../../../view_model/communication/communication_view_model.dart';

class EmotionAnalysisSection extends StatefulWidget {
  const EmotionAnalysisSection({super.key, required this.vm});

  final CommunicationViewModel vm;

  @override
  State<EmotionAnalysisSection> createState() =>
      _EmotionAnalysisSectionState();
}

class _EmotionAnalysisSectionState extends State<EmotionAnalysisSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _amountController;
  late Animation<double> _amountAnimation;
  int _previousAmount = 0;
  int _currentAmount = 0;

  bool isEmotionDropdownOpen = false;

  @override
  void initState() {
    super.initState();
    _amountController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    final vm = widget.vm;
    _currentAmount = vm.emotionSpendingAmount(
      vm.selectedEmotionForAnalysis,
      vm.selectedAnalysisPeriod,
    );
    _previousAmount = _currentAmount;

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
          (m) => '${m[1]},',
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.vm;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 타이틀 + 주간/월간 토글
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '감정별 소비 분석',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    _buildPeriodToggle(vm),
                  ],
                ),
                const SizedBox(height: 20),

                // 감정 드롭다운 + 금액 애니메이션
                Row(
                  children: [
                    SizedBox(
                      width: 150,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            isEmotionDropdownOpen = !isEmotionDropdownOpen;
                          });
                        },
                        child: Container(
                          height: 60,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: const Color(0xFFE0E0E0),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Text(
                                vm.emotionEmojiForAnalysis(
                                  vm.selectedEmotionForAnalysis,
                                ),
                                style: const TextStyle(fontSize: 18),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  vm.selectedEmotionForAnalysis,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Icon(
                                isEmotionDropdownOpen
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                                size: 20,
                                color: Colors.black.withOpacity(0.7),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: AnimatedBuilder(
                        animation: _amountAnimation,
                        builder: (context, child) {
                          return Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  _formatAmount(
                                    _amountAnimation.value.toInt(),
                                  ),
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '원',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(height: isEmotionDropdownOpen ? 220 : 12),
              ],
            ),

            // 드롭다운 레이어
            if (isEmotionDropdownOpen)
              Positioned(
                top: 92,
                left: 0,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: 165,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: const Color(0xFFE0E0E0),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 14,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildEmotionOption(vm, '기쁨', isFirst: true),
                        _buildEmotionOption(vm, '혼란'),
                        _buildEmotionOption(vm, '슬픔'),
                        _buildEmotionOption(vm, '피곤'),
                        _buildEmotionOption(vm, '화남'),
                        _buildEmotionOption(vm, '플렉스', isLast: true),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmotionOption(
      CommunicationViewModel vm,
      String emotion, {
        bool isFirst = false,
        bool isLast = false,
      }) {
    final isSelected = vm.selectedEmotionForAnalysis == emotion;

    return InkWell(
      onTap: () {
        vm.setAnalysisEmotion(emotion);
        setState(() {
          isEmotionDropdownOpen = false;
        });
        final newAmount = vm.emotionSpendingAmount(
          vm.selectedEmotionForAnalysis,
          vm.selectedAnalysisPeriod,
        );
        _animateAmount(newAmount);
      },
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(isFirst ? 22 : 0),
        topRight: Radius.circular(isFirst ? 22 : 0),
        bottomLeft: Radius.circular(isLast ? 22 : 0),
        bottomRight: Radius.circular(isLast ? 22 : 0),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(isFirst ? 22 : 0),
            topRight: Radius.circular(isFirst ? 22 : 0),
            bottomLeft: Radius.circular(isLast ? 22 : 0),
            bottomRight: Radius.circular(isLast ? 22 : 0),
          ),
          color: isSelected ? const Color(0xFFE9F2FF) : Colors.white,
          border: Border(
            bottom: BorderSide(
              color: isLast ? Colors.transparent : const Color(0xFFE5E5E8),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Text(
              emotion,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isSelected ? const Color(0xFF0D6EFF) : Colors.black,
              ),
            ),
            const Spacer(),
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF0D6EFF)
                      : const Color(0xFFD3D3D6),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Container(
                margin: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF0D6EFF),
                ),
              )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodToggle(CommunicationViewModel vm) {
    const periods = ['주간', '월간'];
    final selectedIndex = periods.indexOf(vm.selectedAnalysisPeriod);

    Alignment _alignmentForIndex(int index) {
      switch (index) {
        case 0:
          return Alignment.centerLeft;
        case 1:
          return Alignment.centerRight;
        default:
          return Alignment.centerLeft;
      }
    }

    return Container(
      width: 100,
      height: 28,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            alignment: _alignmentForIndex(selectedIndex),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
              child: Container(
                width: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: List.generate(periods.length, (index) {
              final period = periods[index];
              final isSelected = vm.selectedAnalysisPeriod == period;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (vm.selectedAnalysisPeriod == period) return;
                    vm.setAnalysisPeriod(period);
                    final newAmount = vm.emotionSpendingAmount(
                      vm.selectedEmotionForAnalysis,
                      vm.selectedAnalysisPeriod,
                    );
                    _animateAmount(newAmount);
                  },
                  child: Center(
                    child: Text(
                      period,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color:
                        isSelected ? Colors.black87 : Colors.grey[600],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
