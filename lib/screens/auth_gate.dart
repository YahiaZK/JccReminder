import 'package:flutter/material.dart';
import 'package:jcc_reminder/screens/dashboard_screen.dart';
import 'package:jcc_reminder/screens/login_screen.dart';
import 'package:jcc_reminder/services/auth_service.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          AuthService().subscribeToNotifications();
          return const DashboardScreen();
        }

        return const LoginScreen();
      },
    );
  }
}
