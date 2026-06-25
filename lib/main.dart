import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'core/services/notification_service.dart';
import 'core/constants/api_constants.dart';
import 'features/auth/presentation/pages/splash_page.dart';
import 'features/dashboard/presentation/pages/main_navigation.dart';
import 'features/wallet/data/repositories/wallet_repository.dart';
import 'core/routes/app_router.dart';
import 'core/theme/app_colors.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/services/biometric_service.dart';
import 'core/services/auth_service.dart';
import 'features/wallet/presentation/pages/payment_confirmation_page.dart';
import 'features/wallet/presentation/pages/connect_app_page.dart';
import 'features/wallet/presentation/pages/disconnect_app_page.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('ic_notification');
  const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  runApp(const EMoneyApp());
}

class EMoneyApp extends StatefulWidget {
  static bool isAppUnlocked = false;
  static Uri? pendingDeepLink;
  static final ValueNotifier<bool> refreshTrigger = ValueNotifier(false);

  const EMoneyApp({super.key});

  static void processPendingDeepLink() {
    if (pendingDeepLink != null) {
      _pushDeepLinkRoute(pendingDeepLink!);
      pendingDeepLink = null;
    }
  }

  static void _pushDeepLinkRoute(Uri uri) {
    if (uri.scheme == 'emoneyapp') {
      if (uri.host == 'pay') {
        final invoiceId = uri.queryParameters['invoice_id'];
        final amount = double.tryParse(uri.queryParameters['amount'] ?? '');
        final token = uri.queryParameters['token'];

        if (invoiceId != null && amount != null && token != null) {
          if (navigatorKey.currentState != null) {
            navigatorKey.currentState!.push(
              MaterialPageRoute(
                builder: (context) => PaymentConfirmationPage(
                  invoiceId: invoiceId,
                  amount: amount,
                  token: token,
                ),
              ),
            );
          }
        }
      } else if (uri.host == 'connect') {
        if (navigatorKey.currentState != null) {
          navigatorKey.currentState!.push(
            MaterialPageRoute(
              builder: (context) => const ConnectAppPage(),
            ),
          ).then((_) {
            NotificationService.updateUnreadCount();
            EMoneyApp.refreshTrigger.value = !EMoneyApp.refreshTrigger.value;
          });
        }
      } else if (uri.host == 'disconnect') {
        if (navigatorKey.currentState != null) {
          navigatorKey.currentState!.push(
            MaterialPageRoute(
              builder: (context) => const DisconnectAppPage(),
            ),
          ).then((_) {
            NotificationService.updateUnreadCount();
            EMoneyApp.refreshTrigger.value = !EMoneyApp.refreshTrigger.value;
          });
        }
      }
    }
  }

  @override
  State<EMoneyApp> createState() => _EMoneyAppState();
}

class _EMoneyAppState extends State<EMoneyApp> {
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      _handleDeepLink(initialUri);
    }

    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    }, onError: (err) {
      debugPrint('Error mendengarkan deep link: $err');
    });
  }

  void _handleDeepLink(Uri uri) {
    if (EMoneyApp.isAppUnlocked) {
      EMoneyApp._pushDeepLinkRoute(uri);
    } else {
      EMoneyApp.pendingDeepLink = uri;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'E-Money Mamah Saya',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryColor),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primaryColor,
          foregroundColor: Colors.white,
        ),
        useMaterial3: true,
      ),
      initialRoute: AppRouter.splash,
      routes: AppRouter.routes,
    );
  }
}
