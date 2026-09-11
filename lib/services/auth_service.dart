import 'package:firebase_auth/firebase_auth.dart';
import '../config/api_config.dart';
import '../models/manager.dart';
import 'api_client.dart';
import 'notification_service.dart';

class AuthService {
  static Future<Manager> login({required String email, required String password}) async {
    final res = await ApiClient.post(ApiConfig.login, {'email': email, 'password': password});
    await ApiClient.setToken(res['token'] as String);
    NotificationService.registerCurrentToken();
    return Manager.fromJson(res['manager'] as Map<String, dynamic>);
  }

  static Future<void> logout() async {
    try {
      await NotificationService.unregisterCurrentToken();
      await ApiClient.post(ApiConfig.logout);
    } catch (_) {
      // Even if the network call fails, still clear the local token below.
    }
    await ApiClient.setToken(null);
    await FirebaseAuth.instance.signOut();
  }
}
