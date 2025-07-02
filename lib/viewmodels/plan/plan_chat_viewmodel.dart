import 'package:flutter/material.dart';
import '../../models/plan_info.dart';

class PlanChatVM with ChangeNotifier {
  String _planName = '';
  String _planPurpose = '';
  int _goalAmount = 0;

  String get planName => _planName;
  String get planPurpose => _planPurpose;
  int get goalAmount => _goalAmount;

  void setPlanName(String name) {
    _planName = name;
    notifyListeners();
  }

  void setPlanPurpose(String purpose) {
    _planPurpose = purpose;
    notifyListeners();
  }

  void setGoalAmount(String amountStr) {
    _goalAmount = int.tryParse(amountStr) ?? 0;
    notifyListeners();
  }

  PlanInfo createPlan() {
    return PlanInfo(
      planName: _planName,
      planPurpose: _planPurpose,
      goalAmount: _goalAmount,
    );
  }

  void clear() {
    _planName = '';
    _planPurpose = '';
    _goalAmount = 0;
    notifyListeners();
  }

  bool get isComplete =>
      _planName.isNotEmpty && _planPurpose.isNotEmpty && _goalAmount > 0;
}
