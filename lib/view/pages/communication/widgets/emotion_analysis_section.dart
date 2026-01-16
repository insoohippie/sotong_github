import 'package:flutter/material.dart';

import '../../../../view_model/communication/communication_view_model.dart';

class EmotionAnalysisSection extends StatefulWidget {
  final CommunicationViewModel vm;

  const EmotionAnalysisSection({super.key, required this.vm});

  @override
  State<EmotionAnalysisSection> createState() =>
      _EmotionAnalysisSectionState();
}

class _EmotionAnalysisSectionState extends State<EmotionAnalysisSection>
    with SingleTickerProviderStateMixin {
  String emotion = '기쁨';

  late AnimationController _controller;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    final initial = widget.vm.getEmotionAmount(emotion).toDouble();
    _anim = Tween<double>(begin: initial, end: initial).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setAmount(int value) {
    final begin = _anim.value;
    _anim = Tween<double>(
      begin: begin,
      end: value.toDouble(),
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _box,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '감정별 소비 분석',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              // 감정 선택 드롭다운
              GestureDetector(
                onTap: _selectEmotion,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: _field,
                  child: Row(
                    children: [
                      Text(
                        widget.vm.getEmoji(emotion),
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        emotion,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Icon(Icons.keyboard_arrow_down, size: 18),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 20),

              // 금액 애니메이션
              Expanded(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (_, __) {
                    return Text(
                      '${_anim.value.toInt()}원',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          Text(
            '${emotion}인 날의 평균 소비는 ${widget.vm.getEmotionAmount(emotion)}원이에요.',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  void _selectEmotion() {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        final list = widget.vm.emotionList;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final e in list)
              ListTile(
                leading: Text(
                  widget.vm.getEmoji(e),
                  style: const TextStyle(fontSize: 20),
                ),
                title: Text(e),
                onTap: () {
                  setState(() {
                    emotion = e;
                    _setAmount(widget.vm.getEmotionAmount(e));
                  });
                  Navigator.pop(context);
                },
              ),
          ],
        );
      },
    );
  }

  BoxDecoration get _box => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: const [
      BoxShadow(
        color: Colors.black12,
        blurRadius: 8,
      ),
    ],
  );

  BoxDecoration get _field => BoxDecoration(
    color: Colors.grey[100],
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: Colors.grey[300]!),
  );
}
