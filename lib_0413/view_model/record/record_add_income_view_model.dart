import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../model/record/record_entry.dart';
import '../../repository/record_repository.dart';

class RecordAddIncomeViewModel extends ChangeNotifier {
  final RecordRepository _recordRepo;

  RecordAddIncomeViewModel(this._recordRepo) {
    addEntry(); // 기본 한 줄
  }

  List<Map<String, dynamic>> incomeEntries = [];

  int _entryCounter = 0;

  String _newEntryId() {
    final us = DateTime.now().microsecondsSinceEpoch;
    _entryCounter = (_entryCounter + 1) % 1000000;
    return 'income_entry_${us}_$_entryCounter';
  }

  void addEntry() {
    final amountController = TextEditingController();
    final noteController = TextEditingController();

    amountController.addListener(updateTotal);

    incomeEntries.add({
      'id': _newEntryId(),
      'categoryKey': '',
      'category': '',
      'categorySource': null,
      'categoryEmoji': null,
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

    incomeEntries.remove(entry);
    notifyListeners();
  }

  /// 수입 / 카테고리 / 금액 / 노트 전부 초기화
  void resetIncome() {
    for (final entry in incomeEntries) {
      final amountCtrl = entry['amountController'] as TextEditingController?;
      final noteCtrl = entry['noteController'] as TextEditingController?;
      amountCtrl?.dispose();
      noteCtrl?.dispose();
    }

    incomeEntries.clear();

    final amountController = TextEditingController();
    final noteController = TextEditingController();

    amountController.addListener(updateTotal);

    incomeEntries.add({
      'id': _newEntryId(),
      'categoryKey': '',
      'category': '',
      'categorySource': null,
      'categoryEmoji': null,
      'amountController': amountController,
      'noteController': noteController,
      'amount': 0.0,
      'note': '',
    });

    resetApplyStates(notify: false);
    notifyListeners();
  }

  int get totalIncome {
    return incomeEntries.fold(0, (sum, e) {
      final amount = (e['amount'] as num?)?.toInt() ?? 0;
      return sum + amount;
    });
  }

  String get formattedTotal => NumberFormat('#,###').format(totalIncome);

  String get totalFormattedWithWon => '${formattedTotal}원';

  /// 금액이 있는 항목 중 카테고리 미선택 항목이 하나라도 있으면 true
  bool get hasInvalidCategorySelection {
    for (final entry in incomeEntries) {
      final amount = (entry['amount'] as num?)?.toDouble() ?? 0.0;
      final categoryKey = (entry['categoryKey'] as String?)?.trim() ?? '';

      if (amount > 0 && categoryKey.isEmpty) {
        return true;
      }
    }
    return false;
  }

  /// 수입 입력 페이지에서 다음 단계/저장 활성화 조건에 사용
  bool get canProceedToNextStep {
    final hasAmount = incomeEntries.any(
          (e) => ((e['amount'] as num?)?.toDouble() ?? 0) > 0,
    );

    return hasAmount && !hasInvalidCategorySelection;
  }

  void updateTotal() => notifyListeners();

  /// 디버그/확인용
  List<Map<String, dynamic>> buildEntriesJson() {
    final List<Map<String, dynamic>> entriesJson = [];

    for (final entry in incomeEntries) {
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
      throw Exception('카테고리가 선택되지 않은 수입 항목이 있습니다.');
    }

    final entries = incomeEntries.where((entry) {
      final amount = (entry['amount'] as num?)?.toDouble() ?? 0.0;
      final category = (entry['category'] as String? ?? '').trim();
      final note = (entry['note'] as String? ?? '').trim();

      return amount > 0 || category.isNotEmpty || note.isNotEmpty;
    }).map((entry) {
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
    }).toList();

    await _recordRepo.upsertIncomeForDate(
      date: date,
      incomeEntries: entries,
      totalIncomeAmount: totalIncome,
    );
  }

  // =========================================================
  // 추가 수입 반영 관련 상태
  // =========================================================

  bool isApplyingLimit = false;
  String? applyLimitError;
  String? oldDailyLimitText;
  String? newDailyLimitText;

  bool isApplyingPeriod = false;
  String? applyPeriodError;
  int? _daysReduced;

  int get daysReduced => _daysReduced ?? 0;
  String get daysReducedText => '${_daysReduced ?? 0}일';

  String get appliedAmountText => totalFormattedWithWon;

  String get periodPreviewText {
    if (totalIncome == 0) return '';
    const reducedDays = 30; // TODO: 실제 계산 결과 연결
    return '$appliedAmountText을 기간에 반영하면 ${reducedDays}일이 줄어들어요!';
  }

  String get limitPreviewText {
    if (totalIncome == 0) return '';
    const oldLimit = '10,000원'; // TODO: 실제 기존 한도 연결
    const newLimit = '20,000원'; // TODO: 실제 반영 한도 연결
    return '$appliedAmountText을 소비한도 금액에 반영하면\n'
        '하루에 $oldLimit에서 $newLimit으로 늘어나요!';
  }

  Future<void> applyIncomeToLimit() async {
    if (totalIncome == 0) {
      applyLimitError = '최소 하나의 입금 내역을 입력해주세요.';
      notifyListeners();
      return;
    }

    isApplyingLimit = true;
    applyLimitError = null;
    notifyListeners();

    try {
      // TODO: 실제 플랜/한도 반영 로직 연결
      await Future.delayed(const Duration(milliseconds: 700));

      oldDailyLimitText = '10,000원';
      newDailyLimitText = '20,000원';
    } catch (e) {
      applyLimitError = '소비 한도 반영 중 오류가 발생했습니다.';
    } finally {
      isApplyingLimit = false;
      notifyListeners();
    }
  }

  Future<void> applyIncomeToPeriod() async {
    if (totalIncome == 0) {
      applyPeriodError = '최소 하나의 입금 내역을 입력해주세요.';
      notifyListeners();
      return;
    }

    isApplyingPeriod = true;
    applyPeriodError = null;
    notifyListeners();

    try {
      // TODO: 실제 플랜/기간 반영 로직 연결
      await Future.delayed(const Duration(milliseconds: 700));

      _daysReduced = 30;
    } catch (e) {
      applyPeriodError = '기간 반영 중 오류가 발생했습니다.';
    } finally {
      isApplyingPeriod = false;
      notifyListeners();
    }
  }

  void resetApplyStates({bool notify = true}) {
    isApplyingLimit = false;
    applyLimitError = null;
    oldDailyLimitText = null;
    newDailyLimitText = null;

    isApplyingPeriod = false;
    applyPeriodError = null;
    _daysReduced = null;

    if (notify) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    for (final entry in incomeEntries) {
      (entry['amountController'] as TextEditingController?)?.dispose();
      (entry['noteController'] as TextEditingController?)?.dispose();
    }
    super.dispose();
  }
}