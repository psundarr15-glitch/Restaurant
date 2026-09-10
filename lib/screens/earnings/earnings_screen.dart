import 'package:flutter/material.dart';
import '../../models/earnings.dart';
import '../../services/finance_service.dart';
import '../../services/api_client.dart';
import '../../theme.dart';
import '../../widgets/common/stat_card.dart';
import '../../widgets/common/search_and_filter.dart';
import '../../widgets/common/states.dart';
import '../analytics/sales_analytics_screen.dart';
import '../wallet/wallet_screen.dart';
import '../settlements/settlements_screen.dart';

/// Earnings hub — per the Phase 5 brief's navigation note (section 13),
/// this is where Analytics/Wallet/Settlements live as secondary
/// navigation cards rather than each getting their own bottom-nav slot.
class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});
  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  static const _ranges = ['today', 'yesterday', 'week', 'month'];
  static const _rangeLabels = ['Today', 'Yesterday', 'This Week', 'This Month'];

  Future<EarningsData>? _future;
  int _rangeIndex = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() => _future = FinanceService.earnings(_ranges[_rangeIndex]));
  }

  String _money(double v) => '₹${v.toStringAsFixed(0)}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg(context),
      appBar: AppBar(title: const Text('Earnings')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _load(),
          color: AppTheme.primary,
          child: FutureBuilder<EarningsData>(
            future: _future,
            builder: (context, snapshot) {
              if (!snapshot.hasData && !snapshot.hasError) return const LoadingState();
              if (snapshot.hasError) {
                return ListView(children: [
                  const SizedBox(height: 60),
                  ErrorState(message: _errorMessage(snapshot.error), onRetry: _load),
                ]);
              }
              final data = snapshot.data!;

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  // --- Quick summary (always today/week/month/total) ---
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.7,
                    children: [
                      StatCard(label: "Today's Earnings", value: _money(data.todayEarnings), icon: Icons.today_rounded, color: Colors.green),
                      StatCard(label: "Today's Orders", value: '${data.todayOrders}', icon: Icons.receipt_long_rounded, color: Colors.blue),
                      StatCard(label: 'This Week', value: _money(data.weekEarnings), icon: Icons.calendar_view_week_rounded, color: Colors.orange),
                      StatCard(label: 'This Month', value: _money(data.monthEarnings), icon: Icons.calendar_month_rounded, color: Colors.purple),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppTheme.surface(context), borderRadius: BorderRadius.circular(18)),
                    child: Row(
                      children: [
                        const Icon(Icons.account_balance_wallet_rounded, color: AppTheme.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Total Earnings', style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondary(context))),
                              Text(_money(data.totalEarnings), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),
                  Text('Financial Breakdown', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: AppTheme.textPrimary(context))),
                  const SizedBox(height: 10),
                  FilterChipRow(labels: _rangeLabels, selectedIndex: _rangeIndex, onSelected: (i) {
                    setState(() => _rangeIndex = i);
                    _load();
                  }),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppTheme.surface(context), borderRadius: BorderRadius.circular(18)),
                    child: Column(
                      children: [
                        _breakdownRow(context, 'Gross Sales', data.grossSales),
                        _breakdownRow(context, 'Commission / Platform Fee', -data.commission),
                        _breakdownRow(context, 'Refunds', -data.refunds, subtitle: 'Orders paid then cancelled'),
                        const Divider(height: 20),
                        _breakdownRow(context, 'Net Earnings', data.netEarnings, bold: true),
                        const Divider(height: 20),
                        _breakdownRow(context, 'Delivery Charges', data.deliveryCharges, subtitle: "Collected for delivery — not the restaurant's revenue", muted: true),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),
                  Text('Order Statistics', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: AppTheme.textPrimary(context))),
                  const SizedBox(height: 10),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.7,
                    children: [
                      StatCard(label: 'Completed Orders', value: '${data.completedOrders}', icon: Icons.check_circle_rounded, color: Colors.green),
                      StatCard(label: 'Cancelled Orders', value: '${data.cancelledOrders}', icon: Icons.cancel_rounded, color: Colors.red),
                      StatCard(label: 'Refund Pending', value: '${data.refundPendingOrders}', icon: Icons.currency_exchange_rounded, color: Colors.orange),
                      StatCard(label: 'Avg. Order Value', value: _money(data.averageOrderValue), icon: Icons.trending_up_rounded, color: Colors.blue),
                    ],
                  ),

                  const SizedBox(height: 22),
                  Text('More', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: AppTheme.textPrimary(context))),
                  const SizedBox(height: 10),
                  _navCard(context, icon: Icons.bar_chart_rounded, title: 'Sales Analytics', subtitle: 'Trends, top items, peak hours',
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SalesAnalyticsScreen()))),
                  const SizedBox(height: 10),
                  _navCard(context, icon: Icons.account_balance_wallet_outlined, title: 'Wallet', subtitle: 'Balance & transaction history',
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WalletScreen()))),
                  const SizedBox(height: 10),
                  _navCard(context, icon: Icons.receipt_long_outlined, title: 'Settlements', subtitle: 'Payout history to your bank',
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettlementsScreen()))),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  String _errorMessage(Object? e) => e is ApiException ? e.message : '$e';

  Widget _breakdownRow(BuildContext context, String label, double value, {bool bold = false, bool muted = false, String? subtitle}) {
    final color = muted ? AppTheme.textSecondary(context) : (bold ? AppTheme.textPrimary(context) : (value < 0 ? Colors.red.shade600 : AppTheme.textPrimary(context)));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: bold ? 15 : 13.5, fontWeight: bold ? FontWeight.w800 : FontWeight.w500, color: muted ? color : AppTheme.textPrimary(context))),
                if (subtitle != null) Text(subtitle, style: TextStyle(fontSize: 11, color: AppTheme.textSecondary(context))),
              ],
            ),
          ),
          Text('${value < 0 ? '-' : ''}₹${value.abs().toStringAsFixed(0)}',
              style: TextStyle(fontSize: bold ? 16 : 13.5, fontWeight: bold ? FontWeight.w800 : FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  Widget _navCard(BuildContext context, {required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return Material(
      color: AppTheme.surface(context),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: AppTheme.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
                    Text(subtitle, style: TextStyle(fontSize: 12, color: AppTheme.textSecondary(context))),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
