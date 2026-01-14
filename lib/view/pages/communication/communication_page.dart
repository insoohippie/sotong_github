// lib/view/pages/communication/communication_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../view_model/communication/communication_view_model.dart';
import 'comm_widgets/emotion_calendar_section.dart';
import 'comm_widgets/emotion_top3_carousel_section.dart';


class CommunicationPage extends StatefulWidget {
  const CommunicationPage({super.key});

  @override
  State<CommunicationPage> createState() => _CommunicationPageState();
}

class _CommunicationPageState extends State<CommunicationPage> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CommunicationViewModel>().loadMonth(DateTime.now());
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CommunicationViewModel>();

    if (vm.isLoading) {
      return const SafeArea(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (vm.error != null) {
      return SafeArea(
        child: Center(child: Text('오류 발생: ${vm.error}')),
      );
    }

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  const SizedBox(height: 12),
                  _buildInsightBanner(vm),
                  const SizedBox(height: 20),

                  EmotionCalendarSection(vm: vm),
                  const SizedBox(height: 20),

                  // EmotionAnalysisSection(vm: vm),
                  EmotionTop3CarouselSection(vm: vm),
                  const SizedBox(height: 20),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 사용자에게 보여줄 간단 Insight Banner
  Widget _buildInsightBanner(CommunicationViewModel vm) {
    final insightText = vm.getMonthlyInsightMessage();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF5FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb, color: Color(0xFF0062FF)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              insightText,
              style: const TextStyle(
                color: Color(0xFF0062FF),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          )
        ],
      ),
    );
  }
}
