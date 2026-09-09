import 'package:flutter/material.dart';
import '../../models/order.dart';
import '../../services/order_service.dart';
import '../../theme.dart';
import '../../widgets/order_card.dart';
import 'order_detail_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(length: 2, vsync: this);
  Future<List<Order>>? _incoming;
  Future<List<Order>>? _all;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _incoming = OrderService.list(status: 'placed');
      _all = OrderService.list();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          tabs: const [Tab(text: 'Incoming'), Tab(text: 'All Orders')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _list(_incoming, emptyText: 'No new orders right now.'),
          _list(_all, emptyText: 'No orders yet.'),
        ],
      ),
    );
  }

  Widget _list(Future<List<Order>>? future, {required String emptyText}) {
    return RefreshIndicator(
      onRefresh: () async => _load(),
      child: FutureBuilder<List<Order>>(
        future: future,
        builder: (context, snapshot) {
          if (!snapshot.hasData && !snapshot.hasError) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
          }
          if (snapshot.hasError) {
            return ListView(children: [const SizedBox(height: 80), Center(child: Text('${snapshot.error}'))]);
          }
          final orders = snapshot.data!;
          if (orders.isEmpty) {
            return ListView(children: [
              const SizedBox(height: 80),
              Center(child: Text(emptyText, style: TextStyle(color: AppTheme.textSecondary(context)))),
            ]);
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, i) => OrderCard(
              order: orders[i],
              onTap: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: orders[i].id)))
                  .then((_) => _load()),
            ),
          );
        },
      ),
    );
  }
}
