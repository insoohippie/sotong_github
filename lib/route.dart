import 'package:flutter/material.dart';
import 'package:sotong_local/view/pages/auth/signup_page.dart';
import 'package:sotong_local/view/pages/auth/signup_success_page.dart';
import 'package:sotong_local/view/pages/communication/communication_logs_page.dart';
import 'package:sotong_local/view/pages/communication/communication_page.dart';
import 'package:sotong_local/view/pages/home/home_page.dart';
import 'package:sotong_local/view/pages/home/home_tab_navigator.dart';
import 'package:sotong_local/view/pages/logo_splash_page.dart';
import 'package:sotong_local/view/pages/notification/notification_page.dart';
import 'package:sotong_local/view/pages/plan/chat_plan_page.dart';
import 'package:sotong_local/view/pages/plan/plan_success_page.dart';
import 'package:sotong_local/view/pages/record/record_diary_page.dart';
import 'package:sotong_local/view/pages/record/record_spending_page.dart';
import 'package:sotong_local/view/pages/record/today_spending_page.dart';
import 'package:sotong_local/view/pages/report/report_page.dart';
import 'package:sotong_local/view/pages/setting/FAQ.dart';
import 'package:sotong_local/view/pages/setting/edit_plan/edit_daily_limit_page.dart';
import 'package:sotong_local/view/pages/setting/edit_plan/edit_fixed_cost_page.dart';
import 'package:sotong_local/view/pages/setting/edit_plan/edit_income_page.dart';
import 'package:sotong_local/view/pages/setting/edit_plan/edit_saving_target_page.dart';
import 'package:sotong_local/view/pages/setting/settings_page.dart';
import 'package:sotong_local/view/pages/home/home_add_income.dart';
import 'package:sotong_local/view/pages/home/amount_change_choice_page.dart';
import 'package:sotong_local/view/pages/home/period_loading_page.dart';
import 'package:sotong_local/view/pages/home/limit_loading_page.dart';
import 'package:sotong_local/view/pages/home/period_complete_page.dart';
import 'package:sotong_local/view/pages/home/limit_complete_page.dart';
import 'package:sotong_local/view/pages/variable_expense_popup.dart';
import 'package:sotong_local/view/pages/plan/chat_widgets/input_modal/category_utils.dart';
import 'package:sotong_local/view/pages/daily_expense/daily_expense_input_page.dart';
import 'package:sotong_local/view/pages/daily_expense/daily_expense_modal_page.dart';
import 'package:sotong_local/view/pages/category_test.dart';
import 'package:sotong_local/view/pages/record/record_widgets/daily_category_manage_file.dart';
import 'package:sotong_local/view/pages/category/income_category_page.dart';
import 'package:sotong_local/view/pages/category/fixed_expense_category_page.dart';
import 'package:sotong_local/view/pages/category/daily_expense_category_page.dart';
import 'package:sotong_local/view/pages/category/category_home.dart';
import 'package:sotong_local/model/entry.dart';

import 'view/pages/auth/login_page.dart';

final Map<String, WidgetBuilder> appRoutes = {
  '/logo_splash': (_) => const LogoSplashPage(),

  '/login': (_) => const EmailLoginPage(),

  '/signup': (_) => const SignUpPage(),
  '/signup_success': (_) => const SignupSuccessPage(),

  '/plan_chat': (_) => const ChatPlanPage(),
  '/plan_success': (_) => const PlanSuccessPage(),

  '/home_tab_navigator': (_) => const HomeTabNavigator(),
  '/home': (_) => const HomePage(),

  '/add_income': (_) => const HomeAddIncomePage(),
  '/amount_change_choice': (context) => AmountChangeChoicePage(
    amount:
        ModalRoute.of(context)?.settings.arguments as String? ?? '1,500,000원',
  ),
  '/period_loading': (_) => const PeriodLoadingPage(),
  '/limit_loading': (_) => const LimitLoadingPage(),
  '/period_complete': (context) => PeriodCompletePage(
    amount:
        ModalRoute.of(context)?.settings.arguments as String? ?? '1,500,000원',
    daysReduced: 27,
  ),
  '/limit_complete': (context) => LimitCompletePage(
    amount:
        ModalRoute.of(context)?.settings.arguments as String? ?? '1,500,000원',
    oldLimit: '7,000원',
    newLimit: '8,500원',
  ),

  '/popup': (_) => const VariableExpensePopup(),

  '/record_spending': (_) => const RecordSpendingPage(),
  '/record_diary': (_) => const RecordDiaryPage(),
  '/today_spending': (_) => const TodaySpendingPage(),

  '/setting': (_) => const SettingsPage(),
  '/edit_income': (_) => const EditIncomePage(),
  '/edit_fixed_cost': (_) => const EditFixedCostPage(),
  '/edit_saving_target': (_) => const EditSavingTargetPage(),
  '/edit_daily_limit': (_) => const EditDailyLimitPage(),
  '/faq': (_) => const FAQPage(),

  '/notification': (_) => const NotificationPage(),

  '/report': (_) => const ReportPage(),

  '/communication': (_) => const CommunicationPage(),
  '/communication_logs': (_) => const CommunicationLogsPage(),

  '/daily_expense_input': (context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    return DailyExpenseInputPage(
      initialEntries: args?['initialEntries'] as List<Entry>?,
      monthlyIncome: args?['monthlyIncome'] as double?,
      onCategorySettingsTap: args?['onCategorySettingsTap'] as VoidCallback?,
    );
  },

  '/daily_expense_modal': (context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    return DailyExpenseModalPage(
      title: args?['title'] as String? ?? '일 변동소비 예산을 입력해주세요',
      initialEntries: args?['initialEntries'] as List<Entry>?,
      monthlyIncome: args?['monthlyIncome'] as double?,
      onCategorySettingsTap: args?['onCategorySettingsTap'] as VoidCallback?,
      type: args?['type'] as EntryType? ?? EntryType.daily,
    );
  },

  '/category_test': (_) => const CategoryTestPage(),
  '/daily_category_manage': (_) => const DailyCategoryManagePage(),
  '/category_home': (_) => const CategoryHomePage(),
  '/income_category': (_) => const IncomeCategoryPage(),
  '/fixed_expense_category': (_) => const FixedExpenseCategoryPage(),
  '/daily_expense_category': (_) => const DailyExpenseCategoryPage(),
};
