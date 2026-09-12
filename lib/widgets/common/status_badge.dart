import 'package:flutter/material.dart';
import '../order_card.dart' show statusColor, statusLabel;

/// Small rounded pill for an order/payment status. Uses the same
/// statusColor/statusLabel mapping [OrderCard] already uses, so colors
/// stay consistent between the order list, order details, and kitchen
/// board instead of each screen defining its own palette.
class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.25), width: 1),
      ),
      child: Text(
        statusLabel(status),
        style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.w800, letterSpacing: 0.1),
      ),
    );
  }
}
