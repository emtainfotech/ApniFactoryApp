import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:apni_factory/api_services/creator_api_services.dart';
import 'package:apni_factory/main.dart';
import 'package:apni_factory/screens/brand_notification_screen.dart';
import 'package:apni_factory/screens/category_screen.dart';
import 'package:apni_factory/screens/Coupon_offer_screen.dart';
import 'package:apni_factory/screens/description_page_screen.dart';
import 'package:apni_factory/screens/notification_screen.dart';
import 'package:apni_factory/screens/order_history_screen.dart';
import 'package:apni_factory/screens/track_order_screen.dart';
import 'package:apni_factory/screens/wishlist_screen.dart';
import 'package:apni_factory/shared_pref.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:url_launcher/url_launcher.dart';

// Helper to download image bytes for BigPicture notification banner
Future<Uint8List?> _downloadNotificationImageBytes(String url) async {
  try {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 5);
    final request = await client
        .getUrl(Uri.parse(url))
        .timeout(const Duration(seconds: 8));
    final response = await request.close().timeout(const Duration(seconds: 8));
    if (response.statusCode == 200) {
      return await consolidateHttpClientResponseBytes(response)
          .timeout(const Duration(seconds: 8));
    }
  } catch (e) {
    if (kDebugMode) {
      log("Failed to download notification banner: $e");
    }
  }
  return null;
}

// Top-level Background Message Handler (Runs when app is killed/offline/background)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  log("📩 Background FCM Message Received: ${message.messageId} | Data: ${message.data}");

  final FlutterLocalNotificationsPlugin localPlugin = FlutterLocalNotificationsPlugin();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    "high_importance_channel",
    "High Importance Notification",
    description: "This channel is used for important notification",
    importance: Importance.max,
    playSound: true,
  );

  await localPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  String? title = message.notification?.title ?? message.data['title'];
  String? body = message.notification?.body ?? message.data['body'] ?? message.data['msg'];
  String? imageUrl = message.notification?.android?.imageUrl ??
      message.data['image'] ??
      message.data['banner'];

  if (title != null || body != null) {
    BigPictureStyleInformation? bigPictureStyle;
    if (imageUrl != null && imageUrl.isNotEmpty && imageUrl.startsWith('http')) {
      final bytes = await _downloadNotificationImageBytes(imageUrl);
      if (bytes != null) {
        final ByteArrayAndroidBitmap bitmap = ByteArrayAndroidBitmap(bytes);
        bigPictureStyle = BigPictureStyleInformation(
          bitmap,
          contentTitle: title,
          summaryText: body,
          hideExpandedLargeIcon: true,
        );
      }
    }

    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channel.id,
      channel.name,
      channelDescription: channel.description,
      importance: Importance.max,
      priority: Priority.high,
      styleInformation: bigPictureStyle,
      icon: '@mipmap/ic_launcher',
      playSound: true,
    );

    await localPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      NotificationDetails(android: androidDetails),
      payload: jsonEncode(message.data),
    );
  }
}

class NotificationServices {
  FirebaseMessaging? get _messaging =>
      Firebase.apps.isEmpty ? null : FirebaseMessaging.instance;

  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final AndroidNotificationChannel channel = const AndroidNotificationChannel(
    "high_importance_channel",
    "High Importance Notification",
    description: "This channel is used for important notification",
    importance: Importance.max,
    playSound: true,
  );

  Future<void> init(BuildContext context) async {
    if (_messaging == null) {
      return;
    }
    await requestNotificationPermission();
    await firebaseInit();
    await setupInteractedMessage();
    if (context.mounted) {
      isTokenRefresh(context);
    }
  }

  Future<void> requestNotificationPermission() async {
    final messaging = _messaging;
    if (messaging == null) return;
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: true,
      badge: true,
      carPlay: true,
      criticalAlert: true,
      provisional: true,
      sound: true,
    );
    if (kDebugMode) {
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        log("Notification permission granted");
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        log("Provisional notification permission granted");
      } else {
        log("Notification permission denied");
      }
    }
  }

  Future<void> firebaseInit() async {
    const AndroidInitializationSettings androidInitializationSetting =
        AndroidInitializationSettings("@mipmap/ic_launcher");

    final InitializationSettings initializationSettings =
        const InitializationSettings(android: androidInitializationSetting);

    await _localNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (response) {
        if (response.payload != null) {
          try {
            final Map<String, dynamic> data = jsonDecode(response.payload!);
            log("🔔 Local notification clicked with payload: $data");
            handleNotificationNavigation(data);
          } catch (e) {
            log("Error parsing notification payload: $e");
          }
        }
      },
    );

    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Foreground message handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log("📩 Foreground Message Received: ${message.notification?.title}");
      showNotification(message);
    });

    // Background notification tap
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      log("📩 Background notification tapped: ${message.data}");
      handleNotificationNavigation(message.data);
    });
  }

  Future<void> setupInteractedMessage() async {
    final messaging = _messaging;
    if (messaging == null) return;
    RemoteMessage? message = await messaging.getInitialMessage();
    if (message != null) {
      if (kDebugMode) {
        log("Cold-start notification tapped");
      }
      handleNotificationNavigation(message.data);
    }
  }

  Future<void> showNotification(RemoteMessage message) async {
    String? title = message.notification?.title ?? message.data['title'];
    String? body = message.notification?.body ?? message.data['body'] ?? message.data['msg'];
    String? imageUrl = message.notification?.android?.imageUrl ??
        message.data['image'] ??
        message.data['banner'];

    BigPictureStyleInformation? bigPictureStyle;
    if (imageUrl != null && imageUrl.isNotEmpty && imageUrl.startsWith('http')) {
      final bytes = await _downloadNotificationImageBytes(imageUrl);
      if (bytes != null) {
        final ByteArrayAndroidBitmap bitmap = ByteArrayAndroidBitmap(bytes);
        bigPictureStyle = BigPictureStyleInformation(
          bitmap,
          contentTitle: title,
          summaryText: body,
          hideExpandedLargeIcon: true,
        );
      }
    }

    AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
      channel.id,
      channel.name,
      channelDescription: channel.description,
      importance: Importance.max,
      priority: Priority.high,
      styleInformation: bigPictureStyle,
      icon: '@mipmap/ic_launcher',
      playSound: true,
    );

    final NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);

    await _localNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      notificationDetails,
      payload: jsonEncode(message.data),
    );
  }

  // Deep Link Navigator
  void handleNotificationNavigation(Map<String, dynamic> data) {
    final String? screen = data['screen']?.toString().toLowerCase().trim();
    final String? screenId = data['screenid']?.toString().trim();

    if (screen == null || screen.isEmpty || screen == 'none') {
      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => const NotificationScreen()),
      );
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      switch (screen) {
        case 'product':
          if (screenId != null && int.tryParse(screenId) != null) {
            navigatorKey.currentState?.push(
              MaterialPageRoute(
                builder: (_) => DescriptionPageScreen(
                  productId: int.parse(screenId),
                  colorId: "0",
                ),
              ),
            );
          }
          break;

        case 'category':
          if (screenId != null && int.tryParse(screenId) != null) {
            navigatorKey.currentState?.push(
              MaterialPageRoute(
                builder: (_) => CategoryScreen(mid: int.parse(screenId)),
              ),
            );
          }
          break;

        case 'orderdetail':
        case 'track_order':
          if (screenId != null && screenId.isNotEmpty) {
            navigatorKey.currentState?.push(
              MaterialPageRoute(
                builder: (_) => TrackOrderScreen(orderid: screenId),
              ),
            );
          }
          break;

        case 'orders':
        case 'order_history':
          navigatorKey.currentState?.push(
            MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
          );
          break;

        case 'wishlist':
          navigatorKey.currentState?.push(
            MaterialPageRoute(builder: (_) => const WishlistScreen()),
          );
          break;

        case 'coupon':
        case 'offers':
          navigatorKey.currentState?.push(
            MaterialPageRoute(builder: (_) => const CouponOfferScreen(couponof: "customer")),
          );
          break;

        case 'branddetail':
          if (screenId != null && screenId.isNotEmpty) {
            navigatorKey.currentState?.push(
              MaterialPageRoute(builder: (_) => BrandNotificationScreen(brandid: screenId)),
            );
          }
          break;

        case 'web':
        case 'url':
          if (screenId != null && screenId.isNotEmpty) {
            final uri = Uri.tryParse(screenId);
            if (uri != null) {
              launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          }
          break;

        default:
          navigatorKey.currentState?.push(
            MaterialPageRoute(builder: (_) => const NotificationScreen()),
          );
          break;
      }
    });
  }

  Future<String> getDeviceToken() async {
    final messaging = _messaging;
    if (messaging == null) return '';
    try {
      String? token = await messaging.getToken();
      return token ?? '';
    } catch (_) {
      return '';
    }
  }

  void isTokenRefresh(BuildContext context) {
    final messaging = _messaging;
    if (messaging == null) return;
    messaging.onTokenRefresh.listen((newToken) async {
      String email = await SharedPref.getUserEmailId();
      String userId = await SharedPref.getUserLoginId();
      if (email.isNotEmpty && userId.isNotEmpty && context.mounted) {
        await CreatorApiServices.loginDetails(
          context,
          email: email,
          password: null,
          deviceid: newToken,
        );
      }
    });
  }
}
