import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'route.dart';
import 'component/theme/app_colors.dart';

// DataSources
import 'data_source/auth_data_source.dart';
import 'data_source/plan_data_source.dart';
import 'data_source/category_data_source.dart';
import 'data_source/record_data_source.dart';

// Repositories
import 'repository/auth_repository.dart';
import 'repository/plan_repository.dart';
import 'repository/category_repository.dart';
import 'repository/record_repository.dart';

// EventBus
import 'services/plan_saved_event_bus.dart';
import 'services/spending_event_bus.dart';

// ViewModels
import 'view_model/auth/login_view_model.dart';
import 'view_model/auth/signup_view_model.dart';
import 'view_model/plan/chat_plan_viewmodel.dart';
import 'view_model/home/home_view_model.dart';
import 'view_model/home/today_spending_view_model.dart';
import 'view_model/record/record_view_model.dart';
import 'view_model/report/report_view_model.dart';
import 'view_model/category/category_view_model.dart';
import 'view_model/communication/communication_view_model.dart';
import 'view_model/setting/setting_view_model.dart';
import 'view_model/addIncome/add_income_view_model.dart';
import 'view_model/setting/alarm_view_model.dart';
import 'view_model/notification/notification_view_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1) Hive 초기화
  await Hive.initFlutter();
  await Hive.openBox('monthly_spending');
  await Hive.openBox('categories');

  // 2) Firebase 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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
        Provider<SpendingEventBus>(
          create: (_) => SpendingEventBus(),
          dispose: (_, bus) => bus.dispose(),
        ),

        // 2) DataSources
        Provider<AuthDataSource>(create: (_) => AuthDataSource()),
        Provider<PlanDataSource>(create: (_) => PlanDataSource()),
        Provider<CategoryDataSource>(create: (_) => CategoryDataSource()),
        Provider<RecordDataSource>(create: (_) => RecordDataSource()),

        // 3) Repositories
        Provider<AuthRepository>(
          create: (ctx) => AuthRepository(ctx.read<AuthDataSource>()),
        ),
        Provider<PlanRepository>(
          create: (ctx) => PlanRepository(
            ctx.read<PlanDataSource>(),
            ctx.read<AuthDataSource>(),
          ),
        ),
        Provider<CategoryRepository>(
          create: (ctx) => CategoryRepository(
            ctx.read<CategoryDataSource>(),
            ctx.read<AuthDataSource>(),
          ),
        ),
        Provider<RecordRepository>(
          create: (ctx) => RecordRepository(
            ctx.read<RecordDataSource>(),
            ctx.read<AuthDataSource>(),
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
            planSavedBus: ctx.read<PlanSavedEventBus>(),
          ),
        ),
        ChangeNotifierProvider<HomeViewModel>(
          create: (ctx) => HomeViewModel(
            ctx.read<AuthRepository>(),
            ctx.read<PlanRepository>(),
            ctx.read<PlanSavedEventBus>(),
            ctx.read<RecordRepository>(),
            ctx.read<SpendingEventBus>(),
          ),
        ),
        ChangeNotifierProvider<TodaySpendingViewModel>(
          create: (ctx) => TodaySpendingViewModel(
            ctx.read<RecordRepository>(),
            ctx.read<PlanRepository>(),
          ),
        ),
        ChangeNotifierProvider<RecordViewModel>(
          create: (ctx) => RecordViewModel(
            ctx.read<RecordRepository>(),
            ctx.read<SpendingEventBus>(),
          ),
        ),

        ChangeNotifierProvider<ReportViewModel>(
          create: (ctx) => ReportViewModel(
            ctx.read<RecordRepository>(),
            ctx.read<SpendingEventBus>(),
          ),
        ),

        ChangeNotifierProvider<CommunicationViewModel>(
          create: (ctx) => CommunicationViewModel(
            ctx.read<RecordRepository>(),
            ctx.read<PlanRepository>(),
            ctx.read<SpendingEventBus>(),
          ),
        ),
        ChangeNotifierProvider<CategoryViewModel>(
          create: (ctx) => CategoryViewModel(ctx.read<CategoryRepository>()),
        ),
        ChangeNotifierProvider<SettingViewModel>(
          create: (ctx) => SettingViewModel(
            ctx.read<AuthRepository>(),
            ctx.read<CategoryRepository>(),
            ctx.read<RecordRepository>(),
          ),
        ),
        ChangeNotifierProvider<AddIncomeViewModel>(
          create: (_) => AddIncomeViewModel(),
        ),
        ChangeNotifierProvider<AlarmViewModel>(
          create: (_) => AlarmViewModel(),
        ),
        ChangeNotifierProvider<NotificationViewModel>(
          create: (_) => NotificationViewModel(),
        ),
      ],
      child: MaterialApp(
        title: 'Sotong App',
        theme: ThemeData(
          scaffoldBackgroundColor: Colors.white,
          primaryColor: AppColors.primary,
          colorScheme: ColorScheme.fromSwatch().copyWith(
            primary: AppColors.primary,
            secondary: AppColors.primary,
          ),
        ),
        initialRoute: '/logo_splash',
        routes: appRoutes,
      ),
    );
  }
}
