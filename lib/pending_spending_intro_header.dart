import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';

import '../../../component/theme/app_colors.dart';

/// [PendingSpendingIntroPage] 공통 — 멘트 + [CalendarLottie] + (한도 있을 때) 금액 애니메이션.
class PendingSpendingIntroHeader extends StatefulWidget {
  const PendingSpendingIntroHeader({
    super.key,
    required this.userName,
    required this.pendingDayCount,
    required this.dailyLimitText,
    this.showNextButtonHint = true,
  });

  final String userName;
  final int pendingDayCount;
  final String dailyLimitText;

  /// false면 「다음 버튼을 누르면…」 문구 숨김.
  final bool showNextButtonHint;

  @override
  State<PendingSpendingIntroHeader> createState() =>
      _PendingSpendingIntroHeaderState();
}

class _PendingSpendingIntroHeaderState extends State<PendingSpendingIntroHeader> {
  static const double _textSize = 15.0;

  /// 화면 진입 후 **0.3초 뒤** 일수 숫자 애니 시작.
  static const Duration _delayBeforeDayAnim = Duration(milliseconds: 300);

  /// 일수 애니 시작 **1초 뒤** 금액 애니 시작.
  static const Duration _delayAfterDayAnimBeforeAmount = Duration(
    milliseconds: 1000,
  );

  static const Duration _daysAnimDuration = Duration(milliseconds: 900);
  static const Duration _amountAnimDuration = Duration(milliseconds: 450);

  bool _dayPhase = false;
  bool _amountPhase = false;

  static int _parseWonToInt(String text) {
    final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digits) ?? 0;
  }

  static String _formatAmount(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future<void>.delayed(_delayBeforeDayAnim);
      if (!mounted) return;
      setState(() => _dayPhase = true);
      await Future<void>.delayed(_delayAfterDayAnimBeforeAmount);
      if (!mounted) return;
      setState(() => _amountPhase = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final baseStyle = TextStyle(
      fontSize: _textSize,
      fontWeight: FontWeight.w600,
      color: Colors.black87,
      height: 1.5,
      fontFamily: 'Pretendard Variable',
    );

    final emphasisStyle = TextStyle(
      fontSize: _textSize,
      fontWeight: FontWeight.w700,
      color: AppColors.primary,
      height: 1.5,
      fontFamily: 'Pretendard Variable',
    );

    final footerStyle = TextStyle(
      fontSize: _textSize,
      fontWeight: FontWeight.w400,
      color: Colors.black54,
      height: 1.55,
      fontFamily: 'Pretendard Variable',
    );

    final hasLimit = widget.dailyLimitText != '—' &&
        widget.dailyLimitText.isNotEmpty;
    final amountTarget = hasLimit ? _parseWonToInt(widget.dailyLimitText) : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFirstLine(
          widget.userName,
          widget.pendingDayCount,
          baseStyle,
          emphasisStyle,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 35),
          child: SizedBox(
            width: double.infinity,
            child: CalendarLottie(),
          ),
        ),
        const SizedBox(height: 20),
        if (hasLimit)
          _buildSecondLine(
            widget.userName,
            amountTarget,
            baseStyle,
            emphasisStyle,
          )
        else
          Text(
            '해당 날짜 처리 방식을 바꾸려면 미기록 화면에서 확인·수정해 주세요.',
            style: baseStyle,
          ),
        if (widget.showNextButtonHint) ...[
          const SizedBox(height: 20),
          Text(
            '다음 버튼을 누르면 날짜별로 기록을 이어갈 수 있어요.',
            style: footerStyle,
          ),
        ],
      ],
    );
  }

  Widget _buildFirstLine(
      String userName,
      int pendingDayCount,
      TextStyle baseStyle,
      TextStyle emphasisStyle,
      ) {
    Widget dayDigitSlot() {
      if (!_dayPhase) {
        return Text('', style: emphasisStyle);
      }
      return TweenAnimationBuilder<int>(
        key: ValueKey<int>(pendingDayCount),
        tween: IntTween(begin: 0, end: pendingDayCount),
        duration: _daysAnimDuration,
        curve: Curves.easeOutCubic,
        builder: (context, value, _) {
          if (value == 0) {
            return Text('', style: emphasisStyle);
          }
          return Text('$value', style: emphasisStyle);
        },
      );
    }

    return Text.rich(
      TextSpan(
        style: baseStyle,
        children: [
          TextSpan(text: userName, style: emphasisStyle),
          const TextSpan(text: '님께서 기록하지 않으신 날짜는 총 '),
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: dayDigitSlot(),
          ),
          const TextSpan(text: '일이에요.'),
        ],
      ),
    );
  }

  Widget _buildSecondLine(
      String userName,
      int amountTarget,
      TextStyle baseStyle,
      TextStyle emphasisStyle,
      ) {
    Widget amountSlot() {
      if (!_amountPhase) {
        return Text('', style: emphasisStyle);
      }
      return TweenAnimationBuilder<int>(
        key: ValueKey<int>(amountTarget),
        tween: IntTween(begin: 0, end: amountTarget),
        duration: _amountAnimDuration,
        curve: Curves.easeOutCubic,
        builder: (context, value, _) {
          if (value == 0) {
            return Text('', style: emphasisStyle);
          }
          return Text(
            '${_formatAmount(value)}원',
            style: emphasisStyle,
          );
        },
      );
    }

    return Text.rich(
      TextSpan(
        style: baseStyle,
        children: [
          const TextSpan(text: '해당 날짜는, '),
          TextSpan(text: userName, style: emphasisStyle),
          const TextSpan(text: '님께서 초기에 만들어 두신\n'),
          const TextSpan(text: '일일 소비 한도 금액 '),
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: amountSlot(),
          ),
          const TextSpan(text: '으로 자동 등록해 두었어요.\n'),
          const TextSpan(text: '변경을 원하시면 다음버튼을 눌러주세요.'),
        ],
      ),
    );
  }
}

/// 에셋: `assets/animations/calendar_planning.json` — 원본 캔버스 **900×600** (LottieFiles AE).
///
/// 화면 박스 비율은 **600:400**(가로:세로)로 두고 [BoxFit.contain]으로 맞춤.
/// [rootBundle.load] 후 [Lottie.memory]로 재생 — 에셋 번들·`DefaultAssetBundle` 이슈를 피함.
class CalendarLottie extends StatefulWidget {
  const CalendarLottie({super.key});

  @override
  State<CalendarLottie> createState() => _CalendarLottieState();
}

class _CalendarLottieState extends State<CalendarLottie> {
  static const String _assetPath = 'assets/animations/calendar_planning.json';
  /// 레이아웃 박스 가로:세로 = 600:400 (원본 900×600과 별개).
  static const double _layoutW = 600;
  static const double _layoutH = 400;

  late final Future<Uint8List> _bytesFuture;

  @override
  void initState() {
    super.initState();
    _bytesFuture = _loadBytes();
  }

  Future<Uint8List> _loadBytes() async {
    final data = await rootBundle.load(_assetPath);
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final screenW = MediaQuery.sizeOf(context).width;
        final w = maxW.isFinite && maxW > 0
            ? maxW
            : (screenW > 0 ? screenW : 320.0);
        final h = w * _layoutH / _layoutW;

        return SizedBox(
          width: w,
          height: h,
          child: FutureBuilder<Uint8List>(
            future: _bytesFuture,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                debugPrint('CalendarLottie load: ${snapshot.error}');
                return Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    size: 40,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                );
              }
              if (!snapshot.hasData) {
                return Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                );
              }
              return Lottie.memory(
                snapshot.data!,
                repeat: true,
                fit: BoxFit.contain,
                alignment: Alignment.center,
                errorBuilder: (context, error, stackTrace) {
                  debugPrint('CalendarLottie decode: $error');
                  return Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      size: 40,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
