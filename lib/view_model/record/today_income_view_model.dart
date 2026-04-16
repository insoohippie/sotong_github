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
  DayRecord? _day;

  DateTime? get date => _date;
  DayRecord? get day => _day;

  List<RecordEntry> get entries => _day?.incomeEntries ?? const [];

  int get totalAmount {
    if (_day == null) return 0;
    final sum = _day!.incomeEntries.fold<double>(0, (s, e) => s + e.amount).round();
    return sum;
  }

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

      _day = loadedDay ?? DayRecord.empty(date);
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
    if (_day == null) return;

    final newEntry = RecordEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      categoryKey: categoryKey,
      category: category,
      amount: amount,
      note: note,
    );

    final newEntries = [..._day!.incomeEntries, newEntry];

    _day = _day!.copyWith(
      incomeEntries: newEntries,
      totalIncomeAmount: newEntries.fold<double>(0, (s, e) => s + e.amount).round(),
    );
    notifyListeners();

    await _persist();
  }

  Future<void> updateEntry({
    required String entryId,
    required String categoryKey,
    required String category,
    required double amount,
    required String note,
  }) async {
    if (_day == null) return;

    final newEntries = _day!.incomeEntries.map((e) {
      if (e.id != entryId) return e;
      return e.copyWith(
        categoryKey: categoryKey,
        category: category,
        amount: amount,
        note: note,
      );
    }).toList();

    _day = _day!.copyWith(
      incomeEntries: newEntries,
      totalIncomeAmount: newEntries.fold<double>(0, (s, e) => s + e.amount).round(),
    );
    notifyListeners();

    await _persist();
  }

  Future<void> deleteEntry(String entryId) async {
    if (_day == null) return;

    final newEntries = _day!.incomeEntries.where((e) => e.id != entryId).toList();

    _day = _day!.copyWith(
      incomeEntries: newEntries,
      totalIncomeAmount: newEntries.fold<double>(0, (s, e) => s + e.amount).round(),
    );
    notifyListeners();

    await _persist();
  }

  void _recalcTotal() {
    if (_day == null) return;
    final sum = _day!.incomeEntries.fold<double>(0, (s, e) => s + e.amount).round();
    _day = _day!.copyWith(totalIncomeAmount: sum);
  }

  Future<void> _persist() async {
    if (_day == null) return;

    await _recordRepo.upsertIncomeForDate(
      date: _day!.date,
      incomeEntries: _day!.incomeEntries,
      totalIncomeAmount: _day!.totalIncomeAmount,
    );

    _recordEventBus.fire(RecordUpdatedEvent(_day!.date));
  }
}