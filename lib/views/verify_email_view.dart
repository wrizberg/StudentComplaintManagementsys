import 'package:flutter/material.dart';
import 'package:studentcomplainmanagementsys/constants/routes.dart';
import 'package:studentcomplainmanagementsys/services/auth/auth_service.dart';

class VerifyEmailView extends StatefulWidget {
  const VerifyEmailView({super.key});

  @override
  State<VerifyEmailView> createState() => _VerifyEmailViewState();
}

class _VerifyEmailViewState extends State<VerifyEmailView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Email'),
      ),
      body: Column(
        children: [
          const Text(
              "we've sent an email verification. Please open it to verify your account."),
          const Text(
              "If you haven't received a verification email yet, press the  button below."),
          TextButton(
            onPressed: () async {
              await AuthService.firebase().sendEmailVerification();
            },
            child: const Text(
              'Send Email Verification',
            ),
          ),
          TextButton(
            onPressed: () async {
              await AuthService.firebase().logOut();

              Navigator.of(context).pushNamedAndRemoveUntil(
                registerRoute,
                (route) => false,
              );
            },
            child: const Text('Cancel'),
          )
        ],
      ),
    );
  }
}
