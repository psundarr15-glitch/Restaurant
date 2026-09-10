import '../config/api_config.dart';
import '../models/earnings.dart';
import '../models/sales_analytics.dart';
import '../models/wallet.dart';
import '../models/settlement.dart';
import 'api_client.dart';

class FinanceService {
  static Future<EarningsData> earnings(String range, {String? from, String? to}) async {
    final res = await ApiClient.get(ApiConfig.earnings(range, from: from, to: to));
    return EarningsData.fromJson(res);
  }

  static Future<SalesAnalyticsData> salesAnalytics(String range) async {
    final res = await ApiClient.get(ApiConfig.salesAnalytics(range));
    return SalesAnalyticsData.fromJson(res);
  }

  static Future<WalletSummary> wallet() async {
    final res = await ApiClient.get(ApiConfig.wallet);
    return WalletSummary.fromJson(res);
  }

  static Future<List<WalletTransaction>> walletTransactions() async {
    final res = await ApiClient.get(ApiConfig.walletTransactions);
    return (res['transactions'] as List<dynamic>? ?? []).map((e) => WalletTransaction.fromJson(e)).toList();
  }

  static Future<List<Settlement>> settlements() async {
    final res = await ApiClient.get(ApiConfig.settlements);
    return (res['settlements'] as List<dynamic>? ?? []).map((e) => Settlement.fromJson(e)).toList();
  }

  static Future<({Settlement settlement, List<WalletTransaction> transactions})> settlementDetails(int id) async {
    final res = await ApiClient.get(ApiConfig.settlementDetails(id));
    return (
      settlement: Settlement.fromJson(res['settlement'] as Map<String, dynamic>),
      transactions: (res['transactions'] as List<dynamic>? ?? []).map((e) => WalletTransaction.fromJson(e)).toList(),
    );
  }
}
