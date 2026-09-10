import '../config/api_config.dart';
import '../models/offer.dart';
import 'api_client.dart';

class OfferService {
  static Future<List<Offer>> list() async {
    final res = await ApiClient.get(ApiConfig.offers);
    return (res['offers'] as List<dynamic>? ?? []).map((e) => Offer.fromJson(e)).toList();
  }

  static Future<void> add({
    required String title,
    String? description,
    required String discountType,
    required double discountValue,
    required double minOrderValue,
    double? maxDiscount,
    required DateTime startDate,
    required DateTime endDate,
    int? usageLimit,
    required String applicableTo,
    required bool isActive,
    List<int>? itemIds,
    List<int>? categoryIds,
  }) =>
      ApiClient.post(ApiConfig.addOffer, _fields(
        title: title,
        description: description,
        discountType: discountType,
        discountValue: discountValue,
        minOrderValue: minOrderValue,
        maxDiscount: maxDiscount,
        startDate: startDate,
        endDate: endDate,
        usageLimit: usageLimit,
        applicableTo: applicableTo,
        isActive: isActive,
        itemIds: itemIds,
        categoryIds: categoryIds,
      ));

  static Future<void> update(
    int id, {
    required String title,
    String? description,
    required String discountType,
    required double discountValue,
    required double minOrderValue,
    double? maxDiscount,
    required DateTime startDate,
    required DateTime endDate,
    int? usageLimit,
    required String applicableTo,
    required bool isActive,
    List<int>? itemIds,
    List<int>? categoryIds,
  }) =>
      ApiClient.post(ApiConfig.updateOffer(id), _fields(
        title: title,
        description: description,
        discountType: discountType,
        discountValue: discountValue,
        minOrderValue: minOrderValue,
        maxDiscount: maxDiscount,
        startDate: startDate,
        endDate: endDate,
        usageLimit: usageLimit,
        applicableTo: applicableTo,
        isActive: isActive,
        itemIds: itemIds,
        categoryIds: categoryIds,
      ));

  static Map<String, dynamic> _fields({
    required String title,
    String? description,
    required String discountType,
    required double discountValue,
    required double minOrderValue,
    double? maxDiscount,
    required DateTime startDate,
    required DateTime endDate,
    int? usageLimit,
    required String applicableTo,
    required bool isActive,
    List<int>? itemIds,
    List<int>? categoryIds,
  }) {
    String fmt(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    return {
      'title': title,
      'description': description ?? '',
      'discount_type': discountType,
      'discount_value': discountValue,
      'min_order_value': minOrderValue,
      'max_discount': maxDiscount ?? '',
      'start_date': fmt(startDate),
      'end_date': fmt(endDate),
      'usage_limit': usageLimit ?? '',
      'applicable_to': applicableTo,
      'is_active': isActive ? '1' : '0',
      if (itemIds != null) 'item_ids': itemIds,
      if (categoryIds != null) 'category_ids': categoryIds,
    };
  }

  static Future<void> toggle(int id) => ApiClient.post(ApiConfig.toggleOffer(id));
  static Future<void> delete(int id) => ApiClient.post(ApiConfig.deleteOffer(id));
}
