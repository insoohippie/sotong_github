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
    // 1) VM 내부 entries → SpendingEntry 리스트로 변환
    final entries = spendingEntries.map((entry) {
      return SpendingEntry(
        category: entry['category'] as String? ?? '',
        amount: (entry['amount'] as num?)?.toDouble() ?? 0.0,
        note: entry['note'] as String? ?? '', id: '',
      );
    }).toList();

    // 2) DaySpending 도메인 모델 구성
    final day = DaySpending(
      date: date,
      totalAmount: totalSpending,
      emotion: selectedEmotion ?? '',
      comment: commentController.text,
      entries: entries,
    );

    // 3) Repository를 통해 Firestore의 users/{uid}/records/{yyyy-MM} 갱신
    await _recordRepo.upsertDaySpending(day);

    // 4) 🔥 소비가 저장되었음을 다른 뷰모델(레포트/소통)에 알리기
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
