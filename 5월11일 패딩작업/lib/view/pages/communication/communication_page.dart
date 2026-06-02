// lib/view/pages/communication/communication_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../component/banner/sliding_banner.dart';
import '../../../component/theme/padding/horizontal_padding_clamped_fraction.dart';
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
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface,
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