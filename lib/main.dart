import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:sotong_local/theme/app_colors.dart';
import 'package:sotong_local/view_model/auth/signup_view_model.dart';
import 'package:sotong_local/view_model/communication/communication_view_model.dart';
import 'package:sotong_local/view_model/notification/notification_view_model.dart';
import 'package:sotong_local/view_model/plan/chat_plan_viewmodel.dart';
import 'package:sotong_local/view_model/record/record_view_model.dart';
import 'package:sotong_local/view_model/setting/alarm_view_model.dart';
import 'package:sotong_local/view_model/setting/setting_view_model.dart';
import 'view_model/auth/login_view_model.dart';
import 'repository/auth_repository.dart';
import 'data_source/auth_data_source.dart';
import 'route.dart';
import 'firebase_options.dart';

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
        ChangeNotifierProvider(
          create: (_) => LoginViewModel(AuthRepository(AuthDataSource())),
        ),
        ChangeNotifierProvider(
          create: (_) => SignupViewModel(AuthRepository(AuthDataSource())),
        ),
        ChangeNotifierProvider(create: (_) => ChatPlanViewModel()),
        ChangeNotifierProvider(create: (_) => RecordViewModel()),
        ChangeNotifierProvider(create: (_) => SettingViewModel()),
        ChangeNotifierProvider(create: (_) => AlarmViewModel()),
        ChangeNotifierProvider(create: (_) => NotificationViewModel()),
        ChangeNotifierProvider(create: (_) => CommunicationViewModel()),
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
