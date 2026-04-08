// lib/view_model/communication/communication_view_model.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color, Icons;
import 'package:intl/intl.dart';

import 'package:sotong_local/services/record_event_bus.dart';

import '../../model/record/monthly_record.dart';
import '../../model/record/day_record.dart';
import '../../model/record/record_entry.dart';

import '../../repository/record_repository.dart';
import '../../repository/plan_repository.dart';

class CommunicationViewModel extends ChangeNotifier {
  final RecordRepository _recordRepository;
  final PlanRepository _planRepository;

  late final StreamSubscription<RecordUpdatedEvent> _eventSub;

  CommunicationViewModel(
      this._recordRepository,
      this._planRepository,
      RecordEventBus eventBus,
      ) {
    _eventSub = eventBus.stream.listen((_) {
      reloadForCurrentMonth();
    });
  }

  bool _isLoading = false;
  String? _error;
  bool get isLoading => _isLoading;
  String? get error => _error;

  MonthlyRecord? _monthly;
  final Map<String, MonthlyRecord> _monthCache = {};

  int selectedYear = DateTime.now().year;
  int selectedMonth = DateTime.now().month;

  String selectedEmotionForAnalysis = '기쁨';
  String selectedAnalysisPeriod = '월간';

  double dailySpendingLimit = 0;
  DateTime? _planStartDate;

  Future<void> loadMonth(DateTime anchor) async {
    _setLoading(true);

    selectedYear = anchor.year;
    selectedMonth = anchor.month;

    try {
      final monthly = await _recordRepository.loadMonthlyRecordByDate(anchor);
      _monthly = monthly;
      _monthCache[_monthKey(anchor)] = monthly;

      await _loadPlanInfo();

      if (_planStartDate != null) {
        await _preloadMonthsForPlanPeriod(_planStartDate!);
      } else {
        await _preloadMonthsForRecentPeriod(days: 30);
      }

      _setError(null);
    } catch (e) {
      _setError('로드 실패: $e');
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  Future<void> reloadForCurrentMonth() async {
    await loadMonth(DateTime(selectedYear, selectedMonth, 1));
  }

  void changeMonth(int delta) {
    var newMonth = selectedMonth + delta;
    var newYear = selectedYear;

    if (newMonth < 1) {
      newMonth = 12;
      newYear--;
    } else if (newMonth > 12) {
      newMonth = 1;
      newYear++;
    }

    loadMonth(DateTime(newYear, newMonth, 1));
  }

  Future<void> _loadPlanInfo() async {
    try {
      final plan = await _planRepository.getLatestPlanForCurrentUser();
      final metrics = plan?.result.totalMetrics;
      dailySpendingLimit = (metrics?.dailyConsumeAmount ?? 0).toDouble();
      _planStartDate = _extractPlanStartDate(plan);
    } catch (_) {
      dailySpendingLimit = 0;
      _planStartDate ??= null;
    }
  }

  DateTime? _extractPlanStartDate(dynamic plan) {
    if (plan == null) return null;

    DateTime? parseCandidate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return _dateOnly(value);
      if (value is String) {
        final parsed = DateTime.tryParse(value);
        if (parsed != null) return _dateOnly(parsed);
      }
      return null;
    }

    try {
      final direct = parseCandidate(plan.startDate);
      if (direct != null) return direct;
    } catch (_) {}

    try {
      final nested = parseCandidate(plan.result.startDate);
      if (nested != null) return nested;
    } catch (_) {}

    try {
      final nested2 = parseCandidate(plan.createdAt);
      if (nested2 != null) return nested2;
    } catch (_) {}

    return null;
  }

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  String _fmtKey(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  DayRecord? _dayRecord(DateTime date) {
    final key = _fmtKey(_dateOnly(date));
    return _monthly?.days[key];
  }

  DayRecord? _findDayRecord(DateTime date) {
    final monthKey = _monthKey(date);
    final monthly = _monthCache[monthKey];
    if (monthly == null) return null;

    final dayKey = _fmtKey(_dateOnly(date));
    return monthly.days[dayKey];
  }

  List<RecordEntry> entriesForDay(int day) {
    final date = DateTime(selectedYear, selectedMonth, day);
    final ds = _dayRecord(date);
    return ds?.spendingEntries ?? const [];
  }

  int spendingForDay(int day) {
    final date = DateTime(selectedYear, selectedMonth, day);
    final ds = _dayRecord(date);
    if (ds == null) return 0;
    return ds.totalSpendingAmount;
  }

  bool hasEmotionRecord(int day) {
    final date = DateTime(selectedYear, selectedMonth, day);
    final emotion = _dayRecord(date)?.emotion ?? '';
    return emotion.trim().isNotEmpty;
  }

  bool hasAmountRecord(int day) {
    return spendingForDay(day) > 0;
  }

  bool hasDiaryRecord(int day) {
    final date = DateTime(selectedYear, selectedMonth, day);
    final comment = _dayRecord(date)?.comment ?? '';
    return comment.trim().isNotEmpty;
  }

  bool hasRecord(int day) {
    return hasEmotionRecord(day) || hasAmountRecord(day) || hasDiaryRecord(day);
  }

  int spendingAmountForDay(int day) => spendingForDay(day);

  String emotionLabelForDay(int day) {
    final date = DateTime(selectedYear, selectedMonth, day);
    return _dayRecord(date)?.emotion ?? '';
  }

  String emotionEmojiForDay(int day) {
    final date = DateTime(selectedYear, selectedMonth, day);
    final emotion = _dayRecord(date)?.emotion ?? '';
    if (emotion.trim().isEmpty) return '';
    return getEmoji(emotion);
  }

  String diaryForDay(int day) {
    final date = DateTime(selectedYear, selectedMonth, day);
    final comment = _dayRecord(date)?.comment ?? '';
    if (comment.trim().isEmpty) return '소비 일지가 아직 없어요.';
    return comment;
  }

  static const List<String> emotionList = [
    '평온',
    '좋음',
    '슬픔',
    '스트레스',
    '동기부여',
    '아무 감정 없음',
  ];

  String getEmoji(String emotion) {
    switch (emotion) {
      case '평온':
        return '😌';
      case '좋음':
        return '😊';
      case '슬픔':
        return '😢';
      case '스트레스':
        return '😣';
      case '동기부여':
        return '🔥';
      case '아무 감정 없음':
        return '🙂';
      default:
        return '🙂';
    }
  }

  String emotionEmojiForAnalysis(String emotion) => getEmoji(emotion);

  String _monthKey(DateTime d) => DateFormat('yyyy-MM').format(d);

  Future<void> _ensureMonthLoaded(DateTime anyDay) async {
    final key = _monthKey(anyDay);
    if (_monthCache.containsKey(key)) return;

    final monthAnchor = DateTime(anyDay.year, anyDay.month, 1);
    final monthly = await _recordRepository.loadMonthlyRecordByDate(monthAnchor);
    _monthCache[key] = monthly;
  }

  Future<void> _preloadMonthsForRecentPeriod({required int days}) async {
    final today = _dateOnly(DateTime.now());
    final start = today.subtract(Duration(days: days - 1));

    DateTime cursor = DateTime(start.year, start.month, 1);
    final endMonth = DateTime(today.year, today.month, 1);

    while (!cursor.isAfter(endMonth)) {
      await _ensureMonthLoaded(cursor);
      cursor = DateTime(cursor.year, cursor.month + 1, 1);
    }
  }

  Future<void> _preloadMonthsForPlanPeriod(DateTime planStart) async {
    final today = _dateOnly(DateTime.now());

    DateTime cursor = DateTime(planStart.year, planStart.month, 1);
    final endMonth = DateTime(today.year, today.month, 1);

    while (!cursor.isAfter(endMonth)) {
      await _ensureMonthLoaded(cursor);
      cursor = DateTime(cursor.year, cursor.month + 1, 1);
    }
  }

  List<DayRecord> _daysInRecentPeriod(String period) {
    final today = _dateOnly(DateTime.now());
    final int days = (period == '주간') ? 7 : 30;
    final start = today.subtract(Duration(days: days - 1));

    final List<DayRecord> out = [];

    for (final m in _monthCache.values) {
      for (final d in m.days.values) {
        final date = _dateOnly(d.date);
        if (!date.isBefore(start) && !date.isAfter(today)) {
          out.add(d);
        }
      }
    }

    out.sort((a, b) => a.date.compareTo(b.date));
    return out;
  }

  List<DayRecord> _daysInPlanFullPeriod() {
    final today = _dateOnly(DateTime.now());
    final start = _planStartDate ?? today;

    final List<DayRecord> out = [];

    for (final m in _monthCache.values) {
      for (final d in m.days.values) {
        final date = _dateOnly(d.date);
        if (!date.isBefore(start) && !date.isAfter(today)) {
          out.add(d);
        }
      }
    }

    out.sort((a, b) => a.date.compareTo(b.date));
    return out;
  }

  int emotionCount(String emotion, String period) {
    final days = _daysInRecentPeriod(period);
    return days.where((d) => d.emotion.trim() == emotion).length;
  }

  int emotionTotalSpending(String emotion, String period) {
    final days =
    _daysInRecentPeriod(period).where((d) => d.emotion.trim() == emotion);

    return days.fold<int>(0, (sum, d) {
      return sum + d.totalSpendingAmount;
    });
  }

  int emotionSpendingAmount(String emotion, String period) {
    return emotionTotalSpending(emotion, period);
  }

  List<Map<String, dynamic>> emotionTop3Stats(String period) {
    final list = <Map<String, dynamic>>[];

    for (final e in emotionList) {
      final count = emotionCount(e, period);
      if (count == 0) continue;

      final total = emotionTotalSpending(e, period);
      final avg = (total / count).round();

      list.add({
        'emotion': e,
        'emoji': getEmoji(e),
        'count': count,
        'total': total,
        'avg': avg,
      });
    }

    list.sort((a, b) => (b['total'] as int).compareTo(a['total'] as int));

    return list.take(3).toList();
  }

  void setAnalysisEmotion(String emotion) {
    selectedEmotionForAnalysis = emotion;
    notifyListeners();
  }

  void setAnalysisPeriod(String period) {
    selectedAnalysisPeriod = period;
    _preloadMonthsForRecentPeriod(days: period == '주간' ? 7 : 30);
    notifyListeners();
  }

  List<Map<String, dynamic>> get bannerInsights {
    final days = _daysInPlanFullPeriod();
    final emotionCategoryMap = <String, Map<String, int>>{};

    for (final d in days) {
      final emotion = d.emotion.trim();
      if (emotion.isEmpty) continue;
      if (d.spendingEntries.isEmpty) continue;

      for (final e in d.spendingEntries) {
        final category = e.category.trim().isNotEmpty ? e.category.trim() : '기타';

        emotionCategoryMap[emotion] ??= {};
        emotionCategoryMap[emotion]![category] =
            (emotionCategoryMap[emotion]![category] ?? 0) + e.amount.round();
      }
    }

    final List<Map<String, dynamic>> result = [];

    for (final emotion in emotionList) {
      final categoryMap = emotionCategoryMap[emotion];
      if (categoryMap == null || categoryMap.isEmpty) continue;

      final top = categoryMap.entries.reduce(
            (a, b) => a.value >= b.value ? a : b,
      );

      result.add({
        'title':
        '${_emotionToSentence(emotion)} ${top.key} 소비가 많아요 ${getEmoji(emotion)}',
        'icon': Icons.mood,
        'color': _emotionColor(emotion),
      });
    }

    if (result.isEmpty) {
      result.add({
        'title': '소비 기록이 쌓이면 감정별 소비 패턴을 알려드릴게요.',
        'icon': Icons.mood,
        'color': const Color(0xFF0062FF),
      });
    }

    return result;
  }

  String _emotionToSentence(String emotion) {
    switch (emotion) {
      case '좋음':
        return '기쁠 때는';
      case '평온':
        return '평온할 때는';
      case '슬픔':
        return '슬플 때는';
      case '스트레스':
        return '스트레스 받을 때는';
      case '동기부여':
        return '동기부여가 될 때는';
      case '아무 감정 없음':
        return '무덤덤할 때는';
      default:
        return '$emotion일 때는';
    }
  }

  Color _emotionColor(String emotion) {
    switch (emotion) {
      case '좋음':
        return const Color(0xFFFFC107);
      case '평온':
        return const Color(0xFF4CAF50);
      case '슬픔':
        return const Color(0xFF2196F3);
      case '스트레스':
        return const Color(0xFFF44336);
      case '동기부여':
        return const Color(0xFF9C27B0);
      case '아무 감정 없음':
        return const Color(0xFF9E9E9E);
      default:
        return const Color(0xFF0062FF);
    }
  }

  String getMonthlyInsightMessage() {
    final summary = monthlyEmotionSummary();
    return summary['message'] ?? '이번 달을 기록해보세요!';
  }

  Map<String, dynamic> monthlyEmotionSummary({DateTime? anchor}) {
    if (_monthly == null) {
      return {
        'happy': 0,
        'normal': 0,
        'gloomy': 0,
        'message': '이번 달을 기록해보세요!',
      };
    }

    final now = anchor ?? DateTime(selectedYear, selectedMonth);
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 1);

    final days = _monthly!.days.values.where((d) {
      final date = _dateOnly(d.date);
      return !date.isBefore(monthStart) && date.isBefore(monthEnd);
    });

    int happy = 0, normal = 0, gloomy = 0;

    for (final d in days) {
      final emo = d.emotion.trim();
      if (emo.isEmpty) continue;

      if (emo == '좋음' || emo == '동기부여') {
        happy++;
      } else if (emo == '평온' || emo == '아무 감정 없음') {
        normal++;
      } else if (emo == '슬픔' || emo == '스트레스') {
        gloomy++;
      }
    }

    String message;
    if (happy > gloomy && happy > normal) {
      message = '긍정적인 한 달을 보내고 계시네요! 😊';
    } else if (gloomy > happy && gloomy > normal) {
      message = '조금 힘든 한 달이었네요 🥲';
    } else {
      message = '안정적인 한 달이에요 😌';
    }

    return {
      'happy': happy,
      'normal': normal,
      'gloomy': gloomy,
      'message': message,
    };
  }

  void _setLoading(bool v) {
    _isLoading = v;
  }

  void _setError(String? msg) {
    _error = msg;
  }

  @override
  void dispose() {
    _eventSub.cancel();
    super.dispose();
  }
}