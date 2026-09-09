import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import 'api_client.dart';

/// Same FCM setup as the customer app's NotificationService, adapted
/// for restaurant managers: the payload carries `order_id` (an int) not
/// `order_code`, since Api\ManagerApiController::acceptOrder/
/// CheckoutApiController::placeOrder send that instead. Tapping a "New
/// order received!" push takes the manager straight to that order's
/// detail screen (with the Accept/Reject buttons if it's still pending).
class NotificationService {
  static final _messaging = FirebaseMessaging.instance;
  static final _localNotifications = FlutterLocalNotificationsPlugin();

  static const _channelId = 'new_orders';
  static const _channelName = 'New orders';
  static const _prefKey = 'notifications_enabled';

  /// Settings screen's Notifications toggle. This only controls the
  /// in-app foreground banner shown by [_showForegroundNotification] —
  /// there's no backend field for a manager-level notification
  /// preference, and background/killed-app pushes are handled by the OS
  /// once FCM delivers them, which no app-side flag can suppress. So
  /// "off" here means "don't pop a banner while I'm already looking at
  /// the app", not "stop all notifications" — the toggle's subtitle in
  /// Settings says this explicitly rather than implying more than it does.
  static Future<bool> notificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKey) ?? true;
  }

  static Future<void> setNotificationsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, value);
  }

  static Future<void> init({required GlobalKey<NavigatorState> navigatorKey}) async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    await _localNotifications.initialize(
      const InitializationSettings(android: AndroidInitializationSettings('@drawable/ic_stat_notify')),
      onDidReceiveNotificationResponse: (response) {
        final orderId = response.payload;
        final nav = navigatorKey.currentState;
        if (nav != null && orderId != null && orderId.isNotEmpty) {
          nav.pushNamed('/order-detail', arguments: int.tryParse(orderId));
        }
      },
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: 'A new order needs to be accepted or rejected',
          importance: Importance.max,
        ));

    final token = await _messaging.getToken();
    if (token != null) await _registerToken(token);
    _messaging.onTokenRefresh.listen(_registerToken);

    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
    FirebaseMessaging.onMessageOpenedApp.listen((message) => _handleTap(message, navigatorKey));

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) _handleTap(initialMessage, navigatorKey);
  }

  /// Call again right after a successful login, in case permission/token
  /// weren't available yet at app-start.
  static Future<void> registerCurrentToken() async {
    final token = await _messaging.getToken();
    if (token != null) await _registerToken(token);
  }

  static Future<void> unregisterCurrentToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await ApiClient.post(ApiConfig.unregisterDeviceToken, {'fcm_token': token});
      }
    } catch (_) {
      // Not logged in, or a transient network error - fine either way.
    }
  }

  static Future<void> _registerToken(String token) async {
    try {
      await ApiClient.post(ApiConfig.deviceToken, {'fcm_token': token, 'platform': 'android'});
    } catch (_) {
      // Not logged in yet - we'll try again on next launch or token refresh.
    }
  }

  static Future<void> _showForegroundNotification(RemoteMessage message) async {
    if (!await notificationsEnabled()) return;
    final title = message.notification?.title ?? 'New order';
    final body = message.notification?.body ?? '';
    final orderId = message.data['order_id'];

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      importance: Importance.max,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(body, contentTitle: title),
    );

    await _localNotifications.show(
      message.hashCode,
      title,
      body,
      NotificationDetails(android: androidDetails),
      payload: orderId?.toString(),
    );
  }

  static void _handleTap(RemoteMessage message, GlobalKey<NavigatorState> navigatorKey) {
    final orderId = message.data['order_id'];
    final nav = navigatorKey.currentState;
    if (nav == null || orderId == null) return;
    nav.pushNamed('/order-detail', arguments: int.tryParse(orderId.toString()));
  }
}
