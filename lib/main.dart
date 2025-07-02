import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sotong_local/viewmodels/plan/plan_chat_viewmodel.dart';
import 'route.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PlanChatVM()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Sotong Budget App',
        theme: ThemeData(primarySwatch: Colors.blue),
        initialRoute: '/',
        routes: appRoutes,
      ),
    );
  }
}
