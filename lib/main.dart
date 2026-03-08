// main.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:school_app/config/app_router.dart';
import 'package:school_app/core/constants/app_constants.dart';
import 'package:school_app/core/offline/firestore_offline.dart';
import 'package:school_app/core/offline/firestore_sync_tracker.dart';
import 'package:school_app/core/theme/app_theme.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // App Check hardening (Android: Play Integrity in release).
  // NOTE: When you enable "enforcement" for Firestore/Functions in Firebase Console,
  // debug builds will require registering a debug token.
  if (!kIsWeb) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      await FirebaseAppCheck.instance.activate(
        androidProvider: kReleaseMode ? AndroidProvider.playIntegrity : AndroidProvider.debug,
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      await FirebaseAppCheck.instance.activate(
        appleProvider: kReleaseMode ? AppleProvider.deviceCheck : AppleProvider.debug,
      );
    }
  }

  // Offline-first: queue writes locally and sync when connectivity returns.
  await configureFirestoreOfflinePersistence();
  FirestoreSyncTracker.instance.start();

  runApp(const ProviderScope(child: SchoolApp()));
}

class SchoolApp extends StatelessWidget {
  const SchoolApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      routerConfig: appRouter,
    );
  }
}
