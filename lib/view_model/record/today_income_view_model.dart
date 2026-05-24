import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../model/record/day_record.dart';
import '../../model/record/record_entry.dart';
import '../../repository/record_repository.dart';
import '../../services/record_event_bus.dart';

class TodayIncomeViewModel extends ChangeNotifier {
  final RecordRepository _recordRepo;
  final RecordEventBus _recordEventBus;

  TodayIncomeViewModel(this._recordRepo, this._recordEventBus);

  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  DateTime? _date;
  DayRecord? _savedDay;
  DayRecord? _draftDay;

  DateTime? get date => _date;
  DayRecord? get day => _draftDay;

  List<RecordEntry> get entries => _draftDay?.incomeEntries ?? const [];

  int get totalAmount {
    if (_draftDay == null) return 0;
    final sum = _draftDay!.incomeEntries
        .fold<double>(0, (s, e) => s + e.amount)
        .round();
    return sum;
  }

  bool get hasUnsavedChanges => _hasDraftChanged(_savedDay, _draftDay);
  bool get hasEntryChanges => hasUnsavedChanges;

  Future<void> load(DateTime date) async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _date = date;

      final month = await _recordRepo.loadMonthlyRecordByDate(date);
      final dateKey = DateFormat('yyyy-MM-dd').format(date);
      final loadedDay = month.days[dateKey];

      _savedDay = _cloneDay(loadedDay ?? DayRecord.empty(date));
      _draftDay = _cloneDay(_savedDay!);
      _recalcTotal();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addEntry({
    required String categoryKey,
    required String category,
    required double amount,
    required String note,
  }) async {
    if (_draftDay == null) return;

    final newEntry = RecordEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      categoryKey: categoryKey,
      category: category,
      amount: amount,
      note: note,
    );

    final newEntries = [..._draftDay!.incomeEntries, newEntry];

    _draftDay = _draftDay!.copyWith(
      incomeEntries: newEntries,
      totalIncomeAmount: newEntries
          .fold<double>(0, (s, e) => s + e.amount)
          .round(),
    );
    notifyListeners();
  }

  Future<void> updateEntry({
    required String entryId,
    required String categoryKey,
    required String category,
    required double amount,
    required String note,
  }) async {
    if (_draftDay == null) return;

    final newEntries = _draftDay!.incomeEntries.map((e) {
      if (e.id != entryId) return e;
      return e.copyWith(
        categoryKey: categoryKey,
        category: category,
        amount: amount,
        note: note,
      );
    }).toList();

    _draftDay = _draftDay!.copyWith(
      incomeEntries: newEntries,
      totalIncomeAmount: newEntries
          .fold<double>(0, (s, e) => s + e.amount)
          .round(),
    );
    notifyListeners();
  }

  Future<void> deleteEntry(String entryId) async {
    if (_draftDay == null) return;

    final newEntries = _draftDay!.incomeEntries
        .where((e) => e.id != entryId)
        .toList();

    _draftDay = _draftDay!.copyWith(
      incomeEntries: newEntries,
      totalIncomeAmount: newEntries
          .fold<double>(0, (s, e) => s + e.amount)
          .round(),
    );
    notifyListeners();
  }

  void _recalcTotal() {
    if (_draftDay == null) return;
    final sum = _draftDay!.incomeEntries
        .fold<double>(0, (s, e) => s + e.amount)
        .round();
    _draftDay = _draftDay!.copyWith(totalIncomeAmount: sum);
  }

  Future<void> saveDraft() async {
    if (_draftDay == null) return;

    final normalized = _recalculatedDay(_draftDay!);
    await _recordRepo.upsertIncomeForDate(
      date: normalized.date,
      incomeEntries: normalized.incomeEntries,
      totalIncomeAmount: normalized.totalIncomeAmount,
    );

    _savedDay = _cloneDay(normalized);
    _draftDay = _cloneDay(_savedDay!);
    notifyListeners();

    _recordEventBus.fire(RecordUpdatedEvent(normalized.date));
  }

  void discardDraft() {
    if (_savedDay == null) return;
    _draftDay = _cloneDay(_savedDay!);
    notifyListeners();
  }

  DayRecord _recalculatedDay(DayRecord day) {
    final total = day.incomeEntries
        .fold<double>(0, (sum, entry) => sum + entry.amount)
        .round();
    return day.copyWith(totalIncomeAmount: total);
  }

  DayRecord _cloneDay(DayRecord day) {
    return day.copyWith(
      spendingEntries: List<RecordEntry>.from(day.spendingEntries),
      incomeEntries: List<RecordEntry>.from(day.incomeEntries),
    );
  }

  bool _hasDraftChanged(DayRecord? saved, DayRecord? draft) {
    if (saved == null || draft == null) return false;
    if (saved.totalIncomeAmount != draft.totalIncomeAmount) return true;
    return !_sameEntries(saved.incomeEntries, draft.incomeEntries);
  }

  bool _sameEntries(List<RecordEntry> a, List<RecordEntry> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      final left = a[i];
      final right = b[i];
      if (left.id != right.id ||
          left.categoryKey != right.categoryKey ||
          left.category != right.category ||
          left.amount != right.amount ||
          left.note != right.note) {
        return false;
      }
    }
    return true;
  }
}
