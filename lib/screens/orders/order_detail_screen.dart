import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/order.dart';
import '../../services/order_service.dart';
import '../../services/api_client.dart';
import '../../theme.dart';
import '../../widgets/common/status_badge.dart';
import '../../widgets/common/buttons.dart';
import '../../widgets/common/states.dart';

/// Order Details — and, when the order is still 'placed', doubles as the
/// spec's "New Order" screen (banner + prep-time selector + dominant
/// Accept). There's no separate route for that: a pending order and an
/// in-progress one show the same underlying data, just different action
/// affordances, so one screen keeps the accept/reject logic in one place
/// instead of duplicating the API calls across two screens.
class OrderDetailScreen extends StatefulWidget {
  final int orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  Future<OrderDetails>? _future;
  bool _acting = false;
  int _prepTimeMin = 20;

  static const _prepOptions = [10, 15, 20, 30, 45];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() => _future = OrderService.details(widget.orderId));
  }

  Future<void> _accept() async {
    setState(() => _acting = true);
    try {
      await OrderService.accept(widget.orderId, prepTimeMin: _prepTimeMin);
      _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _reject() async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Reject this order?'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Reason (optional) — e.g. item out of stock'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Reject', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
    if (reason == null) return;

    setState(() => _acting = true);
    try {
      await OrderService.reject(widget.orderId, reason: reason.isEmpty ? null : reason);
      _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _markFoodReady() async {
    setState(() => _acting = true);
    try {
      await OrderService.updateKitchenStatus(widget.orderId, 'ready');
      _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _call(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  String _formatDateTime(String? raw) {
    if (raw == null) return '';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day}/${dt.month}/${dt.year} · $h:$m ${dt.hour >= 12 ? 'PM' : 'AM'}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg(context),
      appBar: AppBar(title: const Text('Order Details')),
      body: FutureBuilder<OrderDetails>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData && !snapshot.hasError) {
            return const LoadingState();
          }
          if (snapshot.hasError) {
            return ErrorState(message: '${snapshot.error}', onRetry: _load);
          }
          final details = snapshot.data!;
          final order = details.order;
          final isPending = order.orderStatus == 'placed';

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              if (isPending) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(14)),
                  child: const Text('NEW ORDER',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 1, fontSize: 13)),
                ),
                const SizedBox(height: 14),
              ],

              // --- Order information ---
              _sectionCard(context, title: 'Order Information', children: [
                _row(context, 'Order ID', '#${order.orderCode}'),
                _row(context, 'Placed at', _formatDateTime(order.placedAt)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Status', style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 13)),
                    StatusBadge(status: order.orderStatus),
                  ],
                ),
              ]),
              const SizedBox(height: 14),

              // --- Customer information ---
              _sectionCard(context, title: 'Customer Information', children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(order.customerName ?? 'Customer',
                              style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary(context))),
                          if (order.customerPhone != null) ...[
                            const SizedBox(height: 2),
                            Text(order.customerPhone!, style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 13)),
                          ],
                        ],
                      ),
                    ),
                    if (order.customerPhone != null)
                      Container(
                        decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), shape: BoxShape.circle),
                        child: IconButton(
                          icon: const Icon(Icons.call_rounded, color: AppTheme.primary),
                          onPressed: () => _call(order.customerPhone!),
                        ),
                      ),
                  ],
                ),
              ]),
              const SizedBox(height: 14),

              // --- Items ---
              _sectionCard(context, title: 'Items (${details.items.length})', children: [
                for (final it in details.items)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(children: [
                            Container(
                              width: 14,
                              height: 14,
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                border: Border.all(color: it.isVeg ? Colors.green : Colors.red),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: DecoratedBox(
                                decoration: BoxDecoration(color: it.isVeg ? Colors.green : Colors.red, shape: BoxShape.circle),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text('${it.itemName}  ×${it.quantity}',
                                  style: TextStyle(color: AppTheme.textPrimary(context), fontSize: 13.5)),
                            ),
                          ]),
                        ),
                        Text('₹${(it.price * it.quantity).toStringAsFixed(0)}',
                            style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary(context))),
                      ],
                    ),
                  ),
              ]),
              const SizedBox(height: 14),

              // --- Price breakdown ---
              _sectionCard(context, title: 'Price Breakdown', children: [
                _billRow(context, 'Subtotal', order.subtotal),
                if (order.discount > 0) _billRow(context, 'Discount', -order.discount),
                _billRow(context, 'Delivery Fee', order.deliveryFee),
                const Divider(height: 18),
                _billRow(context, 'Total', order.total, bold: true),
              ]),
              const SizedBox(height: 14),

              // --- Payment ---
              _sectionCard(context, title: 'Payment', children: [
                _row(context, 'Method', order.paymentMethod.toUpperCase()),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Status', style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 13)),
                    Text(
                      order.paymentStatus[0].toUpperCase() + order.paymentStatus.substring(1),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: order.paymentStatus == 'paid' ? Colors.green.shade700 : Colors.orange.shade800,
                      ),
                    ),
                  ],
                ),
              ]),
              const SizedBox(height: 14),

              // --- Order timeline ---
              _sectionCard(context, title: 'Order Timeline', children: [
                _timeline(context, order.orderStatus, details.history),
              ]),

              if (isPending) ...[
                const SizedBox(height: 20),
                Text('Preparation Time',
                    style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppTheme.textPrimary(context))),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _prepOptions.map((min) {
                    final selected = min == _prepTimeMin;
                    return ChoiceChip(
                      label: Text('$min min'),
                      selected: selected,
                      onSelected: (_) => setState(() => _prepTimeMin = min),
                      selectedColor: AppTheme.primary,
                      labelStyle: TextStyle(color: selected ? Colors.white : AppTheme.textPrimary(context), fontWeight: FontWeight.w600),
                      backgroundColor: AppTheme.surface(context),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20), side: BorderSide(color: AppTheme.borderColor(context))),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: SecondaryButton(label: 'REJECT ORDER', color: Colors.red, onPressed: _acting ? null : _reject)),
                    const SizedBox(width: 12),
                    Expanded(flex: 2, child: PrimaryButton(label: 'ACCEPT ORDER', loading: _acting, onPressed: _accept)),
                  ],
                ),
              ],

              // Shown once the order's accepted and still in progress —
              // one tap marks it ready and pings the assigned delivery
              // partner immediately (see OrderService.updateKitchenStatus /
              // ManagerApiController::notifyDeliveryPartnerFoodReady).
              if (!isPending && !['delivered', 'cancelled'].contains(order.orderStatus)) ...[
                const SizedBox(height: 20),
                if (order.kitchenStatus == 'ready')
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_rounded, color: Colors.green.shade700, size: 18),
                        const SizedBox(width: 8),
                        Text('Food ready — delivery partner notified',
                            style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w700, fontSize: 13)),
                      ],
                    ),
                  )
                else
                  PrimaryButton(label: 'FOOD READY', color: Colors.green, loading: _acting, onPressed: _markFoodReady),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _sectionCard(BuildContext context, {required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.surface(context), borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppTheme.textPrimary(context))),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 13)),
          Flexible(
              child: Text(value,
                  textAlign: TextAlign.end,
                  style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary(context)))),
        ],
      ),
    );
  }

  Widget _billRow(BuildContext context, String label, double value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontWeight: bold ? FontWeight.w800 : FontWeight.normal,
                  color: AppTheme.textPrimary(context),
                  fontSize: bold ? 15 : 13.5)),
          Text('₹${value.toStringAsFixed(0)}',
              style: TextStyle(
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                  color: AppTheme.textPrimary(context),
                  fontSize: bold ? 15 : 13.5)),
        ],
      ),
    );
  }

  Widget _timeline(BuildContext context, String currentStatus, List<TrackingEntry> history) {
    final reached = <String>{for (final h in history) h.status, currentStatus};
    final currentIdx = kOrderStatusFlow.indexOf(currentStatus);
    final isCancelled = currentStatus == 'cancelled';

    if (isCancelled) {
      return Row(children: [
        const Icon(Icons.cancel_rounded, color: Colors.red, size: 20),
        const SizedBox(width: 8),
        Text('Order cancelled', style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w700)),
      ]);
    }

    const labels = {
      'placed': 'Order Received',
      'confirmed': 'Accepted',
      'preparing': 'Preparing',
      'out_for_delivery': 'Picked Up',
      'delivered': 'Completed',
    };

    return Column(
      children: [
        for (int i = 0; i < kOrderStatusFlow.length; i++)
          Builder(builder: (context) {
            final status = kOrderStatusFlow[i];
            final done = reached.contains(status) || (currentIdx >= 0 && i <= currentIdx);
            final isLast = i == kOrderStatusFlow.length - 1;
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Icon(done ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                          size: 18, color: done ? Colors.green.shade600 : AppTheme.borderColor(context)),
                      if (!isLast) Expanded(child: Container(width: 2, color: done ? Colors.green.shade200 : AppTheme.borderColor(context))),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Text(labels[status] ?? status,
                        style: TextStyle(
                            fontWeight: done ? FontWeight.w700 : FontWeight.w500,
                            color: done ? AppTheme.textPrimary(context) : AppTheme.textSecondary(context),
                            fontSize: 13.5)),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}
