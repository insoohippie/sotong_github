import 'package:flutter/material.dart';
import 'package:sotong_local/view/pages/auth/signup_page.dart';
import 'package:sotong_local/view/pages/auth/signup_success_page.dart';
import 'package:sotong_local/view/pages/communication/communication_logs_page.dart';
import 'package:sotong_local/view/pages/communication/communication_page.dart';
import 'package:sotong_local/view/pages/home/home_page.dart';
import 'package:sotong_local/view/pages/home/home_tab_navigator.dart';
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
import 'view/pages/auth/login_page.dart';

final Map<String, WidgetBuilder> appRoutes = {
  '/login': (_) => const EmailLoginPage(),

  '/signup': (_) => const SignUpPage(),
  '/signup_success': (_) => const SignupSuccessPage(),

  '/plan_chat': (_) => const ChatPlanPage(),
  '/plan_success': (_) => const PlanSuccessPage(),

  '/home_tab_navigator': (_) => const HomeTabNavigator(),
  '/home': (_) => const HomePage(),

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
};
