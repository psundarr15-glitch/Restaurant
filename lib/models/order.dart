class OrderItem {
  final String itemName;
  final double price;
  final int quantity;
  final bool isVeg;

  OrderItem({required this.itemName, required this.price, required this.quantity, this.isVeg = true});

  factory OrderItem.fromJson(Map<String, dynamic> j) => OrderItem(
        itemName: j['item_name']?.toString() ?? '',
        price: double.tryParse(j['price']?.toString() ?? '') ?? 0,
        quantity: int.tryParse(j['quantity']?.toString() ?? '') ?? 0,
        isVeg: j['is_veg'] == true || j['is_veg'].toString() == '1',
      );
}

class TrackingEntry {
  final String status;
  final String? note;
  final String? createdAt;
  TrackingEntry({required this.status, this.note, this.createdAt});
  factory TrackingEntry.fromJson(Map<String, dynamic> j) => TrackingEntry(
        status: j['status']?.toString() ?? '',
        note: j['note']?.toString(),
        createdAt: j['created_at']?.toString(),
      );
}

/// Matches OrderModel::$STATUS_FLOW on the backend. A restaurant manager
/// only ever *acts* on 'placed' orders (confirm/reject) — everything
/// after 'confirmed' is driven by the delivery partner app — but sees
/// every stage in the order history list.
const List<String> kOrderStatusFlow = ['placed', 'confirmed', 'preparing', 'out_for_delivery', 'delivered'];

class Order {
  final int id;
  final String orderCode;
  final int restaurantId;
  final String? customerName;
  final String? customerPhone;
  final double subtotal;
  final double discount;
  final double deliveryFee;
  final double total;
  final String paymentMethod;
  final String paymentStatus;
  final String orderStatus;
  final String? placedAt;

  Order({
    required this.id,
    required this.orderCode,
    required this.restaurantId,
    this.customerName,
    this.customerPhone,
    required this.subtotal,
    required this.discount,
    required this.deliveryFee,
    required this.total,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.orderStatus,
    this.placedAt,
  });

  factory Order.fromJson(Map<String, dynamic> j) => Order(
        id: int.parse(j['id'].toString()),
        orderCode: j['order_code']?.toString() ?? '',
        restaurantId: int.tryParse(j['restaurant_id']?.toString() ?? '') ?? 0,
        customerName: j['customer_name']?.toString(),
        customerPhone: j['customer_phone']?.toString(),
        subtotal: double.tryParse(j['subtotal']?.toString() ?? '') ?? 0,
        discount: double.tryParse(j['discount']?.toString() ?? '') ?? 0,
        deliveryFee: double.tryParse(j['delivery_fee']?.toString() ?? '') ?? 0,
        total: double.tryParse(j['total']?.toString() ?? '') ?? 0,
        paymentMethod: j['payment_method']?.toString() ?? 'cod',
        paymentStatus: j['payment_status']?.toString() ?? 'pending',
        orderStatus: j['order_status']?.toString() ?? 'placed',
        placedAt: (j['placed_at'] ?? j['created_at'])?.toString(),
      );
}
