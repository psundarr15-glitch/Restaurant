/// Backed by ManagerApiController::earnings() — every field here is a
/// real computed value, nothing is a placeholder.
class EarningsData {
  final double todayEarnings, todaySales, weekEarnings, monthEarnings, totalEarnings;
  final int todayOrders;
  final String rangeLabel, rangeFrom, rangeTo;
  final double grossSales, commission, deliveryCharges, refunds, netEarnings;
  final int completedOrders, cancelledOrders, refundPendingOrders;
  final double averageOrderValue;

  EarningsData({
    required this.todayEarnings,
    required this.todaySales,
    required this.todayOrders,
    required this.weekEarnings,
    required this.monthEarnings,
    required this.totalEarnings,
    required this.rangeLabel,
    required this.rangeFrom,
    required this.rangeTo,
    required this.grossSales,
    required this.commission,
    required this.deliveryCharges,
    required this.refunds,
    required this.netEarnings,
    required this.completedOrders,
    required this.cancelledOrders,
    required this.refundPendingOrders,
    required this.averageOrderValue,
  });

  static double _d(dynamic v) => double.tryParse(v?.toString() ?? '') ?? 0;
  static int _i(dynamic v) => int.tryParse(v?.toString() ?? '') ?? 0;

  factory EarningsData.fromJson(Map<String, dynamic> j) {
    final summary = j['summary'] as Map<String, dynamic>? ?? {};
    final range = j['range'] as Map<String, dynamic>? ?? {};
    final breakdown = j['breakdown'] as Map<String, dynamic>? ?? {};
    final stats = j['order_stats'] as Map<String, dynamic>? ?? {};

    return EarningsData(
      todayEarnings: _d(summary['today_earnings']),
      todaySales: _d(summary['today_sales']),
      todayOrders: _i(summary['today_orders']),
      weekEarnings: _d(summary['week_earnings']),
      monthEarnings: _d(summary['month_earnings']),
      totalEarnings: _d(summary['total_earnings']),
      rangeLabel: range['label']?.toString() ?? 'Today',
      rangeFrom: range['from']?.toString() ?? '',
      rangeTo: range['to']?.toString() ?? '',
      grossSales: _d(breakdown['gross_sales']),
      commission: _d(breakdown['commission']),
      deliveryCharges: _d(breakdown['delivery_charges']),
      refunds: _d(breakdown['refunds']),
      netEarnings: _d(breakdown['net_earnings']),
      completedOrders: _i(stats['completed_orders']),
      cancelledOrders: _i(stats['cancelled_orders']),
      refundPendingOrders: _i(stats['refund_pending_orders']),
      averageOrderValue: _d(stats['average_order_value']),
    );
  }
}
