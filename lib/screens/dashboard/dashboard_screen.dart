import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/restaurant_service.dart';
import '../../services/order_service.dart';
import '../../services/api_client.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../widgets/order_card.dart';
import '../orders/order_detail_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: RefreshIndicator(
        onRefresh: () async => _load(),
        child: FutureBuilder<DashboardData>(
          future: _future,
          builder: (context, snapshot) {
            if (!snapshot.hasData && !snapshot.hasError) {
              return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
            }
            if (snapshot.hasError) {
              return ListView(children: [
                const SizedBox(height: 80),
                Center(child: Text('${snapshot.error}')),
              ]);
            }
            final data = snapshot.data!;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Expanded(child: _statCard(context, 'Total Orders', '${data.totalOrders}', Icons.receipt_long)),
                    const SizedBox(width: 10),
                    Expanded(child: _statCard(context, 'Menu Items', '${data.totalMenuItems}', Icons.restaurant_menu)),
                  ],
                ),
                const SizedBox(height: 10),
                _statCard(context, 'Revenue (paid orders)', '₹${data.revenue.toStringAsFixed(0)}', Icons.currency_rupee),
                const SizedBox(height: 24),
                Text('New Orders (${data.pendingOrders.length})', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                if (data.pendingOrders.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text('No new orders right now.', style: TextStyle(color: AppTheme.textSecondary(context))),
                  )
                else
                  ...data.pendingOrders.map((order) => Column(
                        children: [
                          OrderCard(
                            order: order,
                            onTap: () => Navigator.of(context)
                                .push(MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: order.id)))
                                .then((_) => _load()),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => _quickReject(order.id),
                                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                                    child: const Text('Reject'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton(onPressed: () => _quickAccept(order.id), child: const Text('Accept')),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )),
                const SizedBox(height: 12),
                Text('Recent Orders', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                if (data.recentOrders.isEmpty)
                  Text('No orders yet.', style: TextStyle(color: AppTheme.textSecondary(context)))
                else
                  ...data.recentOrders.map((order) => OrderCard(
                        order: order,
                        onTap: () => Navigator.of(context)
                            .push(MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: order.id)))
                            .then((_) => _load()),
                      )),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _statCard(BuildContext context, String label, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppTheme.primary),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text(label, style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
