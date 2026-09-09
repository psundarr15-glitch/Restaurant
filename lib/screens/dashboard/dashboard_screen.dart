import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/restaurant_service.dart';
import '../../services/order_service.dart';
import '../../services/api_client.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../widgets/common/app_header.dart';
import '../../widgets/common/hero_earnings_card.dart';
import '../../widgets/common/stat_card.dart';
import '../../widgets/common/buttons.dart';
import '../../widgets/common/states.dart';
import '../../widgets/common/recent_order_tile.dart';
import '../../widgets/order_card.dart';
import '../orders/order_detail_screen.dart';
import '../orders/orders_screen.dart';
import '../menu/menu_screen.dart';
import '../profile/profile_screen.dart';

/// Restaurant Home dashboard. Kept as `DashboardScreen`/same route slot
/// as before (still tab 0 in [RootShell]) — only the layout changed, all
/// data still comes from the same `RestaurantService.dashboard()` call
/// (now returning a few additive fields; see that service for details).
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Future<DashboardData>? _future;
  Timer? _poller;

  @override
  void initState() {
    super.initState();
    _load();
    // Keeps the "New Order" queue fresh even if a push notification is
    // missed (app backgrounded, notifications permission denied, etc).
    _poller = Timer.periodic(const Duration(seconds: 20), (_) => _load(silent: true));
  }

  @override
  void dispose() {
    _poller?.cancel();
    super.dispose();
  }

  void _load({bool silent = false}) {
    final future = RestaurantService.dashboard();
    if (!silent) {
      setState(() => _future = future);
    } else {
      future.then((data) {
        if (mounted) setState(() => _future = Future.value(data));
      }).catchError((_) {});
    }
    context.read<AppState>().refreshPendingCount();
  }

  Future<void> _quickAccept(int orderId) async {
    try {
      await OrderService.accept(orderId);
      _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _quickReject(int orderId) async {
    try {
      await OrderService.reject(orderId);
      _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  void _openOrder(int orderId) => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: orderId)))
      .then((_) => _load());

  void _goTab(Widget screen) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg(context),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _load(),
          color: AppTheme.primary,
          child: FutureBuilder<DashboardData>(
            future: _future,
            builder: (context, snapshot) {
              if (!snapshot.hasData && !snapshot.hasError) {
                return const LoadingState();
              }
              if (snapshot.hasError) {
                return ListView(children: [
                  const SizedBox(height: 60),
                  ErrorState(message: '${snapshot.error}', onRetry: _load),
                ]);
              }
              final data = snapshot.data!;
              final restaurantName = data.restaurant?.name.isNotEmpty == true ? data.restaurant!.name : 'Restaurant';
              final isOpen = data.restaurant?.isOpenNow ?? true;

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  AppHeader(
                    restaurantName: restaurantName,
                    isOpen: isOpen,
                    onMenuTap: () => _goTab(const ProfileScreen()),
                  ),
                  const SizedBox(height: 18),
                  HeroEarningsCard(
                    todaySales: data.todayRevenue,
                    percentVsYesterday: data.percentVsYesterday,
                    ordersToday: data.todayOrders,
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.55,
                    children: [
                      StatCard(
                        label: 'Orders Today',
                        value: '${data.todayOrders}',
                        icon: Icons.receipt_long_rounded,
                        color: Colors.blue,
                        onTap: () => _goTab(const OrdersScreen()),
                      ),
                      StatCard(
                        label: 'Pending Orders',
                        value: '${data.pendingOrders.length}',
                        icon: Icons.hourglass_top_rounded,
                        color: Colors.orange,
                        onTap: () => _goTab(const OrdersScreen()),
                      ),
                      StatCard(
                        label: 'Completed Orders',
                        value: '${data.completedToday}',
                        icon: Icons.check_circle_rounded,
                        color: Colors.green,
                        onTap: () => _goTab(const OrdersScreen()),
                      ),
                      StatCard(
                        label: 'Rating',
                        value: data.restaurant != null && data.restaurant!.ratingCount > 0
                            ? data.restaurant!.rating.toStringAsFixed(1)
                            : '—',
                        icon: Icons.star_rounded,
                        color: AppTheme.gold,
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Text('Quick Actions',
                      style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: AppTheme.textPrimary(context))),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(color: AppTheme.surface(context), borderRadius: BorderRadius.circular(18)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        QuickActionButton(
                            label: 'Orders', icon: Icons.receipt_long_rounded, onTap: () => _goTab(const OrdersScreen())),
                        QuickActionButton(
                            label: 'Menu', icon: Icons.restaurant_menu_rounded, color: Colors.orange, onTap: () => _goTab(const MenuScreen())),
                        QuickActionButton(
                            label: 'Earnings',
                            icon: Icons.account_balance_wallet_rounded,
                            color: Colors.green,
                            onTap: () => ScaffoldMessenger.of(context)
                                .showSnackBar(const SnackBar(content: Text('Earnings — coming in the next update')))),
                        QuickActionButton(
                            label: 'Wallet',
                            icon: Icons.savings_rounded,
                            color: Colors.purple,
                            onTap: () => ScaffoldMessenger.of(context)
                                .showSnackBar(const SnackBar(content: Text('Wallet — coming in the next update')))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  if (data.pendingOrders.isNotEmpty) ...[
                    Text('New Orders (${data.pendingOrders.length})',
                        style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: AppTheme.textPrimary(context))),
                    const SizedBox(height: 10),
                    ...data.pendingOrders.map((order) => Column(
                          children: [
                            OrderCard(order: order, onTap: () => _openOrder(order.id)),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: Row(
                                children: [
                                  Expanded(child: SecondaryButton(label: 'Reject', color: Colors.red, onPressed: () => _quickReject(order.id))),
                                  const SizedBox(width: 10),
                                  Expanded(child: PrimaryButton(label: 'Accept', onPressed: () => _quickAccept(order.id))),
                                ],
                              ),
                            ),
                          ],
                        )),
                    const SizedBox(height: 8),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Recent Activity',
                          style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: AppTheme.textPrimary(context))),
                      TextButton(
                        onPressed: () => _goTab(const OrdersScreen()),
                        child: const Text('View All', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  if (data.recentOrders.isEmpty)
                    const EmptyState(icon: Icons.receipt_long_outlined, title: 'No orders yet')
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(color: AppTheme.surface(context), borderRadius: BorderRadius.circular(18)),
                      child: Column(
                        children: [
                          for (int i = 0; i < data.recentOrders.length; i++) ...[
                            RecentOrderTile(order: data.recentOrders[i], onTap: () => _openOrder(data.recentOrders[i].id)),
                            if (i != data.recentOrders.length - 1) Divider(height: 1, color: AppTheme.borderColor(context)),
                          ],
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
