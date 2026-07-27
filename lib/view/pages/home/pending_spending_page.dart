import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

import 'package:sotong/view/pages/home/home_widgets/home_record_calendar_panel.dart';

import '../../../component/appbars/back_only_app_bar.dart';
import '../../../component/theme/app_colors.dart';
import '../../../component/theme/app_spacing.dart';
import '../../../services/chart_animation_haptic.dart';
import '../../../repository/auth_repository.dart';
import '../../../repository/plan_repository.dart';
import '../../../repository/record_repository.dart';
import '../../../view_model/home/pending_spending_view_model.dart';

class PendingSpendingPage extends StatelessWidget {
  const PendingSpendingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PendingSpendingViewModel(
        context.read<AuthRepository>(),
        context.read<PlanRepository>(),
        context.read<RecordRepository>(),
      ),
      child: const _PendingSpendingPageBody(),
    );
  }
}

class _PendingSpendingPageBody extends StatefulWidget {
  const _PendingSpendingPageBody();

  @override
  State<_PendingSpendingPageBody> createState() =>
      _PendingSpendingPageBodyState();
}

class _PendingSpendingPageBodyState extends State<_PendingSpendingPageBody> {
  final PageController _controller = PageController();
  int _pageIndex = 0;
  bool _didLoad = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didLoad) return;

    final args = ModalRoute.of(context)?.settings.arguments;
    DateTime? initialMonth;

    if (args is Map && args['initialMonth'] is DateTime) {
      initialMonth = args['initialMonth'] as DateTime;
    }

    Future.microtask(() {
      context.read<PendingSpendingViewModel>().load(
        initialMonth: initialMonth,
      );
    });

    _didLoad = true;
  }

  void _goNext() => _controller.animateToPage(
    1,
    duration: const Duration(milliseconds: 300),
    curve: Curves.easeOut,
  );

  void _goBack() {
    if (_pageIndex == 1) {
      _controller.animateToPage(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PendingSpendingViewModel>();
    final theme = Theme.of(context);
    final isAllDone = vm.pendingDayCount == 0;

    debugPrint(
      '[PENDING_PAGE] pendingDayCount=${vm.pendingDayCount}, isAllDone=$isAllDone',
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: BackOnlyAppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        iconColor: theme.colorScheme.onSurface,
        onBack: _goBack,
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : vm.error != null
          ? Center(child: Text('오류: ${vm.error}'))
          : PageView(
        controller: _controller,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (i) {
          setState(() => _pageIndex = i);
          if (i == 0) {
            vm.clearSelectedPendingDate();
          }
        },
        children: [
          /// STEP 1
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenPadding,
                    24,
                    AppSpacing.screenPadding,
                    24,
                  ),
                  child: _sectionCard(
                    context,
                    child: PendingSpendingHeader(
                      userName: vm.userName,
                      pendingDayCount: vm.pendingDayCount,
                      dailyLimitText: vm.dailyLimitText,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding,
                  8,
                  AppSpacing.screenPadding,
                  AppSpacing.screenPadding,
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: isAllDone
                        ? () {
                      AppHaptics.buttonTap();
                      Navigator.of(context)
                          .pushNamedAndRemoveUntil(
                        '/home_tab_navigator',
                            (_) => false,
                      );
                    }
                        : () {
                      AppHaptics.buttonTap();
                      _goNext();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: Text(isAllDone ? '홈으로' : '다음'),
                  ),
                ),
              ),
            ],
          ),

          /// STEP 2
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenPadding,
                    16,
                    AppSpacing.screenPadding,
                    8,
                  ),
                  child: _sectionCard(
                    context,
                    child: HomeRecordCalendarPanel(
                      embedded: true,
                      showEmbeddedHeader: false,
                      unrecordedDates: vm.pendingDates,
                      recordedDates: vm.recordedDates,
                      selectedDate: vm.selectedPendingDate,
                      initialMonth: vm.initialMonth,
                      onDateSelected: (d) {
                        HapticFeedback.selectionClick();
                        if (!vm.isPendingDay(d)) return;
                        vm.selectPendingDate(d);
                      },
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding,
                  8,
                  AppSpacing.screenPadding,
                  AppSpacing.screenPadding,
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: vm.selectedPendingDate != null
                        ? () {
                      AppHaptics.buttonTap();
                      final selectedDate =
                      vm.selectedPendingDate!;
                      Navigator.of(
                        context,
                        rootNavigator: true,
                      ).pushNamed(
                        '/record',
                        arguments: selectedDate,
                      );
                    }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          AppColors.primary.withValues(alpha: 0.35),
                      disabledForegroundColor:
                          Colors.white.withValues(alpha: 0.65),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: const Text('다음'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionCard(BuildContext context, {required Widget child}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class PendingSpendingHeader extends StatefulWidget {
  const PendingSpendingHeader({
    super.key,
    required this.userName,
    required this.pendingDayCount,
    required this.dailyLimitText,
  });

  final String userName;
  final int pendingDayCount;
  final String dailyLimitText;

  @override
  State<PendingSpendingHeader> createState() => _PendingSpendingHeaderState();
}

class _PendingSpendingHeaderState extends State<PendingSpendingHeader> {
  static const double _textSize = 15.0;
  static const Duration _delayBeforeDayAnim = Duration(milliseconds: 300);
  static const Duration _delayAfterDayAnimBeforeAmount =
  Duration(milliseconds: 1000);
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
    final theme = Theme.of(context);

    final baseStyle = TextStyle(
      fontSize: _textSize,
      fontWeight: FontWeight.w600,
      color: theme.colorScheme.onSurface,
      height: 1.5,
    );

    final emphasisStyle = TextStyle(
      fontSize: _textSize,
      fontWeight: FontWeight.w700,
      color: AppColors.primary,
      height: 1.5,
    );

    final hasLimit =
        widget.dailyLimitText != '—' && widget.dailyLimitText.isNotEmpty;
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
            child: const CalendarLottie(),
          ),
        ),
        const SizedBox(height: 20),

        // ✅ 0일이면 무조건 여기서 별도 문구를 띄움
        if (widget.pendingDayCount == 0)
          Text(
            '모든 날짜가 이미 기록되어 있어요.',
            style: baseStyle,
          )
        else if (hasLimit)
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
          return Text('${_formatAmount(value)}원', style: emphasisStyle);
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
          const TextSpan(text: '변경을 원하시면 다음 버튼을 눌러주세요.'),
        ],
      ),
    );
  }
}

class CalendarLottie extends StatefulWidget {
  const CalendarLottie({super.key});

  @override
  State<CalendarLottie> createState() => _CalendarLottieState();
}

class _CalendarLottieState extends State<CalendarLottie> {
  static const String _assetPath = 'assets/animations/calendar_planning.json';
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