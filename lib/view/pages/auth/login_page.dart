import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../component/texts/header_text.dart';
import '../../../component/texts/multi_color_text.dart';
import '../../../theme/app_text_styles.dart';
import '../../../view_model/auth/login_view_model.dart';

class EmailLoginPage extends StatelessWidget {
  const EmailLoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LoginViewModel>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          if (vm.isLoading)
            const Center(child: CircularProgressIndicator()),

          SafeArea(
            child: SingleChildScrollView(
              reverse: true,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(46, 48, 46, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    MultiColorText(
                      baseStyle: AppTextStyles.header,
                      parts: const [
                        TextPart('재미있게 ', Color(0xFF231F1F), bold: true),
                        TextPart('소통', Color(0xFF0062FF), bold: true),
                        TextPart('하며\n', Color(0xFF231F1F), bold: true),
                        TextPart('소비 통제', Color(0xFF0062FF), bold: true),
                        TextPart(' 하자!', Color(0xFF231F1F), bold: true),
                      ],
                    ),
                    const SizedBox(height: 40),
                    HeaderText(text: 'Sign in'),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: vm.emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: vm.passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 30),
                    if (vm.errorMessage != null)
                      Text(
                        vm.errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FloatingActionButton(
                        onPressed: vm.isLoading
                            ? null
                            : () async {
                          final user = await vm.login();
                          //print(vm.errorMessage);
                          if (user != null) {
                            Navigator.of(context).pushReplacementNamed('/home');
                          }
                        },
                        backgroundColor: Colors.white,
                        elevation: 2,
                        child: const Icon(Icons.arrow_forward, color: Colors.black),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
