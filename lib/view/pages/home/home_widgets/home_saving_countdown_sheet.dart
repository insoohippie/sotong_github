import 'package:flutter/material.dart';
import 'package:sotong_local/view_model/home/home_view_model.dart';
import 'package:sotong_local/view_model/services/saving_calculator.dart';

class HomeSavingCountdownSheet extends StatefulWidget {
  const HomeSavingCountdownSheet({
    super.key,
    required this.vm,
    required this.planPercent,
    required this.userPercent,
  });

  final HomeViewModel vm;
  final int planPercent;
  final int userPercent;

  @override
  State<HomeSavingCountdownSheet> createState() =>
      _HomeSavingCountdownSheetState();
}

class _HomeSavingCountdownSheetState extends State<HomeSavingCountdownSheet> {
  // ✅ 진행률 블록 입력 상태(원본 HomeCopyPage와 동일 컨셉)
  int _inputProgressPercent = 0;
  int _appliedProgressPercent = 40;

  int _inputYellowLinePercent = 40;
  int _appliedYellowLinePercent = 40;

  late final TextEditingController _progressInputController;
  late final TextEditingController _yellowLineInputController;

  @override
  void initState() {
    super.initState();
    _progressInputController = TextEditingController(
      text: _appliedProgressPercent.toString(),
    );
    _yellowLineInputController = TextEditingController(
      text: _appliedYellowLinePercent.toString(),
    );
  }

  @override
  void dispose() {
    _progressInputController.dispose();
    _yellowLineInputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.vm;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Container(
          color: Colors.white,
          child: Column(
            children: [
              // 헤더(닫기)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Column(
                    children: [
                      _CountdownHeader(vm: vm),
                      const SizedBox(height: 24),

                      _GoalPaceContainer(
                        planPercent: widget.planPercent,
                        userPercent: widget.userPercent,
                      ),
                      const SizedBox(height: 24),

                      // ✅ 여기! 스샷 블록 추가
                      _buildProgressBarCard(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ 스샷에 있는 “저축 목표 진행률” 카드
  Widget _buildProgressBarCard() {
    final progressPercentText = '${_appliedProgressPercent.toString()}%';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목 + 날짜
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '저축 목표 진행률',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Builder(
                builder: (context) {
                  final yesterday =
                  DateTime.now().subtract(const Duration(days: 1));
                  final dateText =
                      '${yesterday.year.toString().substring(2)}.'
                      '${yesterday.month.toString().padLeft(2, '0')}.'
                      '${yesterday.day.toString().padLeft(2, '0')}일자 기준';
                  return Text(
                    dateText,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF777777)),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 진행 바 + 노란선
          LayoutBuilder(
            builder: (context, constraints) {
              final barWidth = constraints.maxWidth;
              final yellowPos = (_appliedYellowLinePercent / 100.0).clamp(0.0, 1.0);
              final yellowX = barWidth * yellowPos;

              const tolerance = 0.01;
              final threshold = yellowPos - tolerance;

              final inputProgress = (_appliedProgressPercent / 100.0).clamp(0.0, 1.0);
              final isBlue = inputProgress > threshold;

              final graphColor =
              isBlue ? const Color(0xFF0062FF) : const Color(0xFFFF6B6B);

              return Stack(
                children: [
                  Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: inputProgress,
                    child: Container(
                      height: 12,
                      decoration: BoxDecoration(
                        color: graphColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                  Positioned(
                    left: yellowX - 1,
                    top: -4,
                    child: Container(
                      width: 2,
                      height: 20,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFC107),
                        borderRadius: BorderRadius.circular(1),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFC107).withOpacity(0.5),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 16),

          // 입력 + 적용 영역(스샷과 동일 구성)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 기준선 입력
              SizedBox(
                width: 80,
                child: TextField(
                  controller: _yellowLineInputController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: '기준선',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide:
                      const BorderSide(color: Color(0xFFFFC107), width: 2),
                    ),
                    contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onChanged: (v) {
                    final num = int.tryParse(v);
                    if (num != null) {
                      setState(() => _inputYellowLinePercent = num.clamp(0, 100));
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),

              // 기준선 적용
              InkWell(
                onTap: () {
                  final input = int.tryParse(_yellowLineInputController.text);
                  if (input != null && input >= 0 && input <= 100) {
                    setState(() => _appliedYellowLinePercent = input);
                  }
                },
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFC107),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    '적용',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // 그래프 입력
              SizedBox(
                width: 80,
                child: TextField(
                  controller: _progressInputController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: '그래프',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide:
                      const BorderSide(color: Color(0xFF0062FF), width: 2),
                    ),
                    contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onChanged: (v) {
                    final num = int.tryParse(v);
                    if (num != null) {
                      setState(() => _inputProgressPercent = num.clamp(0, 100));
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),

              // 그래프 적용
              InkWell(
                onTap: () {
                  final input = int.tryParse(_progressInputController.text);
                  if (input != null && input >= 0 && input <= 100) {
                    setState(() => _appliedProgressPercent = input);
                  }
                },
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0062FF),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    '적용',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 하단 문구(스샷처럼)
          Row(
            children: [
              Builder(
                builder: (_) {
                  final diff = (_appliedProgressPercent - _appliedYellowLinePercent).abs();
                  final isAhead = _appliedProgressPercent >= _appliedYellowLinePercent;

                  final dotColor = isAhead
                      ? const Color(0xFF0062FF)
                      : const Color(0xFFFF6B6B);

                  final text = isAhead
                      ? '플랜보다 ${diff}일 빨라요'
                      : '플랜보다 ${diff}일 느려요';

                  return Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Text(text, style: const TextStyle(fontSize: 12, color: Color(0xFF777777))),
                    ],
                  );
                },
              )
            ],
          ),

          // (선택) 진행률 텍스트가 필요하면:
          // const SizedBox(height: 8),
          // Text('현재: $progressPercentText'),
        ],
      ),
    );
  }
}


class _CountdownHeader extends StatelessWidget {
  const _CountdownHeader({required this.vm});
  final HomeViewModel vm;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: vm.secondTick,
      builder: (_, __, ___) {
        final remain = vm.liveRemaining ?? Duration.zero;
        final clamped = remain.isNegative ? Duration.zero : remain;

        final days = clamped.inDays;
        final hours = clamped.inHours % 24;
        final minutes = clamped.inMinutes % 60;
        final seconds = clamped.inSeconds % 60;

        String two(int v) => v.toString().padLeft(2, '0');

        return Column(
          children: [
            Text(
              '$days일 ${two(hours)}:${two(minutes)}:${two(seconds)}',
              style: const TextStyle(
                fontFamily: 'RobotoMono',
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              '1초마다 ${vm.perSecondSaving}원이 증가해요',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        );
      },
    );
  }
}

class _GoalPaceContainer extends StatelessWidget {
  const _GoalPaceContainer({required this.planPercent, required this.userPercent});
  final int planPercent;
  final int userPercent;

  @override
  Widget build(BuildContext context) {
    final diff = (planPercent - userPercent).abs();
    final isUserLarger = userPercent > planPercent;

    const targetAmount = 5000000.0;
    final amountDiff = (diff / 100.0) * targetAmount;
    const totalDays = 180;
    final daysDiff = (diff / 100.0) * totalDays;

    String amountText;
    Color amountColor;
    if (isUserLarger) {
      amountText = '${SavingPlanCalculator.formatAmount(amountDiff)}원 더 모았어요!';
      amountColor = const Color(0xFF0062FF);
    } else if (planPercent > userPercent) {
      amountText = '${SavingPlanCalculator.formatAmount(amountDiff)}원 부족해요!';
      amountColor = const Color(0xFFFF6B6B);
    } else {
      amountText = '목표 달성!';
      amountColor = const Color(0xFF4CAF50);
    }

    String daysText;
    Color daysColor;
    if (isUserLarger) {
      daysText = '${daysDiff.round()}일 빨라요!';
      daysColor = const Color(0xFF0062FF);
    } else if (planPercent > userPercent) {
      daysText = '${daysDiff.round()}일 느려요!';
      daysColor = const Color(0xFFFF6B6B);
    } else {
      daysText = '목표 달성!';
      daysColor = const Color(0xFF4CAF50);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              _YellowDot(),
              SizedBox(width: 8),
              Text('목표 페이스', style: TextStyle(fontSize: 12, color: Color(0xFF777777), fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    const Text('💰', style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 4),
                    const Text('금액', style: TextStyle(fontSize: 11, color: Color(0xFF777777))),
                    const SizedBox(height: 4),
                    Text(amountText, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: amountColor)),
                  ],
                ),
              ),
              Container(width: 1, height: 50, color: Colors.grey[300]),
              Expanded(
                child: Column(
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: Color(0xFFFF5F5F)),
                    const SizedBox(height: 4),
                    const Text('일수', style: TextStyle(fontSize: 11, color: Color(0xFF777777))),
                    const SizedBox(height: 4),
                    Text(daysText, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: daysColor)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _YellowDot extends StatelessWidget {
  const _YellowDot();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(color: Color(0xFFFFC107), shape: BoxShape.circle),
    );
  }
}
