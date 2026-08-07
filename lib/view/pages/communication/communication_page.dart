// lib/view/pages/communication/communication_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../component/banner/sliding_banner.dart';
import '../../../component/theme/padding/horizontal_padding_clamped_fraction.dart';
import '../../../view_model/communication/communication_view_model.dart';
import '../../../view_model/home/home_view_model.dart';
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

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final commVm =
      context.read<CommunicationViewModel>();

      final homeVm =
      context.read<HomeViewModel>();

      // 완료된 플랜이면 실제 완료일이 달력 상한.
      // 진행 중이면 null이고,
      // CommunicationViewModel 내부의 planEndDate를 사용한다.
      final completionDate =
          homeVm.planCompletionDate;

      // 달력뿐 아니라 Top3/배너 분석에서도
      // 실제 완료일을 사용할 수 있도록 동기화
      commVm.setPlanCompletionDate(
        completionDate,
      );

      final anchor =
          completionDate ?? DateTime.now();

      await commVm.loadMonth(
        anchor,
        endCap: completionDate,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CommunicationViewModel>();
    final completionDate =
    context.select<HomeViewModel, DateTime?>(
          (homeVm) => homeVm.planCompletionDate,
    );

    vm.setPlanCompletionDate(
      completionDate,
    );
    final horizontalPadding = PaddingResponsive16_40Vw.horizontal(
      context,
      PaddingResponsive16_40Vw.fractionScreen075,
    );
    final viewWidth = MediaQuery.sizeOf(context).width;
    final bannerFontSize = viewWidth <= 386
        ? 11.0
        : viewWidth < 412
        ? 12.0
        : 13.0;

    if (vm.isLoading) {
      return const SafeArea(child: Center(child: CircularProgressIndicator()));
    }

    if (vm.error != null) {
      return SafeArea(child: Center(child: Text('오류 발생: ${vm.error}')));
    }

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),

                  // ✅ 배너 높이 60 고정
                  SizedBox(
                    height: 60,
                    child: SlidingBanner(
                      itemCount: vm.bannerInsights.length,
                      itemBuilder: (context, index) {
                        final insight = vm.bannerInsights[index];
                        final color = insight['color'] as Color;
                        final icon = insight['icon'] as IconData;
                        final title = insight['title'] as String;

                        return Container(
                          height: 60,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: color.withOpacity(0.25),
                              width: 0.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(icon, color: color, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  title,
                                  style: TextStyle(
                                    fontSize: bannerFontSize,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      autoSlideDuration: const Duration(seconds: 3),
                    ),
                  ),

                  const SizedBox(height: 20),
                  EmotionCalendarSection(vm: vm),
                  const SizedBox(height: 20),
                  EmotionTop3CarouselSection(vm: vm),
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
