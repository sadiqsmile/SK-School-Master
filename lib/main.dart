// main.dart
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:school_app/config/app_router.dart';
import 'package:school_app/core/constants/app_constants.dart';
import 'package:school_app/core/offline/firestore_offline.dart';
import 'package:school_app/core/offline/firestore_sync_tracker.dart';
import 'package:school_app/core/theme/app_theme.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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
      scrollBehavior: const _AdaptiveScrollBehavior(),
      builder: (context, child) {
        final media = MediaQuery.of(context);
        final clampedTextScaler = media.textScaler.clamp(
          minScaleFactor: 0.9,
          maxScaleFactor: 1.15,
        );

        return MediaQuery(
          data: media.copyWith(textScaler: clampedTextScaler),
          child: child ?? const SizedBox.shrink(),
        );
      },
      routerConfig: appRouter,
    );
  }
}

class _AdaptiveScrollBehavior extends MaterialScrollBehavior {
  const _AdaptiveScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
    PointerDeviceKind.unknown,
  };
}
