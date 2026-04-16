import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../model/record/record_entry.dart';
import '../../repository/record_repository.dart';
import '../../services/record_event_bus.dart';

class RecordSpendingViewModel extends ChangeNotifier {
  final RecordRepository _recordRepo;
  final RecordEventBus _recordEventBus;

  RecordSpendingViewModel(
      this._recordRepo,
      this._recordEventBus,
      ) {
    addEntry();
  }

  List<Map<String, dynamic>> spendingEntries = [];
  String? selectedEmotion;
  TextEditingController commentController = TextEditingController();

  int _entryCounter = 0;

  String _newEntryId() {
    final us = DateTime.now().microsecondsSinceEpoch;
    _entryCounter = (_entryCounter + 1) % 1000000;
    return 'entry_${us}_$_entryCounter';
  }

  void addEntry() {
    final amountController = TextEditingController();
    final noteController = TextEditingController();

    amountController.addListener(updateTotal);

    spendingEntries.add({
      'id': _newEntryId(),
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
    final amountCtrl = entry['amountController'] as TextEditingController?;
    final noteCtrl = entry['noteController'] as TextEditingController?;

    amountCtrl?.dispose();
    noteCtrl?.dispose();

    spendingEntries.remove(entry);
    notifyListeners();
  }

  void resetSpending() {
    for (final entry in spendingEntries) {
      final amountCtrl = entry['amountController'] as TextEditingController?;
      final noteCtrl = entry['noteController'] as TextEditingController?;
      amountCtrl?.dispose();
      noteCtrl?.dispose();
    }

    spendingEntries.clear();

    final amountController = TextEditingController();
    final noteController = TextEditingController();

    amountController.addListener(updateTotal);

    spendingEntries.add({
      'id': _newEntryId(),
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

  bool get hasInvalidCategorySelection {
    for (final entry in spendingEntries) {
      final amount = (entry['amount'] as num?)?.toDouble() ?? 0.0;
      final categoryKey = (entry['categoryKey'] as String?)?.trim() ?? '';

      if (amount > 0 && categoryKey.isEmpty) {
        return true;
      }
    }
    return false;
  }

  bool get canProceedToNextStep {
    final hasAmount = spendingEntries.any(
          (e) => ((e['amount'] as num?)?.toDouble() ?? 0) > 0,
    );

    return hasAmount && !hasInvalidCategorySelection;
  }

  void updateTotal() => notifyListeners();

  void setEmotion(String emotion) {
    selectedEmotion = emotion;
    notifyListeners();
  }

  void resetEmotion() {
    selectedEmotion = null;
    commentController.clear();
    notifyListeners();
  }

  void resetAllForNewDate() {
    resetSpending();
    resetEmotion();
  }

  List<Map<String, dynamic>> _buildEntriesJson() {
    final List<Map<String, dynamic>> entriesJson = [];

    for (final entry in spendingEntries) {
      final id = (entry['id'] as String?)?.trim() ?? '';
      final categoryKey = (entry['categoryKey'] as String?)?.trim() ?? '';
      final category = entry['category'] as String? ?? '';
      final amount = (entry['amount'] as num?)?.toDouble() ?? 0.0;
      final note = entry['note'] as String? ?? '';

      if (amount <= 0 && category.isEmpty && note.isEmpty) continue;

      entriesJson.add({
        'id': id,
        'categoryKey': categoryKey,
        'category': category,
        'amount': amount,
        'note': note,
      });
    }

    return entriesJson;
  }

  Future<void> saveAllForDate(DateTime date) async {
    if (hasInvalidCategorySelection) {
      throw Exception('카테고리가 선택되지 않은 소비 항목이 있습니다.');
    }

    final entries = spendingEntries
        .where((entry) {
      final amount = (entry['amount'] as num?)?.toDouble() ?? 0.0;
      final category = (entry['category'] as String? ?? '').trim();
      final note = (entry['note'] as String? ?? '').trim();

      return amount > 0 || category.isNotEmpty || note.isNotEmpty;
    })
        .map((entry) {
      final rawId = (entry['id'] as String?)?.trim();
      final categoryKey = (entry['categoryKey'] as String?)?.trim() ?? '';
      final category = entry['category'] as String? ?? '';
      final amount = (entry['amount'] as num?)?.toDouble() ?? 0.0;
      final note = entry['note'] as String? ?? '';

      return RecordEntry(
        id: (rawId == null || rawId.isEmpty) ? _newEntryId() : rawId,
        categoryKey: categoryKey,
        category: category,
        amount: amount,
        note: note,
      );
    })
        .toList();

    await _recordRepo.upsertSpendingForDate(
      date: date,
      spendingEntries: entries,
      totalSpendingAmount: totalSpending,
      emotion: selectedEmotion ?? '',
      comment: commentController.text,
    );

    debugPrint(
      '[RecordSpendingViewModel] saveAllForDate '
          '(date=$date, localMode=${_recordRepo.localMode})',
    );

    _recordEventBus.fire(RecordUpdatedEvent(date));
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