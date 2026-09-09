import 'package:flutter/material.dart';
import '../../models/order.dart';
import '../../services/order_service.dart';
import '../../theme.dart';
import '../../widgets/order_card.dart';
import '../../widgets/common/search_and_filter.dart';
import '../../widgets/common/states.dart';
import 'order_detail_screen.dart';
import '../kitchen/kitchen_screen.dart';

/// Filter tabs shown here map to the real backend status values in
/// [kOrderStatusFlow] + 'cancelled' — not the spec's literal "Ready" /
/// "Picked Up" wording, since the backend doesn't have separate statuses
/// for those (see kOrderStatusFlow's doc comment: everything past
/// 'confirmed' is delivery-partner driven, and 'preparing' already
/// covers "picked up" in this app's status model). Inventing extra
/// client-side-only statuses would show data the backend can't back up.
const List<String> _filterStatuses = ['', 'placed', 'confirmed', 'preparing', 'out_for_delivery', 'delivered', 'cancelled'];
const List<String> _filterLabels = ['All', 'New', 'Confirmed', 'Preparing', 'Out for Delivery', 'Delivered', 'Cancelled'];

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  Future<List<Order>>? _future;
  int _filterIndex = 0;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() => _future = OrderService.list());
  }

  List<Order> _apply(List<Order> orders) {
    final status = _filterStatuses[_filterIndex];
    var result = status.isEmpty ? orders : orders.where((o) => o.orderStatus == status).toList();
    if (_search.trim().isNotEmpty) {
      final q = _search.trim().toLowerCase();
      result = result
          .where((o) => o.orderCode.toLowerCase().contains(q) || (o.customerName ?? '').toLowerCase().contains(q))
          .toList();
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg(context),
      appBar: AppBar(
        title: const Text('My Orders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.soup_kitchen_outlined),
            tooltip: 'Kitchen view',
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const KitchenScreen()))
                .then((_) => _load()),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: AppSearchBar(hint: 'Search by order ID or customer', onChanged: (v) => setState(() => _search = v)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FilterChipRow(
                labels: _filterLabels,
                selectedIndex: _filterIndex,
                onSelected: (i) => setState(() => _filterIndex = i),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => _load(),
                color: AppTheme.primary,
                child: FutureBuilder<List<Order>>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData && !snapshot.hasError) {
                      return const LoadingState();
                    }
                    if (snapshot.hasError) {
                      return ListView(children: [
                        const SizedBox(height: 40),
                        ErrorState(message: '${snapshot.error}', onRetry: _load),
                      ]);
                    }
                    final orders = _apply(snapshot.data!);
                    if (orders.isEmpty) {
                      return ListView(children: const [
                        SizedBox(height: 40),
                        EmptyState(icon: Icons.receipt_long_outlined, title: 'No orders here', subtitle: 'Orders matching this filter will show up here.'),
                      ]);
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
