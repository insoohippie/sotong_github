import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:sotong_local/view_model/auth/signup_view_model.dart';

import 'view/pages/auth/login_page.dart';
import 'view_model/auth/login_view_model.dart';
import 'repository/auth_repository.dart';
import 'data_source/auth_data_source.dart';
import 'route.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
        ChangeNotifierProvider(
          create: (_) => LoginViewModel(AuthRepository(AuthDataSource())),
        ),
        ChangeNotifierProvider(
          create: (_) => SignupViewModel(AuthRepository(AuthDataSource())),
        ),
      ],
      child: MaterialApp(
        title: 'Sotong App',
        theme: ThemeData(fontFamily: 'Pretendard'),
        initialRoute: '/signup',
        routes: appRoutes,
      ),
    );
  }
}