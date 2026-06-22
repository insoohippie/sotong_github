// lib/services/notification_generate_service.dart

import 'package:intl/intl.dart';

import '../model/notification/notification_item.dart';
import '../model/record/day_record.dart';
import '../model/record/monthly_record.dart';
import '../model/plan/total_plan.dart';
import '../model/refData/ref_data.dart';

import '../repository/notification_repository.dart';
import '../repository/record_repository.dart';
import '../repository/ref_data_repository.dart';
import '../repository/plan_repository.dart';

class NotificationGenerateService {
  NotificationGenerateService(
      this._notificationRepo,
      this._recordRepo,
      this._refRepo,
      this._planRepo,
      );

  final NotificationRepository _notificationRepo;
  final RecordRepository _recordRepo;
  final RefDataRepository _refRepo;
  final PlanRepository _planRepo;

  final DateFormat _dateKeyFormat = DateFormat('yyyy-MM-dd');
  final DateFormat _monthKeyFormat = DateFormat('yyyy-MM');
  final NumberFormat _moneyFormat = NumberFormat('#,###');

  final Map<String, MonthlyRecord> _monthCache = {};

  TotalPlan? _latestPlan;
  RefData? _refData;

  Future<void> runDailyCheckIfNeeded() async {
    final now = DateTime.now();
    final today = _dateOnly(now);

    await _loadBaseData();

    await _ensureMonthLoaded(today);
    await _ensureMonthLoaded(today.subtract(const Duration(days: 1)));

    await _ensureTodayAttendanceNotification(now);
    await _ensureYesterdayAbsenceNotification(now);
  }

  Future<void> generateAfterRecordChanged() async {
    final now = DateTime.now();
    final today = _dateOnly(now);

    await _loadBaseData();

    final fullRange = _planFullRange(today);
    final recent7Range = _recent7Range(today);

    await _ensureMonthsLoadedForRange(fullRange);
    await _ensureMonthsLoadedForRange(recent7Range);
    await _ensureMonthLoaded(today);

// 기록 완료된 날짜라면 "오늘 기록하셨나요?" 출석 알림 제거
    await _removeRecordReminderIfRecorded(today);

    await _upsertBudgetNotification(today, now);
    await _upsertReportNotifications(fullRange, recent7Range, now);
    await _upsertEmotionNotifications(fullRange, recent7Range, now);
  }

  Future<void> generateAfterPlanCreated() async {
    final now = DateTime.now();
    await _loadBaseData();
    await _ensureTodayAttendanceNotification(now);
  }

  Future<void> _loadBaseData() async {
    _monthCache.clear();

    _latestPlan = await _planRepo.getLatestPlanForCurrentUser();
    _refData = await _refRepo.loadAll();
  }

  Future<void> _ensureTodayAttendanceNotification(DateTime now) async {
    final today = _dateOnly(now);

    if (_isBeforePlanStart(today)) return;

    final todayRecord = _findDayRecord(today);
    if (_hasRealRecord(todayRecord)) return;

    final id = 'record_today_${_dateKeyFormat.format(today)}';

    if (_notificationRepo.exists(id)) return;

    await _notificationRepo.upsertKeepingCreatedAt(
      NotificationItem(
        id: id,
        title: _getTitleByType(NotificationType.recordReminder),
        message: '오늘 소비 기록하셨나요? ✍️ 하루 한 번, 출석 체크처럼 기록해보세요!',
        type: NotificationType.recordReminder,
        category: NotificationCategory.attendance,
        createdAt: now,
        targetRoute: '/record',
        targetDate: today,
      ),
    );
  }

  Future<void> _removeRecordReminderIfRecorded(DateTime date) async {
    final day = _findDayRecord(date);

    if (!_hasRealRecord(day)) return;

    final todayId = 'record_today_${_dateKeyFormat.format(date)}';
    await _notificationRepo.remove(todayId);
  }

  Future<void> _ensureYesterdayAbsenceNotification(DateTime now) async {
    final today = _dateOnly(now);
    final yesterday = today.subtract(const Duration(days: 1));

    if (_isBeforePlanStart(yesterday)) return;

    final yesterdayRecord = _findDayRecord(yesterday);
    if (_hasRealRecord(yesterdayRecord)) return;

    final id = 'record_yesterday_${_dateKeyFormat.format(yesterday)}';

    if (_notificationRepo.exists(id)) return;

    await _notificationRepo.upsertKeepingCreatedAt(
      NotificationItem(
        id: id,
        title: _getTitleByType(NotificationType.recordReminder),
        message: '앗! 어제 소비 기록을 깜빡하신 것 같아요. 지금 추가해볼까요?',
        type: NotificationType.recordReminder,
        category: NotificationCategory.attendance,
        createdAt: now,
        targetRoute: '/record',
        targetDate: yesterday,
      ),
    );
  }

  Future<void> _upsertBudgetNotification(DateTime today, DateTime now) async {
    final planned = _plannedDailyAmountOn(today);
    final spent = _spentOnDate(today);

    if (planned <= 0) return;

    if (spent > planned) {
      final over = spent - planned;

      await _notificationRepo.upsertKeepingCreatedAt(
        NotificationItem(
          id: 'budget_over_${_dateKeyFormat.format(today)}',
          title: _getTitleByType(NotificationType.timeValue),
          message: '오늘 소비가 일일 목표보다 ${_formatWon(over)} 많아요. 소비 흐름을 한 번 점검해볼까요?',
          type: NotificationType.timeValue,
          category: NotificationCategory.home,
          createdAt: now,
          targetRoute: '/today_record',
          targetDate: today,
        ),
      );
    } else if (spent > 0 && spent <= planned) {
      final saved = planned - spent;

      await _notificationRepo.upsertKeepingCreatedAt(
        NotificationItem(
          id: 'budget_saved_${_dateKeyFormat.format(today)}',
          title: _getTitleByType(NotificationType.timeValue),
          message: '오늘은 목표 안에서 소비했어요! ${_formatWon(saved)} 여유가 남았어요 🎯',
          type: NotificationType.timeValue,
          category: NotificationCategory.home,
          createdAt: now,
          targetRoute: '/today_record',
          targetDate: today,
        ),
      );
    }
  }

  Future<void> _upsertReportNotifications(
      _NotificationRange fullRange,
      _NotificationRange recent7Range,
      DateTime now,
      ) async {
    final today = _dateOnly(now);

    final recentTop = _topCategoryStatsInRange(recent7Range);
    final fullTop = _topCategoryStatsInRange(fullRange);

    if (recentTop != null) {
      await _notificationRepo.upsertKeepingCreatedAt(
        NotificationItem(
          id: 'report_recent7_${_dateKeyFormat.format(today)}',
          title: _getTitleByType(NotificationType.report),
          message:
          '최근 7일 동안 ${recentTop.name} 지출이 가장 많아요. 평균 ${_formatWon(recentTop.avg)} 사용했어요.',
          type: NotificationType.report,
          category: NotificationCategory.report,
          createdAt: now,
          targetRoute: '/home_tab_navigator',
          targetTabIndex: 0,
        ),
      );
    }

    if (fullTop != null) {
      await _notificationRepo.upsertKeepingCreatedAt(
        NotificationItem(
          id: 'report_full_${_dateKeyFormat.format(today)}',
          title: _getTitleByType(NotificationType.report),
          message: '플랜 기간 동안 ${fullTop.name} 소비가 가장 많아요. 소비 패턴을 확인해보세요.',
          type: NotificationType.report,
          category: NotificationCategory.report,
          createdAt: now,
          targetRoute: '/home_tab_navigator',
          targetTabIndex: 0,
        ),
      );
    }
  }

  Future<void> _upsertEmotionNotifications(
      _NotificationRange fullRange,
      _NotificationRange recent7Range,
      DateTime now,
      ) async {
    final today = _dateOnly(now);

    final recentEmotion = _topEmotionInRange(recent7Range);
    final categoryEmotion = _topCategoryEmotionInRange(fullRange);

    if (recentEmotion != null) {
      await _notificationRepo.upsertKeepingCreatedAt(
        NotificationItem(
          id: 'emotion_recent7_${_dateKeyFormat.format(today)}',
          title: _getTitleByType(NotificationType.emotion),
          message:
          '최근 7일 동안 ${recentEmotion.emotion} 감정이 가장 많아요. 이번 주 감정 흐름을 돌아볼까요?',
          type: NotificationType.emotion,
          category: NotificationCategory.communication,
          createdAt: now,
          targetRoute: '/home_tab_navigator',
          targetTabIndex: 2,
        ),
      );
    }

    if (categoryEmotion != null) {
      await _notificationRepo.upsertKeepingCreatedAt(
        NotificationItem(
          id: 'emotion_category_${_dateKeyFormat.format(today)}',
          title: _getTitleByType(NotificationType.emotion),
          message:
          '${categoryEmotion.category} 소비를 할 때 ${categoryEmotion.emotion}을 많이 느끼는 편이에요.',
          type: NotificationType.emotion,
          category: NotificationCategory.communication,
          createdAt: now,
          targetRoute: '/home_tab_navigator',
          targetTabIndex: 2,
        ),
      );
    }
  }

  DayRecord? _findDayRecord(DateTime date) {
    final monthKey = _monthKeyFormat.format(DateTime(date.year, date.month, 1));
    final monthly = _monthCache[monthKey];
    if (monthly == null) return null;

    final dateKey = _dateKeyFormat.format(_dateOnly(date));
    return monthly.days[dateKey];
  }

  bool _hasRealRecord(DayRecord? day) {
    if (day == null) return false;
    if (day.isAutoGenerated) return false;

    return day.spendingEntries.isNotEmpty ||
        day.incomeEntries.isNotEmpty ||
        day.emotion.trim().isNotEmpty ||
        day.comment.trim().isNotEmpty;
  }

  int _spentOnDate(DateTime date) {
    final day = _findDayRecord(date);
    if (day == null) return 0;

    return day.spendingEntries.fold<int>(
      0,
          (sum, e) => sum + e.amount.round(),
    );
  }

  int _plannedDailyAmountOn(DateTime date) {
    final refData = _refData;
    if (refData == null) return 0;

    final day = _dateOnly(date);
    int total = 0;

    for (final dc in refData.dailyConsumeMap.values) {
      if (!dc.isActive) continue;

      final start = _dateOnly(dc.startDate);
      final end = _dateOnly(dc.endDate);

      if (day.isBefore(start) || day.isAfter(end)) continue;

      for (final e in dc.entries) {
        total += e.amount.round();
      }
    }

    return total;
  }

  ({String name, int total, int avg})? _topCategoryStatsInRange(
      _NotificationRange range,
      ) {
    const etcKey = 'etc';

    final spentByKey = <String, int>{};
    final nameByKey = <String, String>{};
    final activeDaysByKey = <String, int>{};

    DateTime cursor = _dateOnly(range.start);

    while (!cursor.isAfter(range.end)) {
      final day = _findDayRecord(cursor);

      if (day != null) {
        final daySumByKey = <String, int>{};

        for (final e in day.spendingEntries) {
          final key =
          e.categoryKey.trim().isEmpty ? etcKey : e.categoryKey.trim();

          daySumByKey[key] = (daySumByKey[key] ?? 0) + e.amount.round();

          final name = e.category.trim();
          if (name.isNotEmpty) {
            nameByKey[key] = name;
          }
        }

        for (final entry in daySumByKey.entries) {
          spentByKey[entry.key] = (spentByKey[entry.key] ?? 0) + entry.value;
          if (entry.value > 0) {
            activeDaysByKey[entry.key] =
                (activeDaysByKey[entry.key] ?? 0) + 1;
          }
        }
      }

      cursor = cursor.add(const Duration(days: 1));
    }

    if (spentByKey.isEmpty) return null;

    final top = spentByKey.entries.reduce(
          (a, b) => a.value >= b.value ? a : b,
    );

    final key = top.key;
    final total = top.value;
    final activeDays = activeDaysByKey[key] ?? 1;
    final avg = (total / activeDays).round();

    final name = nameByKey[key] ?? (key == etcKey ? '기타' : key);

    return (name: name, total: total, avg: avg);
  }

  ({String emotion, int count})? _topEmotionInRange(
      _NotificationRange range,
      ) {
    final emotionCount = <String, int>{};

    DateTime cursor = _dateOnly(range.start);

    while (!cursor.isAfter(range.end)) {
      final day = _findDayRecord(cursor);
      final emotion = day?.emotion.trim() ?? '';

      if (emotion.isNotEmpty) {
        emotionCount[emotion] = (emotionCount[emotion] ?? 0) + 1;
      }

      cursor = cursor.add(const Duration(days: 1));
    }

    if (emotionCount.isEmpty) return null;

    final top = emotionCount.entries.reduce(
          (a, b) => a.value >= b.value ? a : b,
    );

    return (emotion: top.key, count: top.value);
  }

  ({String category, String emotion, int count})? _topCategoryEmotionInRange(
      _NotificationRange range,
      ) {
    final categoryEmotionCount = <String, Map<String, int>>{};

    DateTime cursor = _dateOnly(range.start);

    while (!cursor.isAfter(range.end)) {
      final day = _findDayRecord(cursor);

      if (day == null) {
        cursor = cursor.add(const Duration(days: 1));
        continue;
      }

      final emotion = day.emotion.trim();

      if (emotion.isEmpty || day.spendingEntries.isEmpty) {
        cursor = cursor.add(const Duration(days: 1));
        continue;
      }

      for (final e in day.spendingEntries) {
        final category =
        e.category.trim().isNotEmpty ? e.category.trim() : '기타';

        categoryEmotionCount[category] ??= {};
        categoryEmotionCount[category]![emotion] =
            (categoryEmotionCount[category]![emotion] ?? 0) + 1;
      }

      cursor = cursor.add(const Duration(days: 1));
    }

    if (categoryEmotionCount.isEmpty) return null;

    String? bestCategory;
    String? bestEmotion;
    int bestCount = 0;

    for (final categoryEntry in categoryEmotionCount.entries) {
      final emotionMap = categoryEntry.value;
      if (emotionMap.isEmpty) continue;

      final topEmotionForCategory = emotionMap.entries.reduce(
            (a, b) => a.value >= b.value ? a : b,
      );

      if (topEmotionForCategory.value > bestCount) {
        bestCount = topEmotionForCategory.value;
        bestCategory = categoryEntry.key;
        bestEmotion = topEmotionForCategory.key;
      }
    }

    if (bestCategory == null || bestEmotion == null) return null;

    return (
    category: bestCategory,
    emotion: bestEmotion,
    count: bestCount,
    );
  }

  _NotificationRange _recent7Range(DateTime today) {
    return _NotificationRange(
      start: today.subtract(const Duration(days: 6)),
      end: today,
    );
  }

  _NotificationRange _planFullRange(DateTime today) {
    final start = _latestPlan?.startDate;

    if (start == null) {
      return _NotificationRange(start: today, end: today);
    }

    return _NotificationRange(
      start: _dateOnly(start),
      end: today,
    );
  }

  Future<void> _ensureMonthsLoadedForRange(_NotificationRange range) async {
    final months = _monthsCovered(range.start, range.end);

    for (final month in months) {
      await _ensureMonthLoaded(month);
    }
  }

  Future<void> _ensureMonthLoaded(DateTime anyDay) async {
    final monthAnchor = DateTime(anyDay.year, anyDay.month, 1);
    final monthKey = _monthKeyFormat.format(monthAnchor);

    if (_monthCache.containsKey(monthKey)) return;

    final monthly = await _recordRepo.loadMonthlyRecordByDate(monthAnchor);
    _monthCache[monthKey] = monthly;
  }

  List<DateTime> _monthsCovered(DateTime start, DateTime end) {
    final result = <DateTime>[];

    var cursor = DateTime(start.year, start.month, 1);
    final endMonth = DateTime(end.year, end.month, 1);

    while (!cursor.isAfter(endMonth)) {
      result.add(cursor);
      cursor = DateTime(cursor.year, cursor.month + 1, 1);
    }

    return result;
  }

  bool _isBeforePlanStart(DateTime date) {
    final start = _latestPlan?.startDate;
    if (start == null) return false;

    return _dateOnly(date).isBefore(_dateOnly(start));
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  String _formatWon(int amount) {
    return '${_moneyFormat.format(amount)}원';
  }

  Future<void> generateInitialBackfill() async {
    await runDailyCheckIfNeeded();
    await generateAfterRecordChanged();
  }

  String _getTitleByType(NotificationType type) {
    switch (type) {
      case NotificationType.recordReminder:
        return '출석 알림';
      case NotificationType.timeValue:
        return '예산 알림';
      case NotificationType.report:
        return '레포트 알림';
      case NotificationType.emotion:
        return '소통 알림';
    }
  }
}

class _NotificationRange {
  const _NotificationRange({
    required this.start,
    required this.end,
  });

  final DateTime start;
  final DateTime end;
}