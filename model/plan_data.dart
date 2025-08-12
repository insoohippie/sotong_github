class PlanData {
  String planName;
  String purpose;
  double targetAmount;
  double currentAsset;
  double monthlyIncome;
  double monthlyFixedCost;
  double dailySpendingLimit;
  DateTime planStartDate;

  PlanData({
    this.planName = '',
    this.purpose = '',
    this.targetAmount = 0,
    this.currentAsset = 0,
    this.monthlyIncome = 0,
    this.monthlyFixedCost = 0,
    this.dailySpendingLimit = 0,
    DateTime? planStartDate,
  }) : planStartDate = planStartDate ?? DateTime.now();
}

class IncomeItem {
  final String id;
  String category;
  double amount;

  IncomeItem({required this.id, this.category = '', this.amount = 0});
}

class ExpenseItem {
  final String id;
  String category;
  double amount;

  ExpenseItem({required this.id, this.category = '', this.amount = 0});
}
