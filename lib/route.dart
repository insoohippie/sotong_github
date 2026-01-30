import 'package:flutter/material.dart';
import 'package:sotong_local/view/pages/addIncome/add_income_page.dart';
import 'package:sotong_local/view/pages/addIncome/apply_income_option_page.dart';
import 'package:sotong_local/view/pages/addIncome/limit_apply_page.dart';
import 'package:sotong_local/view/pages/addIncome/period_apply_page.dart';
import 'package:sotong_local/view/pages/auth/signup_page.dart';
import 'package:sotong_local/view/pages/auth/signup_success_page.dart';
import 'package:sotong_local/view/pages/category/category_edit.dart';
import 'package:sotong_local/view/pages/communication/communication_page.dart';
import 'package:sotong_local/view/pages/home/home_copy.dart';
import 'package:sotong_local/view/pages/home/home_page.dart';
import 'package:sotong_local/view/pages/home/home_tab_navigator.dart';
import 'package:sotong_local/view/pages/logo_splash_page.dart';
import 'package:sotong_local/view/pages/notification/notification_page.dart';
import 'package:sotong_local/view/pages/plan/chat_plan_page.dart';
import 'package:sotong_local/view/pages/plan/plan_success_page.dart';
import 'package:sotong_local/view/pages/record/record_diary_page.dart';
import 'package:sotong_local/view/pages/record/record_spending_page.dart';
import 'package:sotong_local/view/pages/home/today_spending_page.dart';
import 'package:sotong_local/view/pages/report/report_page.dart';
import 'package:sotong_local/view/pages/setting/FAQ.dart';
import 'package:sotong_local/view/pages/setting/edit_plan/edit_daily_limit_page.dart';
import 'package:sotong_local/view/pages/setting/edit_plan/edit_fixed_cost_page.dart';
import 'package:sotong_local/view/pages/setting/edit_plan/edit_income_page.dart';
import 'package:sotong_local/view/pages/setting/edit_plan/edit_saving_target_page.dart';
import 'package:sotong_local/view/pages/setting/settings_page.dart';
import 'package:sotong_local/view/test_insoo/home/home_test.dart';
import 'package:sotong_local/view/test_insoo/home/home_widget_test_page.dart';
import 'package:sotong_local/view/test_insoo/home/today_spending_test_page.dart';

import 'view/pages/auth/login_page.dart';

final Map<String, WidgetBuilder> appRoutes = {
  // 시작 화면(로고)
  '/logo_splash': (_) => const LogoSplashPage(),

  // 로그인
  '/login': (_) => const EmailLoginPage(),

  // 회원가입
  '/signup': (_) => const SignUpPage(),
  '/signup_success': (_) => const SignupSuccessPage(),

  // 플랜 생성 페이지(채팅 형식)
  '/plan_chat': (_) => const ChatPlanPage(),
  '/plan_success': (_) => const PlanSuccessPage(),

  // 메인 페이지(홈, 소통, 레포트)
  '/home_tab_navigator': (_) => const HomeTabNavigator(),
  '/home': (_) => const HomePage(),
  '/report': (_) => const ReportPage(),
  '/communication': (_) => const CommunicationPage(),

  // 하루 소비 페이지(입력, 불러오기)
  '/record_spending': (_) => const RecordSpendingPage(),
  '/record_diary': (_) => const RecordDiaryPage(),
  '/today_spending': (_) => const TodaySpendingPage(),

  // 추가 소득 페이지(입력, 기간or소비한도 적용)
  '/add_income': (_) => const AddIncomePage(),
  '/apply_income_option': (_) => const ApplyIncomeOptionPage(),
  '/limit_apply': (_) => const LimitApplyPage(),
  '/period_apply': (_) => const PeriodApplyPage(),

  // 설정 페이지
  '/setting': (_) => const SettingsPage(),
  '/faq': (_) => const FAQPage(),

  // 플랜 수정 페이지(월 수입, 월 고정 소비, 목표 금액, 일일 한도)
  '/edit_income': (_) => const EditIncomePage(),
  '/edit_fixed_cost': (_) => const EditFixedCostPage(),
  '/edit_saving_target': (_) => const EditSavingTargetPage(),
  '/edit_daily_limit': (_) => const EditDailyLimitPage(),

  // 알림 페이지
  '/notification': (_) => const NotificationPage(),

  // 테스트용 페이지(인수)
  '/category_edit': (_) => const CategoryEditPage(),
  '/home_widget_test': (_) => const HomeWidgetTestPage(),
  '/home_test': (_) => const HomeTestPage(),
  '/home_copy': (_) => const HomeCopyPage(),
  '/today_spending_test': (_) => const TodaySpendingTestPage(),
};
