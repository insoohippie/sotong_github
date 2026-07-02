import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:provider/provider.dart';
import 'package:sotong_local/repository/notification_repository.dart';
import 'package:sotong_local/repository/plan_mutation_repository.dart';
import 'package:sotong_local/services/notification_generate_service.dart';
import 'package:sotong_local/view_model/record/today_income_view_model.dart';
import 'package:sotong_local/view_model/services/category_bootstrap_service.dart';

import 'data_source/auth_cache_data_source.dart';
import 'firebase_options.dart';
import 'route.dart';
import 'component/theme/app_theme.dart';

// DataSources
import 'data_source/auth_data_source.dart';
import 'data_source/plan_data_source.dart';
import 'data_source/record_data_source.dart';
import 'data_source/ref_data_data_source.dart';
import 'data_source/ref_category_data_source.dart';

// Repositories
import 'repository/auth_repository.dart';
import 'repository/plan_repository.dart';
import 'repository/record_repository.dart';
import 'repository/ref_data_repository.dart';
import 'repository/ref_category_repository.dart';
import 'repository/plan_cache_repository.dart';
import 'repository/account_delete_repository.dart';

// EventBus
import 'services/plan_saved_event_bus.dart';
import 'services/record_event_bus.dart';
import 'services/app_session_reset_service.dart';

// ViewModels
import 'view_model/auth/login_view_model.dart';
import 'view_model/auth/signup_view_model.dart';
import 'view_model/plan/chat_plan_viewmodel.dart';
import 'view_model/home/home_view_model.dart';

import 'view_model/category/plan_category_view_model.dart';
import 'view_model/category/category_edit_view_model.dart';
import 'view_model/category/spending_category_view_model.dart';
import 'view_model/category/add_income_category_view_model.dart';
import 'package:sotong_local/view_model/record/today_spending_view_model.dart';
import 'package:sotong_local/view_model/record/record_add_income_view_model.dart';

import 'view_model/record/record_spending_view_model.dart';
import 'view_model/report/report_view_model.dart';
import 'view_model/communication/communication_view_model.dart';
import 'view_model/setting/setting_view_model.dart';
import 'view_model/setting/alarm_view_model.dart';
import 'view_model/notification/notification_view_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1) Hive 초기화
  await Hive.initFlutter();
  await Hive.openBox('auth_cache');
  await Hive.openBox('refData');
  await Hive.openBox('ref_categories');
  await Hive.openBox('monthly_spending');
  await Hive.openBox('past_plans');
  await Hive.openBox('settings');
  await Hive.openBox('plan_cache');
  await Hive.openBox('notification_read');
  await Hive.openBox('notification_cache');

  // 2) Firebase 초기화
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') rethrow;
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 1) EventBus
        Provider<PlanSavedEventBus>(
          create: (_) => PlanSavedEventBus(),
          dispose: (_, bus) => bus.dispose(),
        ),
        Provider<RecordEventBus>(
          create: (_) => RecordEventBus(),
          dispose: (_, bus) => bus.dispose(),
        ),


        // 2) DataSources
        Provider<AuthDataSource>(create: (_) => AuthDataSource()),
        Provider<AuthCacheDataSource>(create: (_) => AuthCacheDataSource()),
        Provider<PlanDataSource>(create: (_) => PlanDataSource()),
        Provider<RecordDataSource>(create: (_) => RecordDataSource()),
        Provider<RefDataDataSource>(create: (_) => RefDataDataSource()),
        Provider<RefCategoryDataSource>(
          create: (_) => RefCategoryDataSource(),
        ),

        // 3) Repositories
        Provider<AuthRepository>(
          create: (ctx) => AuthRepository(
            ctx.read<AuthDataSource>(),
            ctx.read<AuthCacheDataSource>(),
          ),
        ),
        Provider<PlanRepository>(
          create: (ctx) => PlanRepository(
            ctx.read<PlanDataSource>(),
            ctx.read<AuthDataSource>(),
          ),
        ),
        Provider<PlanMutationRepository>(
          create: (_) => PlanMutationRepository(),
        ),
        Provider<RecordRepository>(
          create: (ctx) => RecordRepository(
            ctx.read<RecordDataSource>(),
            ctx.read<AuthDataSource>(),
          ),
        ),
        Provider<RefDataRepository>(
          create: (ctx) => RefDataRepository(
            ctx.read<RefDataDataSource>(),
            ctx.read<AuthDataSource>(),
          ),
        ),
        Provider<RefCategoryRepository>(
          create: (ctx) => RefCategoryRepository(
            ctx.read<RefCategoryDataSource>(),
            ctx.read<AuthDataSource>(),
          ),
        ),
        Provider<PlanCacheRepository>(
          create: (_) => PlanCacheRepository(),
        ),
        Provider<AccountDeleteRepository>(
          create: (ctx) => AccountDeleteRepository(
            ctx.read<AuthRepository>(),
          ),
        ),
        Provider<NotificationRepository>(
          create: (ctx) => NotificationRepository(
            ctx.read<AuthRepository>(),
          ),
        ),
        Provider<NotificationGenerateService>(
          create: (ctx) => NotificationGenerateService(
            ctx.read<NotificationRepository>(),
            ctx.read<RecordRepository>(),
            ctx.read<RefDataRepository>(),
            ctx.read<PlanRepository>(),
          ),
        ),
        Provider<CategoryBootstrapService>(
          create: (ctx) => CategoryBootstrapService(
            ctx.read<RefCategoryRepository>(),
          ),
        ),

        // 4) ViewModels
        ChangeNotifierProvider<LoginViewModel>(
          create: (ctx) => LoginViewModel(ctx.read<AuthRepository>()),
        ),
        ChangeNotifierProvider<SignupViewModel>(
          create: (ctx) => SignupViewModel(ctx.read<AuthRepository>()),
        ),
        ChangeNotifierProvider<ChatPlanViewModel>(
          create: (ctx) => ChatPlanViewModel(
            ctx.read<AuthRepository>(),
            ctx.read<PlanRepository>(),
            ctx.read<RefDataRepository>(),
            ctx.read<PlanCacheRepository>(),
            ctx.read<CategoryBootstrapService>(),
            planSavedBus: ctx.read<PlanSavedEventBus>(),
          ),
        ),
        ChangeNotifierProvider<HomeViewModel>(
          create: (ctx) => HomeViewModel(
            ctx.read<AuthRepository>(),
            ctx.read<PlanRepository>(),
            ctx.read<PlanSavedEventBus>(),
            ctx.read<RecordRepository>(),
              ctx.read<RecordEventBus>(),
            ctx.read<RefDataRepository>()  // 세은님 추가 부분
          ),
        ),
        ChangeNotifierProvider<TodaySpendingViewModel>(
          create: (ctx) => TodaySpendingViewModel(
            ctx.read<RecordRepository>(),
            ctx.read<PlanRepository>(),
              ctx.read<RecordEventBus>()
          ),
        ),
        ChangeNotifierProvider<TodayIncomeViewModel>(
          create: (ctx) => TodayIncomeViewModel(
            ctx.read<RecordRepository>(),
              ctx.read<RecordEventBus>()
          ),
        ),
        ChangeNotifierProvider<RecordSpendingViewModel>(
          create: (ctx) => RecordSpendingViewModel(
            ctx.read<RecordRepository>(),
              ctx.read<RecordEventBus>()
          ),
        ),
        ChangeNotifierProvider<RecordAddIncomeViewModel>(
          create: (ctx) => RecordAddIncomeViewModel(
            ctx.read<RecordRepository>(),
          ),
        ),
        ChangeNotifierProvider<ReportViewModel>(
          create: (context) => ReportViewModel(
            context.read<RecordRepository>(),
            context.read<RefDataRepository>(),
            context.read<PlanRepository>(),
            context.read<AuthRepository>(),
            eventBus: context.read<RecordEventBus>(),
            planSavedBus: context.read<PlanSavedEventBus>(),
          ),
        ),
        ChangeNotifierProvider<CommunicationViewModel>(
          create: (ctx) => CommunicationViewModel(
            ctx.read<RecordRepository>(),
            ctx.read<PlanRepository>(),
              ctx.read<RecordEventBus>()
          ),
        ),
        ChangeNotifierProvider<PlanCategoryViewModel>(
          create: (_) => PlanCategoryViewModel(),
        ),
        ChangeNotifierProvider<SpendingCategoryViewModel>(
          create: (ctx) => SpendingCategoryViewModel(
            ctx.read<AuthRepository>(),
            ctx.read<PlanCacheRepository>(),
            ctx.read<RefDataRepository>(),
            ctx.read<RefCategoryRepository>(),
          ),
        ),
        ChangeNotifierProvider<AddIncomeCategoryViewModel>(
          create: (ctx) => AddIncomeCategoryViewModel(
            ctx.read<RefCategoryRepository>(),
          ),
        ),
        ChangeNotifierProvider<CategoryEditViewModel>(
          create: (context) => CategoryEditViewModel(
            context.read<AuthRepository>(),
            context.read<PlanRepository>(),
            context.read<RefDataRepository>(),
            context.read<RefCategoryRepository>(),
            context.read<PlanMutationRepository>(),
            context.read<PlanCacheRepository>(),
            context.read<PlanSavedEventBus>(),
          ),
        ),
        ChangeNotifierProvider<AlarmViewModel>(
          create: (_) => AlarmViewModel(),
        ),
        ChangeNotifierProvider<NotificationViewModel>(
          create: (ctx) => NotificationViewModel(
            ctx.read<NotificationRepository>(),
            ctx.read<NotificationGenerateService>(),
            ctx.read<RecordEventBus>(),
          ),
        ),

        Provider<AppSessionResetService>(
          create: (ctx) => AppSessionResetService(
            targets: [
              ctx.read<ChatPlanViewModel>(),
              ctx.read<ReportViewModel>(),
              ctx.read<NotificationViewModel>(),
            ],
          ),
        ),
        ChangeNotifierProvider<SettingViewModel>(
          create: (ctx) => SettingViewModel(
            ctx.read<AuthRepository>(),
            ctx.read<RecordRepository>(),
            ctx.read<PlanRepository>(),
            ctx.read<RefDataRepository>(),
            ctx.read<PlanCacheRepository>(),
            ctx.read<RefCategoryRepository>(),
            ctx.read<AccountDeleteRepository>(),
            ctx.read<AppSessionResetService>(),
          ),
        ),

      ],
      child: Consumer<SettingViewModel>(
        builder: (context, settingVM, _) {
          return MaterialApp(
            title: 'Sotong App',
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: settingVM.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            initialRoute: '/logo_splash',
            routes: appRoutes,
          );
        },
      ),
    );
  }
}
