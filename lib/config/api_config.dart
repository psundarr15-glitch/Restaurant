/// Backend API base URL — points at the live deployed backend, same
/// server the customer app talks to (see Config/Routes.php's `manager/*`
/// group, added specifically for this app).
class ApiConfig {
  static const String baseUrl = 'https://food.tvkomalur.xyz/api';

  static const String login = '$baseUrl/manager/login';
  static const String logout = '$baseUrl/manager/logout';
  static const String me = '$baseUrl/manager/me';
  static const String dashboard = '$baseUrl/manager/dashboard';

  static const String restaurant = '$baseUrl/manager/restaurant';
  static const String restaurantUpdate = '$baseUrl/manager/restaurant/update';

  static const String categories = '$baseUrl/manager/categories';
  static const String addSubCategory = '$baseUrl/manager/sub-categories/add';

  static const String menu = '$baseUrl/manager/menu';
  static const String menuAdd = '$baseUrl/manager/menu/add';
  static String menuUpdate(int id) => '$baseUrl/manager/menu/$id/update';
  static String menuDelete(int id) => '$baseUrl/manager/menu/$id/delete';
  static String menuToggleAvailability(int id) => '$baseUrl/manager/menu/$id/toggle-availability';

  /// [status] filters to one order_status (e.g. 'placed' for the
  /// Incoming tab); omit for the full history tab.
  static String orders([String? status]) =>
      status != null ? '$baseUrl/manager/orders?status=$status' : '$baseUrl/manager/orders';
  static String orderDetails(int id) => '$baseUrl/manager/orders/$id';
  static String acceptOrder(int id) => '$baseUrl/manager/orders/$id/accept';
  static String rejectOrder(int id) => '$baseUrl/manager/orders/$id/reject';
  static String kitchenStatus(int id) => '$baseUrl/manager/orders/$id/kitchen-status';

  static const String deviceToken = '$baseUrl/manager/device-token';
  static const String unregisterDeviceToken = '$baseUrl/manager/device-token/unregister';

  // --- Phase 5 ---
  static String earnings(String range, {String? from, String? to}) {
    var url = '$baseUrl/manager/earnings?range=$range';
    if (from != null) url += '&from=$from';
    if (to != null) url += '&to=$to';
    return url;
  }

  static String salesAnalytics(String range) => '$baseUrl/manager/sales-analytics?range=$range';

  static const String wallet = '$baseUrl/manager/wallet';
  static const String walletTransactions = '$baseUrl/manager/wallet-transactions';

  static const String settlements = '$baseUrl/manager/settlements';
  static String settlementDetails(int id) => '$baseUrl/manager/settlements/$id';

  static const String reviews = '$baseUrl/manager/reviews';
  static String replyToReview(int id) => '$baseUrl/manager/reviews/$id/reply';

  static const String offers = '$baseUrl/manager/offers';
  static const String addOffer = '$baseUrl/manager/offers/add';
  static String updateOffer(int id) => '$baseUrl/manager/offers/$id/update';
  static String toggleOffer(int id) => '$baseUrl/manager/offers/$id/toggle';
  static String deleteOffer(int id) => '$baseUrl/manager/offers/$id/delete';

  // Not manager-scoped (no auth needed) — same static content the
  // customer-facing site shows (Api\StaticContentApiController).
  static const String termsPage = '$baseUrl/pages/terms';
  static const String privacyPage = '$baseUrl/pages/privacy';
}
