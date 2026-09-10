class OfferTarget {
  final int id;
  final String name;
  OfferTarget({required this.id, required this.name});
  factory OfferTarget.fromJson(Map<String, dynamic> j) =>
      OfferTarget(id: int.tryParse(j['id']?.toString() ?? '') ?? 0, name: j['name']?.toString() ?? '');
}

class Offer {
  final int id;
  final String title;
  final String? description;
  final String discountType; // percentage | fixed
  final double discountValue;
  final double minOrderValue;
  final double? maxDiscount;
  final String startDate, endDate;
  final int? usageLimit;
  final int usedCount;
  final String applicableTo; // restaurant | item | category
  final bool isActive;
  final bool isLive;
  final List<OfferTarget> items;
  final List<OfferTarget> categories;

  Offer({
    required this.id,
    required this.title,
    this.description,
    required this.discountType,
    required this.discountValue,
    required this.minOrderValue,
    this.maxDiscount,
    required this.startDate,
    required this.endDate,
    this.usageLimit,
    required this.usedCount,
    required this.applicableTo,
    required this.isActive,
    required this.isLive,
    this.items = const [],
    this.categories = const [],
  });

  factory Offer.fromJson(Map<String, dynamic> j) => Offer(
        id: int.tryParse(j['id']?.toString() ?? '') ?? 0,
        title: j['title']?.toString() ?? '',
        description: j['description']?.toString(),
        discountType: j['discount_type']?.toString() ?? 'percentage',
        discountValue: double.tryParse(j['discount_value']?.toString() ?? '') ?? 0,
        minOrderValue: double.tryParse(j['min_order_value']?.toString() ?? '') ?? 0,
        maxDiscount: j['max_discount'] != null ? double.tryParse(j['max_discount'].toString()) : null,
        startDate: j['start_date']?.toString() ?? '',
        endDate: j['end_date']?.toString() ?? '',
        usageLimit: j['usage_limit'] != null ? int.tryParse(j['usage_limit'].toString()) : null,
        usedCount: int.tryParse(j['used_count']?.toString() ?? '') ?? 0,
        applicableTo: j['applicable_to']?.toString() ?? 'restaurant',
        isActive: j['is_active'] == true || j['is_active'].toString() == '1',
        isLive: j['is_live'] == true,
        items: (j['items'] as List<dynamic>? ?? []).map((e) => OfferTarget.fromJson(e)).toList(),
        categories: (j['categories'] as List<dynamic>? ?? []).map((e) => OfferTarget.fromJson(e)).toList(),
      );
}
