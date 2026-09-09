import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/order.dart';
import '../../services/order_service.dart';
import '../../services/api_client.dart';
import '../../theme.dart';
import '../../widgets/common/search_and_filter.dart';
import '../../widgets/common/buttons.dart';
import '../../widgets/common/states.dart';
import '../orders/order_detail_screen.dart';

/// Kitchen board — a busy-hours-friendly view of live orders grouped
/// into NEW / PREPARING / READY / COMPLETED.
///
/// NEW uses `order_status` ('placed') since Accept/Reject genuinely are
/// order-level actions. PREPARING/READY use the separate
/// `kitchen_status` field instead of `order_status`: `order_status`'s
/// own 'preparing' value is set by the delivery partner app the moment
/// a partner claims the job (DeliveryApiController::acceptOrder), and
/// that flow's "available jobs" query filters on order_status =
/// 'confirmed' — so a kitchen action can't be allowed to change
/// order_status without silently pulling accepted orders out of every
/// delivery partner's job list. kitchen_status tracks the restaurant's
/// own prep progress without touching any of that (see
/// ManagerApiController::updateKitchenStatus).
class KitchenScreen extends StatefulWidget {
  const KitchenScreen({super.key});
  @override
  State<KitchenScreen> createState() => _KitchenScreenState();
}

enum _Board { newOrders, preparing, ready, completed }

class _KitchenScreenState extends State<KitchenScreen> {
  static const _labels = ['New', 'Preparing', 'Ready', 'Completed'];

  Future<List<Order>>? _future;
  int _tab = 0;
  Timer? _ticker;
  Timer? _poller;
  final _busy = <int>{};

  @override
  void initState() {
    super.initState();
    _load();
    _poller = Timer.periodic(const Duration(seconds: 20), (_) => _load(silent: true));
    _ticker = Timer.periodic(const Duration(seconds: 60), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _poller?.cancel();
    _ticker?.cancel();
    super.dispose();
  }

  void _load({bool silent = false}) {
    final future = OrderService.list();
    if (silent) {
      future.then((data) {
        if (mounted) setState(() => _future = Future.value(data));
      }).catchError((_) {});
    } else {
      setState(() => _future = future);
    }
  }

  bool _inKitchenFlow(Order o) => !['placed', 'cancelled', 'delivered'].contains(o.orderStatus);

  List<Order> _forBoard(_Board board, List<Order> all) {
    switch (board) {
      case _Board.newOrders:
        return all.where((o) => o.orderStatus == 'placed').toList();
      case _Board.preparing:
        return all.where((o) => _inKitchenFlow(o) && o.kitchenStatus != 'ready').toList();
      case _Board.ready:
        return all.where((o) => _inKitchenFlow(o) && o.kitchenStatus == 'ready').toList();
      case _Board.completed:
        return all.where((o) => o.orderStatus == 'delivered').toList();
    }
  }

  Future<void> _accept(int orderId) async {
    setState(() => _busy.add(orderId));
    try {
      await OrderService.accept(orderId, prepTimeMin: 20);
      _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy.remove(orderId));
    }
  }

  Future<void> _reject(int orderId) async {
    setState(() => _busy.add(orderId));
    try {
      await OrderService.reject(orderId);
      _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy.remove(orderId));
    }
  }

  Future<void> _advanceKitchen(int orderId, String nextStatus) async {
    setState(() => _busy.add(orderId));
    try {
      await OrderService.updateKitchenStatus(orderId, nextStatus);
      _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy.remove(orderId));
    }
  }

  String _elapsed(String? placedAt) {
    if (placedAt == null) return '';
    final dt = DateTime.tryParse(placedAt);
    if (dt == null) return '';
    final mins = DateTime.now().difference(dt).inMinutes;
    if (mins < 1) return 'just now';
    if (mins < 60) return '$mins min ago';
    return '${(mins / 60).floor()}h ${mins % 60}m ago';
  }

  @override
  Widget build(BuildContext context) {
    final board = _Board.values[_tab];
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg(context),
      appBar: AppBar(title: const Text('Kitchen')),
      body: SafeArea(
        child: FutureBuilder<List<Order>>(
          future: _future,
          builder: (context, snapshot) {
            if (!snapshot.hasData && !snapshot.hasError) return const LoadingState();
            if (snapshot.hasError) return ErrorState(message: '${snapshot.error}', onRetry: _load);

            final all = snapshot.data!;
            final counts = _Board.values.map((b) => _forBoard(b, all).length).toList();
            final orders = _forBoard(board, all)..sort((a, b) => (a.placedAt ?? '').compareTo(b.placedAt ?? ''));

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: FilterChipRow(labels: _labels, counts: counts, selectedIndex: _tab, onSelected: (i) => setState(() => _tab = i)),
                ),
                Expanded(
                  child: orders.isEmpty
                      ? EmptyState(icon: Icons.soup_kitchen_outlined, title: 'No ${_labels[_tab].toLowerCase()} orders right now')
                      : RefreshIndicator(
                          onRefresh: () async => _load(),
                          color: AppTheme.primary,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            itemCount: orders.length,
                            itemBuilder: (context, i) {
                              final order = orders[i];
                              return _KitchenCard(
                                order: order,
                                board: board,
                                elapsedText: _elapsed(order.placedAt),
                                busy: _busy.contains(order.id),
                                onAccept: () => _accept(order.id),
                                onReject: () => _reject(order.id),
                                onStartPreparing: () => _advanceKitchen(order.id, 'preparing'),
                                onMarkReady: () => _advanceKitchen(order.id, 'ready'),
                                onTap: () => Navigator.of(context)
                                    .push(MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: order.id)))
                                    .then((_) => _load()),
                              );
                            },
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _KitchenCard extends StatelessWidget {
  final Order order;
  final _Board board;
  final String elapsedText;
  final bool busy;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onStartPreparing;
  final VoidCallback onMarkReady;
  final VoidCallback onTap;

  const _KitchenCard({
    required this.order,
    required this.board,
    required this.elapsedText,
    required this.busy,
    required this.onAccept,
    required this.onReject,
    required this.onStartPreparing,
    required this.onMarkReady,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface(context),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('#${order.orderCode}', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5, color: AppTheme.textPrimary(context))),
                Text(elapsedText, style: TextStyle(fontSize: 12, color: AppTheme.textSecondary(context), fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 6),
            Text('${order.itemCount} item${order.itemCount == 1 ? '' : 's'} · ₹${order.total.toStringAsFixed(0)}',
                style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 13)),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.timer_outlined, size: 14, color: AppTheme.textSecondary(context)),
                const SizedBox(width: 4),
                Text('Prep time: ${order.estimatedDeliveryMin} min', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary(context))),
              ],
            ),
            const SizedBox(height: 14),
            if (board == _Board.newOrders)
              Row(
                children: [
                  Expanded(child: SecondaryButton(label: 'Reject', color: Colors.red, onPressed: busy ? null : onReject)),
                  const SizedBox(width: 10),
                  Expanded(flex: 2, child: PrimaryButton(label: 'Accept', loading: busy, onPressed: onAccept)),
                ],
              )
            else if (board == _Board.preparing)
              PrimaryButton(
                label: order.kitchenStatus == 'preparing' ? 'Mark Ready' : 'Start Preparing',
                color: order.kitchenStatus == 'preparing' ? Colors.green : Colors.orange,
                loading: busy,
                onPressed: order.kitchenStatus == 'preparing' ? onMarkReady : onStartPreparing,
              )
            else if (board == _Board.ready)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_rounded, size: 16, color: Colors.green.shade700),
                    const SizedBox(width: 6),
                    Text('Ready — waiting for pickup', style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w700, fontSize: 12.5)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
