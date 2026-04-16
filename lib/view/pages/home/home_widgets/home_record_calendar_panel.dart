import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../component/theme/app_colors.dart';

/// 미기록: 평일 검정·토 primary·일 빨강(굵게) / 기록됨: 연한 비활성. 기록된 날은 탭 불가.
class HomeRecordCalendarPanel extends StatefulWidget {
  const HomeRecordCalendarPanel({
    super.key,
    required this.unrecordedDates,
    required this.recordedDates,
    this.initialMonth,
    required this.onDateSelected,
    this.embedded = false,
    this.showEmbeddedHeader = true,
    /// 선택된 날(미기록 탭) — 테두리 강조. null이면 표시 안 함.
    this.selectedDate,
  });

  final List<DateTime> unrecordedDates;
  final List<DateTime> recordedDates;
  final DateTime? initialMonth;
  final void Function(DateTime date) onDateSelected;

  final DateTime? selectedDate;

  /// true: 페이지에 삽입 — 상단 안내 멘트 + 미기록 범례 + 달력, 카드 테두리 없음.
  /// false: 바텀시트 — 핸들·안내·범례(미기록·기록함) + 상단 라운드·그림자 컨테이너.
  final bool embedded;

  /// [embedded]가 true일 때만 사용. false면 멘트 없이 범례 + 달력만 (상단 카드에 멘트를 둘 때).
  final bool showEmbeddedHeader;

  @override
  State<HomeRecordCalendarPanel> createState() =>
      _HomeRecordCalendarPanelState();
}

class _HomeRecordCalendarPanelState extends State<HomeRecordCalendarPanel> {
  late DateTime _viewMonth;
  late Set<String> _unrecordedYmd;
  late Set<String> _recordedYmd;

  String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
          '${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  DateTime _monthOnly(DateTime d) => DateTime(d.year, d.month);

  @override
  void initState() {
    super.initState();
    _unrecordedYmd = {for (final d in widget.unrecordedDates) _ymd(d)};
    _recordedYmd = {for (final d in widget.recordedDates) _ymd(d)};
    final all = <DateTime>[
      ...widget.unrecordedDates,
      ...widget.recordedDates,
    ];
    final now = DateTime.now();
    if (widget.initialMonth != null) {
      _viewMonth = _monthOnly(widget.initialMonth!);
    } else if (all.isEmpty) {
      _viewMonth = _monthOnly(now);
    } else {
      all.sort((a, b) => a.compareTo(b));
      final first = all.first;
      final last = all.last;
      if (now.isBefore(first)) {
        _viewMonth = _monthOnly(first);
      } else if (now.isAfter(last)) {
        _viewMonth = _monthOnly(last);
      } else {
        _viewMonth = _monthOnly(now);
      }
    }
    _viewMonth = _viewMonth.isBefore(_firstMonth)
        ? _firstMonth
        : (_viewMonth.isAfter(_lastMonth) ? _lastMonth : _viewMonth);
  }

  DateTime get _firstMonth {
    final all = <DateTime>[...widget.unrecordedDates, ...widget.recordedDates];
    final now = DateTime.now();
    final months = <DateTime>{
      _monthOnly(now),
      if (widget.initialMonth != null) _monthOnly(widget.initialMonth!),
      ...all.map(_monthOnly),
    };
    if (months.isEmpty) return _monthOnly(now);
    final sorted = months.toList()..sort((a, b) => a.compareTo(b));
    return sorted.first;
  }

  DateTime get _lastMonth {
    final all = <DateTime>[...widget.unrecordedDates, ...widget.recordedDates];
    final now = DateTime.now();
    final months = <DateTime>{
      _monthOnly(now),
      if (widget.initialMonth != null) _monthOnly(widget.initialMonth!),
      ...all.map(_monthOnly),
    };
    if (months.isEmpty) return _monthOnly(now);
    final sorted = months.toList()..sort((a, b) => a.compareTo(b));
    return sorted.last;
  }

  void _prevMonth() {
    if (_viewMonth.isAfter(_firstMonth)) {
      setState(() {
        _viewMonth = DateTime(_viewMonth.year, _viewMonth.month - 1);
      });
    }
  }

  void _nextMonth() {
    if (_viewMonth.isBefore(_lastMonth)) {
      setState(() {
        _viewMonth = DateTime(_viewMonth.year, _viewMonth.month + 1);
      });
    }
  }

  bool _isUnrecorded(DateTime d) => _unrecordedYmd.contains(_ymd(d));

  bool _isRecorded(DateTime d) =>
      _recordedYmd.contains(_ymd(d)) && !_isUnrecorded(d);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final year = _viewMonth.year;
    final month = _viewMonth.month;
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);
    final daysInMonth = lastDay.day;
    final firstWeekdayOffset = (firstDay.weekday + 6) % 7;

    final inner = Padding(
      padding: EdgeInsets.fromLTRB(
        widget.embedded ? 0 : 20,
        widget.embedded ? 0 : 12,
        widget.embedded ? 0 : 20,
        widget.embedded ? 0 : 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.embedded && widget.showEmbeddedHeader) ...[
            Text(
              '미기록 날짜를 선택하면 해당 날의 기록 화면으로 이동해요',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (!widget.embedded) ...[
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Text(
              '미기록 날짜를 선택하면 해당 날의 기록 화면으로 이동해요',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
                height: 1.35,
              ),
            ),
          ],
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: _viewMonth.isAfter(_firstMonth)
                      ? () {
                    HapticFeedback.selectionClick();
                    _prevMonth();
                  }
                      : null,
                  child: Icon(
                    Icons.chevron_left,
                    size: 22,
                    color: _viewMonth.isAfter(_firstMonth)
                        ? theme.colorScheme.onSurfaceVariant
                        : theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.3,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$year년 $month월',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _viewMonth.isBefore(_lastMonth)
                      ? () {
                    HapticFeedback.selectionClick();
                    _nextMonth();
                  }
                      : null,
                  child: Icon(
                    Icons.chevron_right,
                    size: 22,
                    color: _viewMonth.isBefore(_lastMonth)
                        ? theme.colorScheme.onSurfaceVariant
                        : theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: ['월', '화', '수', '목', '금', '토', '일']
                .map(
                  (w) => Expanded(
                child: Center(
                  child: Text(
                    w,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: w == '일'
                          ? Colors.red
                          : w == '토'
                          ? AppColors.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            )
                .toList(),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.1,
            ),
            itemCount: 42,
            itemBuilder: (context, index) {
              final day = index - firstWeekdayOffset + 1;
              if (day < 1 || day > daysInMonth) {
                return const SizedBox();
              }
              final date = DateTime(year, month, day);
              final un = _isUnrecorded(date);
              final rec = _isRecorded(date);
              final isSun = date.weekday == DateTime.sunday;
              final isSat = date.weekday == DateTime.saturday;

              late Color dayColor;
              late FontWeight weight;
              if (rec) {
                dayColor =
                    theme.colorScheme.onSurface.withValues(alpha: 0.28);
                weight = FontWeight.w400;
              } else if (un) {
                // 미기록: 평일 검정 / 토 primary / 일 빨강 (동일 규칙, 굵게)
                if (isSun) {
                  dayColor = Colors.red;
                } else if (isSat) {
                  dayColor = AppColors.primary;
                } else {
                  dayColor = theme.colorScheme.onSurface;
                }
                weight = FontWeight.w700;
              } else {
                // 그 외 날: 같은 요일 톤으로 연하게
                if (isSun) {
                  dayColor = Colors.red.withValues(alpha: 0.35);
                } else if (isSat) {
                  dayColor = AppColors.primary.withValues(alpha: 0.45);
                } else {
                  dayColor = theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.45,
                  );
                }
                weight = FontWeight.w500;
              }

              final selected = widget.selectedDate != null &&
                  _isSameDay(date, widget.selectedDate!);

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: rec
                    ? null
                    : () {
                  HapticFeedback.selectionClick();
                  widget.onDateSelected(date);
                },
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: selected
                      ? BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  )
                      : null,
                  child: Center(
                    child: Text(
                      '$day',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: weight,
                        color: dayColor,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          if (widget.embedded) ...[
            Row(
              children: [
                _legendDot(AppColors.primary, '미기록'),
              ],
            ),
          ],
          if (!widget.embedded) ...[
            Row(
              children: [
                _legendDot(AppColors.primary, '미기록'),
                const SizedBox(width: 16),
                _legendDot(
                  theme.colorScheme.onSurface.withValues(alpha: 0.28),
                  '기록함',
                ),
              ],
            ),
          ],
        ],
      ),
    );

    if (widget.embedded) {
      return inner;
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(40),
          topRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            offset: const Offset(0, -4),
            blurRadius: 6,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: inner,
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
