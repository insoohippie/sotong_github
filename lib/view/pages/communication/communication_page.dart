import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../component/theme/app_spacing.dart';
import '../../../view_model/communication/communication_view_model.dart';

import 'widgets/insight_banner.dart';
import 'widgets/emotion_calendar_section.dart';
import 'widgets/emotion_analysis_section.dart';
import 'widgets/monthly_summary_section.dart';

class CommunicationPage extends StatefulWidget {
  const CommunicationPage({super.key});

  @override
  State<CommunicationPage> createState() => _CommunicationPageState();
}

class _CommunicationPageState extends State<CommunicationPage> {
  @override
  void initState() {
    super.initState();

    // ✅ 프레임 끝난 뒤 + mounted 체크 후에 데이터 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CommunicationViewModel>().loadMonth(DateTime.now());
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CommunicationViewModel>();

    // 로딩 / 에러 화면도 SafeArea 안에서
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
          // 상단에 커스텀 앱바 쓰고 싶으면 여기서 추가 가능
          // const CustomHomeAppBar(title: '소통'),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),

                  const InsightBanner(),

                  const SizedBox(height: 16),

                  EmotionCalendarSection(vm: vm),

                  const SizedBox(height: 20),

                  EmotionAnalysisSection(vm: vm),

                  const SizedBox(height: 20),

                  MonthlySummarySection(vm: vm),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
