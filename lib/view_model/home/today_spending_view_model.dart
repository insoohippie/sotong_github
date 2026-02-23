// lib/view_model/record/today_spending_view_model.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../model/record/day_spending.dart';
import '../../model/record/spending_entry.dart';
import '../../repository/record_repository.dart';
import '../../repository/plan_repository.dart';

class TodaySpendingViewModel extends ChangeNotifier {
  final RecordRepository _recordRepo;
  final PlanRepository _planRepo;

  TodaySpendingViewModel(this._recordRepo, this._planRepo);

  bool _isLoading = false;
  String? _error;
  bool get isLoading => _isLoading;
  String? get error => _error;

  DateTime? _date;
  DateTime? get date => _date;

  DaySpending? _day;
  DaySpending? get day => _day;

  List<SpendingEntry> get entries => _day?.entries ?? [];

  int get totalAmount {
    if (_day == null) return 0;
    final sum = _day!.entries.fold<double>(0, (s, e) => s + e.amount).round();
    return sum;
  }

  int _dailyLimit = 0;
  int get dailyLimit => _dailyLimit;

  int get diffAmount => totalAmount - _dailyLimit;

  String get emotion => _day?.emotion ?? '';
  String get comment => _day?.comment ?? '';

  /// ---- 로드 ----
  Future<void> load(DateTime date) async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _date = date;

      // 1) 월 데이터 로드 (오프라인 퍼스트)
      final month = await _recordRepo.loadMonthlySpendingByDate(date);

      final dateKey = DateFormat('yyyy-MM-dd').format(date);
      final loadedDay = month.days[dateKey];

      // 2) 해당 날짜 데이터가 없으면 빈 day 생성
      _day = loadedDay ??
          DaySpending(
            date: date,
            totalAmount: 0,
            emotion: '',
            comment: '',
            entries: const [],
          );

      // 3) 하루 한도 로드 (플랜에서)
      // final savingState = await _planRepo.getSavingStateForCurrentUser();
      _dailyLimit = await _readDailyLimitFallback();

      // totalAmount 정리
      _recalcTotal();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<int> _readDailyLimitFallback() async {
    try {
      final plan = await _planRepo.getLatestPlanForCurrentUser();
      final metrics = plan?.result.totalMetrics;
      if (metrics == null) return 0;
      return metrics.dailyConsumeAmount.round();
    } catch (_) {
      return 0;
    }
  }

  /// ---- entries CRUD ----
  Future<void> addEntry({
    required String categoryKey, // ✅ 추가
    required String category,    // 표시용
    required double amount,
    required String note,
  }) async {
    if (_day == null) return;

    final newEntry = SpendingEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      categoryKey: categoryKey,
      category: category,
      amount: amount,
      note: note,
    );

    final newEntries = [..._day!.entries, newEntry];

    _day = _day!.copyWith(
      entries: newEntries,
      totalAmount: newEntries.fold<double>(0, (s, e) => s + e.amount).round(),
    );
    notifyListeners();

    await _persist();
  }

  Future<void> updateEntry({
    required String entryId,
    required String categoryKey, // ✅ 추가
    required String category,
    required double amount,
    required String note,
  }) async {
    if (_day == null) return;

    final newEntries = _day!.entries.map((e) {
      if (e.id != entryId) return e;
      return e.copyWith(
        categoryKey: categoryKey,
        category: category,
        amount: amount,
        note: note,
      );
    }).toList();

    _day = _day!.copyWith(
      entries: newEntries,
      totalAmount: newEntries.fold<double>(0, (s, e) => s + e.amount).round(),
    );
    notifyListeners();

    await _persist();
  }

  Future<void> deleteEntry(String entryId) async {
    if (_day == null) return;

    final newEntries = _day!.entries.where((e) => e.id != entryId).toList();

    _day = _day!.copyWith(
      entries: newEntries,
      totalAmount: newEntries.fold<double>(0, (s, e) => s + e.amount).round(),
    );
    notifyListeners();

    await _persist();
  }

  Future<void> updateEmotionAndComment({
    required String emotion,
    required String comment,
  }) async {
    if (_day == null) return;

    _day = _day!.copyWith(emotion: emotion, comment: comment);
    notifyListeners();

    await _persist();
  }

  void _recalcTotal() {
    if (_day == null) return;
    final sum = _day!.entries.fold<double>(0, (s, e) => s + e.amount).round();
    _day = _day!.copyWith(totalAmount: sum);
  }

  Future<void> _persist() async {
    if (_day == null) return;
    await _recordRepo.upsertDaySpending(_day!);
  }
}
