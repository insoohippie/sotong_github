import 'dart:async';
import 'package:flutter/material.dart';

class InsightBanner extends StatefulWidget {
  const InsightBanner({super.key});

  @override
  State<InsightBanner> createState() => _InsightBannerState();
}

class _InsightBannerState extends State<InsightBanner> {
  late final PageController _controller;
  Timer? _timer;

  final List<Map<String, dynamic>> insights = [
    {
      "icon": Icons.mood,
      "text": "행복할 때 소비가 증가해요",
      "color": Colors.green,
    },
    {
      "icon": Icons.shopping_bag,
      "text": "스트레스 받으면 쇼핑이 늘어요",
      "color": Colors.orange,
    },
    {
      "icon": Icons.coffee,
      "text": "피곤할 때 카페 지출이 늘어요",
      "color": Colors.blue,
    },
  ];

  int _index = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();

    // 🔥 mounted 체크 넣어서 dispose 이후에는 더 안 돌아가게
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) return; // 위젯이 이미 dispose 되었으면 아무 것도 안 함

      if (_controller.hasClients) {
        _index = (_index + 1) % insights.length;
        _controller.animateToPage(
          _index,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    // 🔥 타이머 먼저 끄고
    _timer?.cancel();
    // 🔥 컨트롤러도 정리
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: PageView.builder(
        controller: _controller,
        scrollDirection: Axis.vertical,
        itemCount: insights.length,
        itemBuilder: (_, i) {
          final it = insights[i];

          // Map<String, dynamic>에서 꺼낸 값들 타입 캐스팅
          final IconData icon = it["icon"] as IconData;
          final Color color = it["color"] as Color;
          final String text = it["text"] as String;

          return Container(
            // margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    text,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
