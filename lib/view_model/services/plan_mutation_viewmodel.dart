import 'package:flutter/foundation.dart';

import '../../model/commands/update_daily_command.dart';
import '../../model/commands/update_monthly_command.dart';
import '../../model/plan/plan_mutation_result.dart';
import '../../model/plan/plan_snapshot.dart';
import '../../services/plan_mutation_service.dart';

/// MVVM adapter exposing async mutation operations to the UI layer.

class PlanMutationViewModel extends ChangeNotifier {
  PlanMutationViewModel(this._service);

  final PlanMutationService _service;

  PlanSnapshot? _snapshot;
  PlanSnapshot? get snapshot => _snapshot;

  bool _isBusy = false;
  bool get isBusy => _isBusy;

  void loadSnapshot(PlanSnapshot snapshot) {
    _snapshot = snapshot;
    notifyListeners();
  }

  Future<PlanMutationResult> applyMonthly(UpdateMonthlyCommand command) async {
    _ensureSnapshotLoaded();
    _toggleBusy(true);
    try {
      final result = _service.applyMonthly(
        command: command,
        snapshot: _snapshot!,
      );
      _snapshot = PlanSnapshot(
        totalPlan: result.totalPlan,
        monthlyIncomes: result.monthlyIncomes,
        monthlyConsumes: result.monthlyConsumes,
        dailyConsumes: result.dailyConsumes,
      );
      notifyListeners();
      return result;
    } finally {
      _toggleBusy(false);
    }
  }

  Future<PlanMutationResult> applyDaily(UpdateDailyCommand command) async {
    _ensureSnapshotLoaded();
    _toggleBusy(true);
    try {
      final result = _service.applyDaily(
        command: command,
        snapshot: _snapshot!,
      );
      _snapshot = PlanSnapshot(
        totalPlan: result.totalPlan,
        monthlyIncomes: result.monthlyIncomes,
        monthlyConsumes: result.monthlyConsumes,
        dailyConsumes: result.dailyConsumes,
      );
      notifyListeners();
      return result;
    } finally {
      _toggleBusy(false);
    }
  }

  void _ensureSnapshotLoaded() {
    if (_snapshot == null) {
      throw StateError('PlanSnapshot has not been loaded.');
    }
  }

  void _toggleBusy(bool value) {
    if (_isBusy != value) {
      _isBusy = value;
      notifyListeners();
    }
  }
}
