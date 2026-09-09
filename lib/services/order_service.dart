import '../config/api_config.dart';
import '../models/order.dart';
import 'api_client.dart';

class OrderDetails {
  final Order order;
  final List<OrderItem> items;
  final List<TrackingEntry> history;
  OrderDetails({required this.order, required this.items, required this.history});
}

class OrderService {
  /// [status] = 'placed' for the Incoming tab; omit for full history.
  static Future<List<Order>> list({String? status}) async {
    final res = await ApiClient.get(ApiConfig.orders(status));
    return (res['orders'] as List<dynamic>? ?? []).map((e) => Order.fromJson(e)).toList();
  }

  static Future<OrderDetails> details(int orderId) async {
    final res = await ApiClient.get(ApiConfig.orderDetails(orderId));
    return OrderDetails(
      order: Order.fromJson(res['order'] as Map<String, dynamic>),
      items: (res['items'] as List<dynamic>? ?? []).map((e) => OrderItem.fromJson(e)).toList(),
      history: (res['history'] as List<dynamic>? ?? []).map((e) => TrackingEntry.fromJson(e)).toList(),
    );
  }

  static Future<void> accept(int orderId) => ApiClient.post(ApiConfig.acceptOrder(orderId));

  static Future<void> reject(int orderId, {String? reason}) =>
      ApiClient.post(ApiConfig.rejectOrder(orderId), {'reason': reason});
}
