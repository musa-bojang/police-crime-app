import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';

void main() {
  runApp(
    // ChangeNotifierProvider makes a single AuthService available to the whole
    // widget tree. `..tryAutoLogin()` kicks off restoring any saved session.
    ChangeNotifierProvider(
      create: (_) => AuthService()..tryAutoLogin(),
      child: const PoliceApp(),
    ),
  );
}

class PoliceApp extends StatelessWidget {
  const PoliceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Police Crime System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      // The "auth gate": show Home if logged in, otherwise Login. Because it's a
      // Consumer, it automatically switches the moment login/logout happens.
      home: Consumer<AuthService>(
        builder: (context, auth, _) {
          return auth.isLoggedIn ? const HomeScreen() : const LoginScreen();
        },
      ),
    );
  }
}
