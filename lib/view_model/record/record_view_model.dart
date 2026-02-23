import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../model/record/day_spending.dart';
import '../../model/record/spending_entry.dart';
import '../../repository/record_repository.dart';
import '../../services/spending_event_bus.dart';

class RecordViewModel extends ChangeNotifier {
  final RecordRepository _recordRepo;

  final SpendingEventBus _spendingEventBus;

  RecordViewModel(
      this._recordRepo,
      this._spendingEventBus,
      ) {
    addEntry(); // 기본 한 줄
  }

  List<Map<String, dynamic>> spendingEntries = [];
  String? selectedEmotion;
  TextEditingController commentController = TextEditingController();

  void addEntry() {
    final amountController = TextEditingController();
    final noteController = TextEditingController();

    amountController.addListener(updateTotal);

    spendingEntries.add({
      'categoryKey': '',
      'category': '',
      'amountController': amountController,
      'noteController': noteController,
      'amount': 0.0,
      'note': '',
    });
    notifyListeners();
  }

  void removeEntryByRef(Map<String, dynamic> entry) {
    spendingEntries.remove(entry);
    notifyListeners();
  }

  /// 소비 / 카테고리 / 금액 / 노트 전부 초기화
  void resetSpending() {
    // 기존 컨트롤러 정리
    for (final entry in spendingEntries) {
      final amountCtrl = entry['amountController'] as TextEditingController?;
      final noteCtrl = entry['noteController'] as TextEditingController?;
      amountCtrl?.dispose();
      noteCtrl?.dispose();
    }

    spendingEntries.clear();

    // 완전 새 엔트리 하나 추가 (카테고리도 빈 상태)
    final amountController = TextEditingController();
    final noteController = TextEditingController();

    amountController.addListener(updateTotal);

    spendingEntries.add({
      'categoryKey': '',
      'category': '',
      'amountController': amountController,
      'noteController': noteController,
      'amount': 0.0,
      'note': '',
    });

    notifyListeners();
  }

  int get totalSpending {
    return spendingEntries.fold(0, (sum, e) {
      final amount = (e['amount'] as num?)?.toInt() ?? 0;
      return sum + amount;
    });
  }

  String get formattedTotal => NumberFormat('#,###').format(totalSpending);

  void updateTotal() => notifyListeners();

  void setEmotion(String emotion) {
    selectedEmotion = emotion;
    notifyListeners();
  }

  /// 감정 + 코멘트 초기화
  void resetEmotion() {
    selectedEmotion = null;
    commentController.clear();
    notifyListeners();
  }

  /// “새 날짜 시작”할 때 한 번에 다 비우고 싶으면 이거 호출
  void resetAllForNewDate() {
    resetSpending();
    resetEmotion();
  }

  /// 🔹 (지금은 안 쓰고 있어서 남겨만 둔 헬퍼)
  List<Map<String, dynamic>> _buildEntriesJson() {
    final List<Map<String, dynamic>> entriesJson = [];

    for (final entry in spendingEntries) {
      final category = entry['category'] as String? ?? '';
      final amount = (entry['amount'] as num?)?.toDouble() ?? 0.0;
      final note = entry['note'] as String? ?? '';

      if (amount <= 0 && category.isEmpty && note.isEmpty) continue;

      entriesJson.add({
        'category': category,
        'amount': amount,
        'note': note,
      });
    }

    return entriesJson;
  }

  Future<void> saveAllForDate(DateTime date) async {
    final entries = spendingEntries.map((entry) {
      final categoryKey = entry['categoryKey'] as String? ?? ''; // ✅
      final category = entry['category'] as String? ?? '';
      final amount = (entry['amount'] as num?)?.toDouble() ?? 0.0;
      final note = entry['note'] as String? ?? '';

      return SpendingEntry(
        id: '', // id 없으면 fromMap에서 안정 id로 보정됨(혹은 여기서 생성해도 됨)
        categoryKey: categoryKey,
        category: category,
        amount: amount,
        note: note,
      );
    }).toList();

    final day = DaySpending(
      date: date,
      totalAmount: totalSpending,
      emotion: selectedEmotion ?? '',
      comment: commentController.text,
      entries: entries,
    );

    await _recordRepo.upsertDaySpending(day);
    _spendingEventBus.fire(SpendingUpdatedEvent(date));
  }

  @override
  void dispose() {
    for (final entry in spendingEntries) {
      (entry['amountController'] as TextEditingController?)?.dispose();
      (entry['noteController'] as TextEditingController?)?.dispose();
    }
    commentController.dispose();
    super.dispose();
  }
}
