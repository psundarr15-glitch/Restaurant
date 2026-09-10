class SalesDay {
  final DateTime day;
  final double sales;
  final int orders;
  SalesDay({required this.day, required this.sales, required this.orders});

  factory SalesDay.fromJson(Map<String, dynamic> j) => SalesDay(
        day: DateTime.tryParse(j['day']?.toString() ?? '') ?? DateTime.now(),
        sales: double.tryParse(j['sales']?.toString() ?? '') ?? 0,
        orders: int.tryParse(j['orders']?.toString() ?? '') ?? 0,
      );
}

class TopFood {
  final String name;
  final int orderCount;
  final int quantity;
  final double revenue;
  TopFood({required this.name, required this.orderCount, required this.quantity, required this.revenue});

  factory TopFood.fromJson(Map<String, dynamic> j) => TopFood(
        name: j['item_name']?.toString() ?? '',
        orderCount: int.tryParse(j['order_count']?.toString() ?? '') ?? 0,
        quantity: int.tryParse(j['quantity']?.toString() ?? '') ?? 0,
        revenue: double.tryParse(j['revenue']?.toString() ?? '') ?? 0,
      );
}

class PeakHour {
  final int hour;
  final int orders;
  PeakHour({required this.hour, required this.orders});

  factory PeakHour.fromJson(Map<String, dynamic> j) => PeakHour(
        hour: int.tryParse(j['hour']?.toString() ?? '') ?? 0,
        orders: int.tryParse(j['orders']?.toString() ?? '') ?? 0,
      );
}

/// Backed by ManagerApiController::salesAnalytics(). `topCategoriesNote`
/// explains why category-level analytics aren't available yet (see that
/// endpoint's doc comment) — shown as an honest empty state, not hidden.
class SalesAnalyticsData {
  final List<SalesDay> salesChart;
  final List<TopFood> topFoods;
  final List<PeakHour> peakHours;
  final String topCategoriesNote;

  SalesAnalyticsData({required this.salesChart, required this.topFoods, required this.peakHours, required this.topCategoriesNote});

  factory SalesAnalyticsData.fromJson(Map<String, dynamic> j) => SalesAnalyticsData(
        salesChart: (j['sales_chart'] as List<dynamic>? ?? []).map((e) => SalesDay.fromJson(e)).toList(),
        topFoods: (j['top_foods'] as List<dynamic>? ?? []).map((e) => TopFood.fromJson(e)).toList(),
        peakHours: (j['peak_hours'] as List<dynamic>? ?? []).map((e) => PeakHour.fromJson(e)).toList(),
        topCategoriesNote: j['top_categories_note']?.toString() ?? '',
      );
}
