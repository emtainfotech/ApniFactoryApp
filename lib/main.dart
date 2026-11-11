import 'package:apni_factory/api_services/notification_services.dart';
import 'package:apni_factory/provider/notifier_provider.dart';
import 'package:apni_factory/res/app_text.dart';
import 'package:apni_factory/res/theme.dart';
import 'package:apni_factory/screens/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (_) {
    // Allow app startup to degrade gracefully when push services are unavailable.
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  final Widget? home;

  const MyApp({super.key, this.home});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: AppProvider.notifierProvider(),
        child: MaterialApp(
          navigatorKey: navigatorKey,
          title: AppText.apniFactory,
          theme: AppTheme.themeData(),
          home: home ?? const SpalshScreen(),
        ));
  }
}
