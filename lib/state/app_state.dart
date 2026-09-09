import 'package:flutter/foundation.dart';
import '../models/manager.dart';
import '../services/api_client.dart';
import '../services/order_service.dart';
import '../services/notification_service.dart';

class AppState extends ChangeNotifier {
  bool isLoggedIn = false;
  Manager? currentManager;
  int pendingOrderCount = 0;

  Future<void> bootstrap() async {
    final token = await ApiClient.getToken();
    isLoggedIn = token != null;
    if (isLoggedIn) {
      await refreshPendingCount();
      // Re-attach the FCM token now that we have an auth token - covers
      // the case where Firebase got a token before login happened.
      NotificationService.registerCurrentToken();
    }
    notifyListeners();
  }

  void setLoggedIn(Manager manager) {
    isLoggedIn = true;
    currentManager = manager;
    notifyListeners();
    refreshPendingCount();
  }

  void logout() {
    isLoggedIn = false;
    currentManager = null;
    pendingOrderCount = 0;
    notifyListeners();
  }

  /// Drives the "Incoming" tab badge — polled from the dashboard/orders
  /// screens after every accept/reject action and periodically while
  /// the app is open.
  Future<void> refreshPendingCount() async {
    try {
      final pending = await OrderService.list(status: 'placed');
      pendingOrderCount = pending.length;
      notifyListeners();
    } catch (_) {
      // not logged in / network issue — badge just stays as-is
    }
  }
}
