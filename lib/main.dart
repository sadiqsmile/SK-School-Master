import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:school_app/features/auth/screens/login_screen.dart';
import 'package:school_app/features/super_admin/screens/super_admin_dashboard.dart';
import 'firebase_options.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {

        // 🔥 WAIT UNTIL AUTH READY
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;

        // 🔥 NOT LOGGED IN
        if (user == null) {
          return const LoginScreen();
        }

        // 🔥 ADD SMALL DELAY TO ENSURE TOKEN READY
        return FutureBuilder(
          future: Future.delayed(const Duration(milliseconds: 300)),
          builder: (context, _) {
            return const SuperAdminDashboard();
          },
        );
      },
    );
  }
}