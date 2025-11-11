import 'package:flutter/material.dart';
import 'package:sotong_local/summary_widget_sandbox.dart';
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

  '/__debug_summary': (_) => BudgetAllWidgetsSandboxPage(),
};
