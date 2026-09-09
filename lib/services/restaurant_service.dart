import 'dart:io';
import 'package:flutter/material.dart' show TimeOfDay;
import '../config/api_config.dart';
import '../models/restaurant.dart';
import '../models/order.dart';
import 'api_client.dart';

/// Minimal restaurant summary embedded in the dashboard response — just
/// enough for the Home header/status pill, not the full editable profile
/// (see [Restaurant] / [RestaurantService.view] for that).
class DashboardRestaurant {
  final String name;
  final bool isActive;
  final String? openingTime;
  final String? closingTime;
  final double rating;
  final int ratingCount;

  DashboardRestaurant({
    required this.name,
    required this.isActive,
    this.openingTime,
    this.closingTime,
    required this.rating,
    required this.ratingCount,
  });

  factory DashboardRestaurant.fromJson(Map<String, dynamic> j) => DashboardRestaurant(
        name: j['name']?.toString() ?? '',
        isActive: j['is_active'] == true || j['is_active'].toString() == '1',
        openingTime: j['opening_time']?.toString(),
        closingTime: j['closing_time']?.toString(),
        rating: double.tryParse(j['rating']?.toString() ?? '') ?? 0,
        ratingCount: int.tryParse(j['rating_count']?.toString() ?? '') ?? 0,
      );

  /// Mirrors the backend's RestaurantModel::isOpenNow(): the superadmin's
  /// is_active switch wins first (off always means closed), then falls
  /// back to comparing against opening/closing hours. This is
  /// intentionally read-only in the app — restaurant managers can't flip
  /// is_active themselves (superadmin-only, see ManagerApiController),
  /// so the Home screen shows this as a status pill, not a toggle.
  bool get isOpenNow {
    if (!isActive) return false;
    if (openingTime == null || closingTime == null) return true;
    final now = TimeOfDay.now();
    final nowMin = now.hour * 60 + now.minute;
    final open = _toMinutes(openingTime!);
    final close = _toMinutes(closingTime!);
    if (open == null || close == null) return true;
    if (open <= close) return nowMin >= open && nowMin <= close;
    return nowMin >= open || nowMin <= close; // overnight window
  }

  static int? _toMinutes(String hms) {
    final parts = hms.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return h * 60 + m;
  }
}

class DashboardData {
  final int totalOrders;
  final int totalMenuItems;
  final double revenue;
  final int todayOrders;
  final double todayRevenue;
  final double yesterdayRevenue;
  final int completedToday;
  final List<Order> pendingOrders;
  final List<Order> recentOrders;
  final DashboardRestaurant? restaurant;

  DashboardData({
    required this.totalOrders,
    required this.totalMenuItems,
    required this.revenue,
    required this.todayOrders,
    required this.todayRevenue,
    required this.yesterdayRevenue,
    required this.completedToday,
    required this.pendingOrders,
    required this.recentOrders,
    this.restaurant,
  });

  /// Null when there's no revenue yesterday to compare against (avoids a
  /// misleading "+infinite%"); the Home screen falls back to just showing
  /// today's total without a delta in that case.
  double? get percentVsYesterday {
    if (yesterdayRevenue <= 0) return null;
    return ((todayRevenue - yesterdayRevenue) / yesterdayRevenue) * 100;
  }
}

class RestaurantService {
  static Future<DashboardData> dashboard() async {
    final res = await ApiClient.get(ApiConfig.dashboard);
    return DashboardData(
      totalOrders: int.tryParse(res['total_orders'].toString()) ?? 0,
      totalMenuItems: int.tryParse(res['total_menu_items'].toString()) ?? 0,
      revenue: double.tryParse(res['revenue'].toString()) ?? 0,
      todayOrders: int.tryParse(res['today_orders']?.toString() ?? '') ?? 0,
      todayRevenue: double.tryParse(res['today_revenue']?.toString() ?? '') ?? 0,
      yesterdayRevenue: double.tryParse(res['yesterday_revenue']?.toString() ?? '') ?? 0,
      completedToday: int.tryParse(res['completed_today']?.toString() ?? '') ?? 0,
      pendingOrders: (res['pending_orders'] as List<dynamic>? ?? []).map((e) => Order.fromJson(e)).toList(),
      recentOrders: (res['recent_orders'] as List<dynamic>? ?? []).map((e) => Order.fromJson(e)).toList(),
      restaurant: res['restaurant'] != null
          ? DashboardRestaurant.fromJson(res['restaurant'] as Map<String, dynamic>)
          : null,
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
