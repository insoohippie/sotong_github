import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:sotong_local/view/pages/home/home_widgets/home_record_calendar_panel.dart';

import '../../../component/appbars/back_only_app_bar.dart';
import '../../../component/theme/app_colors.dart';
import '../../../component/theme/app_spacing.dart';

import 'pending_spending_intro_header.dart';
class PendingSpendingIntroPage extends StatefulWidget {
  const PendingSpendingIntroPage({super.key});

  @override
  State<PendingSpendingIntroPage> createState() =>
      _PendingSpendingIntroPageState();
}

class _PendingSpendingIntroPageState extends State<PendingSpendingIntroPage> {
  static const Duration _kPageAnimDuration = Duration(milliseconds: 320);
  static const Curve _kPageAnimCurve = Curves.easeOutCubic;

  /// 1단계 인트로 — 표시 이름 (멘트 하드코딩).
  static const String _kIntroDisplayName = '황인수';

  /// 미기록으로 집계된 **일수** (`… 총 N일이에요`).
  static const int _kIntroUnrecordedDayCount = 5;

  /// 일일 소비 한도 **표시 문자열** (`50,000원` — [PendingSpendingIntroHeader] 애니·문구용).
  static const String _kIntroDailyLimitText = '50,000원';

  final PageController _pageController = PageController();

  int _pageIndex = 0;
  DateTime? _pendingRecordDate;

  static DateTime? _initialMonth(Object? raw) {
    if (raw is Map && raw['initialMonth'] is DateTime) {
      return raw['initialMonth'] as DateTime;
    }
    return null;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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

  Future<void> _goToCalendar() async {
    HapticFeedback.selectionClick();
    await _pageController.animateToPage(
      1,
      duration: _kPageAnimDuration,
      curve: _kPageAnimCurve,
    );
  }

  Future<void> _goToIntro() async {
    await _pageController.animateToPage(
      0,
      duration: _kPageAnimDuration,
      curve: _kPageAnimCurve,
    );
  }

  void _handleBack() {
    if (_pageIndex == 1) {
      _goToIntro();
    } else {
      Navigator.pop(context);
    }
  }

  bool _isPendingDay(DateTime d) {
    return true;
    // return kSamplePendingSpendingDays.any(
    //       (x) =>
    //   x.year == d.year && x.month == d.month && x.day == d.day,
    // );
  }

  void _onCalendarDayTapped(DateTime date) {
    HapticFeedback.selectionClick();
    if (!_isPendingDay(date)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('미기록 날짜를 선택해 주세요')),
      );
      return;
    }
    setState(() => _pendingRecordDate = date);
  }

  void _goToPendingSpendingDays() {
    final d = _pendingRecordDate;
    if (d == null) return;
    HapticFeedback.selectionClick();
    Navigator.of(context, rootNavigator: true).pushReplacementNamed(
      '/pending_spending_days',
      arguments: <String, dynamic>{'initialDate': d},
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initialMonth =
    _initialMonth(ModalRoute.of(context)?.settings.arguments);

    return PopScope(
      canPop: _pageIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _pageIndex == 1) {
          _goToIntro();
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: BackOnlyAppBar(
          backgroundColor: theme.scaffoldBackgroundColor,
          iconColor: theme.colorScheme.onSurface,
          onBack: _handleBack,
        ),
        body: SafeArea(
          child: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (i) {
              setState(() {
                _pageIndex = i;
                if (i == 0) _pendingRecordDate = null;
              });
            },
            children: [
              _buildIntroStep(context),
              _buildCalendarStep(
                context,
                initialMonth: initialMonth,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIntroStep(BuildContext context) {
    return Column(
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
              child: PendingSpendingIntroHeader(
                userName: _kIntroDisplayName,
                pendingDayCount: _kIntroUnrecordedDayCount,
                dailyLimitText: _kIntroDailyLimitText,
                showNextButtonHint: false,
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
              onPressed: _goToCalendar,
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
              child: const Text('다음'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarStep(
      BuildContext context, {
        required DateTime? initialMonth,
      }) {
    return Column(
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
                unrecordedDates: kSamplePendingSpendingDays,
                recordedDates: kSampleRecordedSpendingDays,
                initialMonth: initialMonth,
                selectedDate: _pendingRecordDate,
                onDateSelected: _onCalendarDayTapped,
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
              onPressed:
              _pendingRecordDate != null ? _goToPendingSpendingDays : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.disabled,
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
    );
  }
}
