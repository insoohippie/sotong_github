import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RecordViewModel extends ChangeNotifier {
  List<Map<String, dynamic>> spendingEntries = [];
  String? selectedEmotion;
  TextEditingController commentController = TextEditingController();

  RecordViewModel() {
    addEntry(); // 초기 항목 1개 추가
  }

  void addEntry() {
    final amountController = TextEditingController();
    final noteController = TextEditingController();

    amountController.addListener(updateTotal);

    spendingEntries.add({
      'category': null,
      'amountController': amountController,
      'noteController': noteController,
    });
    notifyListeners();
  }

  void removeEntryByRef(Map<String, dynamic> entry) {
    spendingEntries.remove(entry);
    notifyListeners();
  }

  void resetSpending() {
    for (final entry in spendingEntries) {
      entry['amountController'].dispose();
      entry['noteController'].dispose();
    }
    spendingEntries.clear();
    addEntry();
    notifyListeners();
  }

  int get totalSpending {
    return spendingEntries.fold(0, (sum, e) {
      final val =
          int.tryParse(e['amountController'].text.replaceAll(',', '')) ?? 0;
      return sum + val;
    });
  }

  String get formattedTotal => NumberFormat('#,###').format(totalSpending);

  void updateTotal() {
    notifyListeners(); // Selector에서 총합 업데이트용
  }

  void setEmotion(String emotion) {
    selectedEmotion = emotion;
    notifyListeners();
  }

  void resetEmotion() {
    selectedEmotion = null;
    notifyListeners();
  }

  void saveDiary() {
    final emotion = selectedEmotion;
    final comment = commentController.text;
    // TODO: Firestore 저장 로직
  }
}
