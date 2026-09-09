import 'dart:io';
import '../config/api_config.dart';
import '../models/restaurant.dart';
import '../models/order.dart';
import 'api_client.dart';

class DashboardData {
  final int totalOrders;
  final int totalMenuItems;
  final double revenue;
  final List<Order> pendingOrders;
  final List<Order> recentOrders;

  DashboardData({
    required this.totalOrders,
    required this.totalMenuItems,
    required this.revenue,
    required this.pendingOrders,
    required this.recentOrders,
  });
}

class RestaurantService {
  static Future<DashboardData> dashboard() async {
    final res = await ApiClient.get(ApiConfig.dashboard);
    return DashboardData(
      totalOrders: int.tryParse(res['total_orders'].toString()) ?? 0,
      totalMenuItems: int.tryParse(res['total_menu_items'].toString()) ?? 0,
      revenue: double.tryParse(res['revenue'].toString()) ?? 0,
      pendingOrders: (res['pending_orders'] as List<dynamic>? ?? []).map((e) => Order.fromJson(e)).toList(),
      recentOrders: (res['recent_orders'] as List<dynamic>? ?? []).map((e) => Order.fromJson(e)).toList(),
    );
  }

  static Future<Restaurant> view() async {
    final res = await ApiClient.get(ApiConfig.restaurant);
    return Restaurant.fromJson(res['restaurant'] as Map<String, dynamic>);
  }

  static Future<Restaurant> update(
    Map<String, dynamic> fields, {
    File? image,
    File? logo,
    File? fssaiCertificate,
    File? tinCertificate,
  }) async {
    final files = <String, File>{};
    if (image != null) files['image'] = image;
    if (logo != null) files['logo'] = logo;
    if (fssaiCertificate != null) files['fssai_certificate'] = fssaiCertificate;
    if (tinCertificate != null) files['tin_certificate'] = tinCertificate;

    final res = await ApiClient.postMultipart(ApiConfig.restaurantUpdate, fields, files: files);
    return Restaurant.fromJson(res['restaurant'] as Map<String, dynamic>);
  }
}
