import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/router/app_router.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
  );


// await FirebaseAuth.instance.signInWithEmailAndPassword(
//   email: "sadiq.smile@gmail.com",
//   password: "admin@123",
// );


  
  runApp(
    const ProviderScope(
      child: SchoolApp(),
    ),
  );
}

class SchoolApp extends ConsumerWidget {
  const SchoolApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'SK School Master',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}