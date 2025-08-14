import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:sotong_local/view_model/home/home_viewmodel.dart';

import 'component/theme/app_colors.dart';
import 'firebase_options.dart';
import 'route.dart';

// DataSources
import 'data_source/auth_data_source.dart';
import 'data_source/plan_data_source.dart';

// Repositories
import 'repository/auth_repository.dart';
import 'repository/plan_repository.dart';

// ViewModels
import 'view_model/auth/login_view_model.dart';
import 'view_model/auth/signup_view_model.dart';
import 'view_model/plan/chat_plan_viewmodel.dart';
import 'view_model/record/record_view_model.dart';
import 'view_model/setting/setting_view_model.dart';
import 'view_model/setting/alarm_view_model.dart';
import 'view_model/notification/notification_view_model.dart';
import 'view_model/communication/communication_view_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 1) DataSources
        Provider<AuthDataSource>(create: (_) => AuthDataSource()),
        Provider<PlanDataSource>(create: (_) => PlanDataSource()),

        // 2) Repositories (위 DataSource를 read 해서 생성)
        Provider<AuthRepository>(
          create: (ctx) => AuthRepository(ctx.read<AuthDataSource>()),
        ),
        Provider<PlanRepository>(
          create: (ctx) => PlanRepository(
            ctx.read<PlanDataSource>(),
            ctx.read<AuthDataSource>(),
          ),
        ),

        // 3) ViewModels
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
          ),
        ),
        ChangeNotifierProvider<HomeViewModel>(
          create: (ctx) => HomeViewModel(
            ctx.read<AuthRepository>(),
            ctx.read<PlanRepository>(),
          ),
        ),
        ChangeNotifierProvider<RecordViewModel>(create: (_) => RecordViewModel()),
        ChangeNotifierProvider<SettingViewModel>(create: (_) => SettingViewModel()),
        ChangeNotifierProvider<AlarmViewModel>(create: (_) => AlarmViewModel()),
        ChangeNotifierProvider<NotificationViewModel>(create: (_) => NotificationViewModel()),
        ChangeNotifierProvider<CommunicationViewModel>(create: (_) => CommunicationViewModel()),
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
        initialRoute: '/signup_success',
        routes: appRoutes,
      ),
    );
  }
}
