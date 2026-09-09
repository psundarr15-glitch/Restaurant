import 'package:flutter/material.dart';
import '../models/order.dart';
import '../theme.dart';

Color statusColor(String status) {
  switch (status) {
    case 'placed':
      return Colors.orange.shade700;
    case 'confirmed':
    case 'preparing':
      return Colors.blue.shade700;
    case 'out_for_delivery':
      return Colors.purple.shade700;
    case 'delivered':
      return Colors.green.shade700;
    case 'cancelled':
      return Colors.red.shade700;
    default:
      return Colors.grey.shade700;
  }
}

String statusLabel(String status) {
  switch (status) {
    case 'placed':
      return 'New Order';
    case 'confirmed':
      return 'Confirmed';
    case 'preparing':
      return 'Preparing / Picked up';
    case 'out_for_delivery':
      return 'Out for Delivery';
    case 'delivered':
      return 'Delivered';
    case 'cancelled':
      return 'Cancelled';
    default:
      return status;
  }
}

class OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback onTap;
  const OrderCard({super.key, required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = statusColor(order.orderStatus);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(width: 4, height: 44, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('#${order.orderCode}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(order.customerName ?? '', style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 13)),
                    if (order.itemCount > 0) ...[
                      const SizedBox(height: 2),
                      Text('${order.itemCount} item${order.itemCount == 1 ? '' : 's'}',
                          style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 12)),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('₹${order.total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                    child: Text(statusLabel(order.orderStatus), style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    order.paymentStatus == 'paid' ? 'Paid' : (order.paymentMethod.toUpperCase()),
                    style: TextStyle(
                      fontSize: 10.5,
                      color: order.paymentStatus == 'paid' ? Colors.green.shade700 : AppTheme.textSecondary(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
