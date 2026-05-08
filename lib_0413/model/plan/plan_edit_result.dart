import '../commands/update_daily_command.dart';
import '../commands/update_monthly_command.dart';
import '../refData/ref_data.dart';
import 'total_plan.dart';

/// Result returned from PlanEditPage capturing updated plan and pending commands.
class PlanEditResult {
  PlanEditResult({
    required this.updatedPlan,
    required this.updatedRefData,
    required this.applyDate,
    required this.projectedGoalDate,
    required this.monthlyCommands,
    required this.dailyCommands,
  });

  final TotalPlan updatedPlan;
  final RefData updatedRefData;
  final DateTime applyDate;
  final DateTime projectedGoalDate;
  final List<UpdateMonthlyCommand> monthlyCommands;
  final List<UpdateDailyCommand> dailyCommands;
}
