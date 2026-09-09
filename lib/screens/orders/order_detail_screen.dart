import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/order_service.dart';
import '../../services/api_client.dart';
import '../../theme.dart';
import '../../widgets/order_card.dart';

class OrderDetailScreen extends StatefulWidget {
  final int orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  Future<OrderDetails>? _future;
  bool _acting = false;

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
      await OrderService.accept(widget.orderId);
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

  Future<void> _call(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order Details')),
      body: FutureBuilder<OrderDetails>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData && !snapshot.hasError) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
          }
          if (snapshot.hasError) {
            return Center(child: Text('${snapshot.error}'));
          }
          final details = snapshot.data!;
          final order = details.order;
          final isPending = order.orderStatus == 'placed';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('#${order.orderCode}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor(order.orderStatus).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(statusLabel(order.orderStatus),
                        style: TextStyle(color: statusColor(order.orderStatus), fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(order.customerName ?? 'Customer', style: const TextStyle(fontWeight: FontWeight.w600)),
                              if (order.customerPhone != null) Text(order.customerPhone!),
                            ],
                          ),
                          if (order.customerPhone != null)
                            IconButton(
                              icon: const Icon(Icons.call, color: AppTheme.primary),
                              onPressed: () => _call(order.customerPhone!),
                            ),
                        ],
                      ),
                      const Divider(height: 24),
                      Text('${order.paymentMethod.toUpperCase()} · ${order.paymentStatus}',
                          style: TextStyle(color: AppTheme.textSecondary(context))),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Items', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              ...details.items.map((it) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(children: [
                          Icon(Icons.circle, size: 9, color: it.isVeg ? Colors.green : Colors.red),
                          const SizedBox(width: 6),
                          Text('${it.itemName} x${it.quantity}'),
                        ]),
                        Text('₹${(it.price * it.quantity).toStringAsFixed(0)}'),
                      ],
                    ),
                  )),
              const Divider(height: 24),
              _billRow('Subtotal', order.subtotal),
              if (order.discount > 0) _billRow('Discount', -order.discount),
              _billRow('Delivery Fee', order.deliveryFee),
              _billRow('Total', order.total, bold: true),
              const SizedBox(height: 20),
              if (isPending)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _acting ? null : _reject,
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                        child: const Text('Reject'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _acting ? null : _accept,
                        child: _acting
                            ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Accept'),
                      ),
                    ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _billRow(String label, double value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          Text('₹${value.toStringAsFixed(0)}', style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}
