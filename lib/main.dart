import 'package:flutter/material.dart';
import 'package:studentcomplainmanagementsys/constants/routes.dart';
import 'package:studentcomplainmanagementsys/services/auth/auth_service.dart';
import 'package:studentcomplainmanagementsys/views/complaints/new_complaints_view.dart';
import 'package:studentcomplainmanagementsys/views/login_view.dart';
import 'package:studentcomplainmanagementsys/views/verify_email_view.dart';
import 'views/complaints/complaints_view.dart';
import 'views/registerview.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.greenAccent),
      ),
      home: const HomePage(),
      routes: {
        loginRoute: (context) => const LoginView(),
        registerRoute: (context) => const RegisterView(),
        complaintsRoute: (context) => const ComplaintView(),
        verifyEmailRoute: (context) => const VerifyEmailView(),
        newComplaintRoute: (context) => const NewComplaintView(),
      },
    ),
  );
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: AuthService.firebase().initialize(),
      builder: (context, snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.done:
            final user = AuthService.firebase().currentUser;
            if (user != null) {
              if (user.isEmailVerified) {
                return const ComplaintView();
              } else {
                return const VerifyEmailView();
              }
            } else {
              return const LoginView();
            }

          default:
            return const Text('Loading...');
        }
      },
    );
  }
}
