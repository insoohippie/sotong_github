import 'package:flutter/material.dart';
import '../../model/addIncome/income_entry.dart';

class AddIncomeViewModel extends ChangeNotifier {
  /// ====== 1) 추가 입금 입력 상태 ======
  final List<IncomeEntry> _entries = [];
  List<IncomeEntry> get entries => List.unmodifiable(_entries);

  /// ✅ 기본 4개 + 커스텀을 한 리스트로 관리 (프리셋 없음)
  final List<String> _categories = ['급여', '사업', '배당', '용돈'];
  List<String> get categories => List.unmodifiable(_categories);

  /// ✅ 카테고리별 이모지 (기본도 포함)
  final Map<String, String> _categoryEmojis = {
    '급여': '💼',
    '사업': '🏢',
    '배당': '📈',
    '용돈': '🎁',
  };
  Map<String, String> get categoryEmojis => Map.unmodifiable(_categoryEmojis);

  AddIncomeViewModel() {
    addEntry(); // 기본 한 줄
  }

  void addEntry() {
    _entries.add(IncomeEntry(category: ''));
    notifyListeners();
  }

  void updateEntry(
      int index, {
        String? category,
        String? content,
        String? amount,
      }) {
    if (index < 0 || index >= _entries.length) return;
    final current = _entries[index];
    _entries[index] = IncomeEntry(
      category: category ?? current.category,
      content: content ?? current.content,
      amount: amount ?? current.amount,
    );
    notifyListeners();
  }

  bool removeEntry(int index) {
    if (_entries.length <= 1) return false;
    if (index < 0 || index >= _entries.length) return false;
    _entries.removeAt(index);
    notifyListeners();
    return true;
  }

  /// ✅ 새 카테고리 추가(이모지 포함)
  void addCategoryWithEmoji(String category, String emoji) {
    final name = category.trim();
    if (name.isEmpty) return;

    if (!_categories.contains(name)) {
      _categories.add(name);
    }
    _categoryEmojis[name] = (emoji.trim().isNotEmpty) ? emoji.trim() : '💰';
    notifyListeners();
  }

  void removeCategory(String category) {
    final name = category.trim();
    _categories.remove(name);
    _categoryEmojis.remove(name);
    notifyListeners();
  }

  void setCategoryEmoji(String category, String emoji) {
    final name = category.trim();
    if (name.isEmpty) return;
    _categoryEmojis[name] = (emoji.trim().isNotEmpty) ? emoji.trim() : '💰';
    notifyListeners();
  }

  List<IncomeEntry> get validEntries => _entries.where((e) => !e.isEmpty).toList();

  /// 총 금액(int)
  int get totalAmount {
    int total = 0;
    for (final e in validEntries) {
      if (e.amount == null) continue;
      final clean = e.amount!.replaceAll(',', '');
      total += int.tryParse(clean) ?? 0;
    }
    return total;
  }

  /// "1,234,567원" 형태
  String get totalFormatted {
    if (totalAmount == 0) return '0원';
    return _formatWithComma(totalAmount) + '원';
  }

  String _formatWithComma(int number) {
    final s = number.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) {
        buf.write(',');
      }
      buf.write(s[i]);
    }
    return buf.toString();
  }

  /// ====== 2) 공통 적용 결과 상태 ======
  String? appliedAmountText;

  /// ====== 3) 한도 반영 상태 ======
  bool isApplyingLimit = false;
  String? applyLimitError;
  String? oldDailyLimitText;
  String? newDailyLimitText;

  /// ====== 4) 기간 반영 상태 ======
  bool isApplyingPeriod = false;
  String? applyPeriodError;
  int? _daysReduced;

  int get daysReduced => _daysReduced ?? 0;
  String get daysReducedText => '${_daysReduced ?? 0}일';

  String get periodPreviewText {
    if (totalAmount == 0) return '';
    const reducedDays = 30; // TODO: 실제 계산으로 교체
    return '$totalFormatted을 기간에 반영하면 $reducedDays일이 줄어들어요!';
  }

  String get limitPreviewText {
    if (totalAmount == 0) return '';
    const oldLimit = '10,000원';
    const newLimit = '20,000원';
    return '$totalFormatted을 소비한도 금액에 반영하면\n'
        '하루에 $oldLimit에서 $newLimit으로 늘어나요!';
  }

  Future<void> applyIncomeToLimit() async {
    if (totalAmount == 0) {
      applyLimitError = '최소 하나의 입금 내역을 입력해주세요.';
      notifyListeners();
      return;
    }

    isApplyingLimit = true;
    applyLimitError = null;
    notifyListeners();

    try {
      appliedAmountText = totalFormatted;
      oldDailyLimitText ??= '10,000원';
      newDailyLimitText ??= '20,000원';
    } catch (e) {
      applyLimitError = '소비 한도 반영 중 오류가 발생했습니다.';
    } finally {
      isApplyingLimit = false;
      notifyListeners();
    }
  }

  Future<void> applyIncomeToPeriod() async {
    if (totalAmount == 0) {
      applyPeriodError = '최소 하나의 입금 내역을 입력해주세요.';
      notifyListeners();
      return;
    }

    isApplyingPeriod = true;
    applyPeriodError = null;
    notifyListeners();

    try {
      appliedAmountText = totalFormatted;
      _daysReduced ??= 30;
    } catch (e) {
      applyPeriodError = '기간 반영 중 오류가 발생했습니다.';
    } finally {
      isApplyingPeriod = false;
      notifyListeners();
    }
  }

  void resetApplyStates() {
    isApplyingLimit = false;
    isApplyingPeriod = false;
    applyLimitError = null;
    applyPeriodError = null;
  }
}
