import 'package:flutter/material.dart';
import '../texts/subtext.dart';
import '../theme/app_colors.dart';

class BubbleSavingProgressBar extends StatelessWidget {
  final double currentRate;
  final double baseRate;
  final Color barColor;
  final Color backgroundColor;
  final Color currentBubbleColor;
  final Color baseBubbleColor;

  const BubbleSavingProgressBar({
    super.key,
    required this.currentRate,
    required this.baseRate,
    this.barColor = AppColors.primary,
    this.backgroundColor = AppColors.greyBackground,
    this.currentBubbleColor = AppColors.primary,
    this.baseBubbleColor = AppColors.planTagBackground,
  });

  @override
  Widget build(BuildContext context) {
    const bubbleHorizontalPadding = 12.0;
    const bubbleVerticalPadding = 4.0;
    const extraPadding = 16.0;
    const double fixedBubbleWidth = 48.0;

    return SizedBox(
      height: 100,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: extraPadding),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final barWidth = constraints.maxWidth;

            final currentText = "${(currentRate * 100).round()}%";
            final baseText = "${(baseRate * 100).round()}%";

            const bubbleTextStyle = TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            );

            return Stack(
              clipBehavior: Clip.none,
              children: [
                // progress bar
                Positioned(
                  top: 40,
                  left: 0,
                  right: 0,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: currentRate.clamp(0.0, 1.0),
                      minHeight: 20,
                      backgroundColor: backgroundColor,
                      valueColor: AlwaysStoppedAnimation<Color>(barColor),
                    ),
                  ),
                ),

                Positioned(
                  top: 0,
                  left: currentRate * barWidth - fixedBubbleWidth / 2,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: fixedBubbleWidth,
                        padding: const EdgeInsets.symmetric(
                          vertical: bubbleVerticalPadding,
                        ),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          // color: currentBubbleColor,
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: SubText(
                          text: currentText,
                          color: currentBubbleColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SubText(
                        text: "현재 절약율",
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ],
                  ),
                ),

                Positioned(
                  top: 70,
                  left: baseRate * barWidth - fixedBubbleWidth / 2,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: fixedBubbleWidth,
                        padding: const EdgeInsets.symmetric(
                          vertical: bubbleVerticalPadding,
                        ),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          // color: baseBubbleColor,
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: SubText(
                          text: baseText,
                          color: baseBubbleColor,
                          fontWeight: FontWeight.bold,
                        ),
                        // Text(
                        //   baseText,
                        //   style: bubbleTextStyle,
                        //   textAlign: TextAlign.center,
                        // ),
                      ),
                      const SubText(
                        text: "기준 절약률",
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ],
                  ),
                ),

                // 화살표: 진행 바 정중앙에 위치
                Positioned(
                  top: 20,
                  left: currentRate * barWidth - 10,
                  child: const Icon(
                    Icons.arrow_drop_down,
                    size: 20,
                    color: AppColors.primary,
                  ),
                ),
                Positioned(
                  top: 60,
                  left: baseRate * barWidth - 10,
                  child: const Icon(
                    Icons.arrow_drop_up,
                    size: 20,
                    color: AppColors.planTagBackground,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
