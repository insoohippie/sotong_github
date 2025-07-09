import 'package:flutter/material.dart';
import 'package:sotong_local/view/pages/auth/signup_page.dart';
import 'package:sotong_local/view/pages/home/home_page.dart';
import 'package:sotong_local/view/pages/plan/plan_chat_page.dart';
import 'view/pages/auth/login_page.dart';

final Map<String, WidgetBuilder> appRoutes = {
  '/login': (_) => EmailLoginPage(),
  '/home': (_) => HomePage(), // 이후 실제 HomePage로 교체
  '/signup': (_) => const SignUpPage(),
};
