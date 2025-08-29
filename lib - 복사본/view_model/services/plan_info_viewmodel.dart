


import '../../model/plan_info.dart';

class PlanInfoViewModel {
  final PlanInfo planInfo;

  PlanInfoViewModel(this.planInfo);

  // Optionally, a method to update multiple fields at once
  void updatePlanInfo({
    String? planName,
    String? purpose,
    double? targetAmount,
    double? currentAmount,
    double? currentAsset,
    bool? autoService,
    DateTime? startDate,
  }) {
    if (planName != null) this.planInfo.planName = planName;
    if (purpose != null) this.planInfo.purpose = purpose;
    if (targetAmount != null) this.planInfo.targetAmount = targetAmount;
    if (currentAmount != null) this.planInfo.currentAmount = currentAmount;
    if (currentAsset != null) this.planInfo.currentAsset = currentAsset;
    if (autoService != null) this.planInfo.autoService = autoService;
    if (startDate != null) this.planInfo.startDate = startDate;
  }

  // Update methods for each PlanInfo variable
  void updatePlanName(String name) {
    planInfo.planName = name;
  }

  void updatePurpose(String purpose) {
    planInfo.purpose = purpose;
  }

  void updateTargetAmount(double amount) {
    planInfo.targetAmount = amount;
  }

  void updateCurrentAmount(double amount) {
    planInfo.currentAmount = amount;
  }

  void updateCurrentAsset(double asset) {
    planInfo.currentAsset = asset;
  }

  void updateStartDate(DateTime date) {
    planInfo.startDate = date;
  }
} 