import 'package:flutter/material.dart';

import 'package:sotong/view/pages/auth/signup_page.dart';
import 'package:sotong/view/pages/auth/signup_success_page.dart';
import 'package:sotong/view/pages/auth/unsuccess_plan_quit.dart';
import 'package:sotong/view/pages/category/category_edit.dart';
import 'package:sotong/view/pages/home/pending_spending_page.dart';

import 'package:sotong/view/pages/logo_splash_page.dart';

import 'package:sotong/view/pages/communication/communication_page.dart';

import 'package:sotong/view/pages/home/home_page.dart';
import 'package:sotong/view/pages/home/home_tab_navigator.dart';
import 'package:sotong/view/pages/record/addIncome/period_apply_page.dart';
import 'package:sotong/view/pages/record/today_record_page.dart';

import 'package:sotong/view/pages/plan/chat_plan_page.dart';
import 'package:sotong/view/pages/plan/plan_edit_page.dart';
import 'package:sotong/view/pages/plan/plan_success_page.dart';
import 'package:sotong/view/pages/plan/totalplan.dart';
import 'package:sotong/view/pages/plan/celebration_plan_success.dart';
import 'package:sotong/model/setting/past_plan_snapshot.dart';

import 'package:sotong/view/pages/record/record_diary_page.dart';
import 'package:sotong/view/pages/record/record_page.dart';
import 'package:sotong/view/pages/report/report_page.dart';

import 'package:sotong/view/pages/notification/notification_page.dart';

import 'package:sotong/view/pages/setting/settings_page.dart';
import 'package:sotong/view/pages/setting/personal_info_page.dart';
import 'package:sotong/view/pages/setting/FAQ.dart';
import 'package:sotong/view/pages/setting/version.dart';

import 'package:sotong/view/pages/setting/edit_plan/edit_daily_limit_page.dart';
import 'package:sotong/view/pages/setting/edit_plan/edit_fixed_cost_page.dart';
import 'package:sotong/view/pages/setting/edit_plan/edit_income_page.dart';
import 'package:sotong/view/pages/setting/edit_plan/edit_saving_target_page.dart';

import 'package:sotong/view/pages/setting/past_plan/past_plans_list_page.dart';

import 'view/pages/auth/login_page.dart';

final Map<String, WidgetBuilder> appRoutes = {
  // 시작 화면(로고)
  '/logo_splash': (_) => const LogoSplashPage(),

  // 로그인
  '/login': (_) => const EmailLoginPage(),

  // 회원가입
  '/signup': (_) => const SignUpPage(),
  '/signup_success': (_) => const SignupSuccessPage(),
  '/unsuccess_plan_quit': (_) => const UnsuccessPlanQuitPage(),

  // 플랜 생성, 수정, 생성 완료 페이지
  '/plan_chat': (_) => const ChatPlanPage(),
  '/plan_edit': (_) => const PlanEditPage(),
  '/plan_success': (_) => const PlanSuccessPage(),
  // 플랜 도달, 분석 페이지
  // arguments: {'planName': String?, 'daysTaken': int?, 'snapshot': PastPlanSnapshot?}
  '/celebration_plan_success': (context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    String? planName;
    int? daysTaken;
    PastPlanSnapshot? snapshot;
    if (args is Map) {
      planName = args['planName'] as String?;
      daysTaken = args['daysTaken'] as int?;
      final rawSnapshot = args['snapshot'];
      if (rawSnapshot is PastPlanSnapshot) {
        snapshot = rawSnapshot;
      }
    }
    return CelebrationPlanSuccessPage(
      planName: planName,
      daysTaken: daysTaken,
      snapshot: snapshot,
    );
  },
  // arguments: PastPlanSnapshot? (넘기면 지난 플랜 열람 모드)
  '/total_plan': (context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    return TotalPlanPage(
      snapshot: args is PastPlanSnapshot ? args : null,
    );
  },

  // 카테고리 편집 페이지
  '/category_edit': (_) => const CategoryEditPage(),

  // 메인 페이지(홈, 소통, 레포트)
  '/home_tab_navigator': (context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    int initialIndex = 1;
    if (args is int) {
      initialIndex = args;
    }
    return HomeTabNavigator(initialIndex: initialIndex);
  },
  '/home': (_) => const HomePage(),
  '/report': (_) => const ReportPage(),
  '/communication': (_) => const CommunicationPage(),

  // 추가수입/소비 페이지(입력, 불러오기)
  '/record': (_) => const RecordPage(),
  '/today_record': (_) => const TodayRecordPage(),

  '/record_diary': (_) => const RecordDiaryPage(),

  '/period_apply': (_) => const PeriodApplyPage(),

  '/pending_spending': (_) => const PendingSpendingPage(),

  // 설정 페이지
  '/setting': (_) => const SettingsPage(),
  '/personal_info': (_) => const PersonalInfoPage(),
  '/faq': (_) => const FAQPage(),
  '/version': (_) => const VersionPage(),
  // 과거 플랜 리스트 페이지
  '/past_plans': (_) => const PastPlansListPage(),

  // 플랜 수정 페이지(월 수입, 월 고정 소비, 목표 금액, 일일 한도)
  '/edit_income': (_) => const EditIncomePage(),
  '/edit_fixed_cost': (_) => const EditFixedCostPage(),
  '/edit_saving_target': (_) => const EditSavingTargetPage(),
  '/edit_daily_limit': (_) => const EditDailyLimitPage(),

  // 알림 페이지
  '/notification': (_) => const NotificationPage(),
};
