class IncomeEntry {
  String category;
  String? content;
  String? amount;

  IncomeEntry({required this.category, this.content, this.amount});

  bool get isEmpty => amount == null || amount!.isEmpty;
}