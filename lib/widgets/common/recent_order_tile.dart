import 'package:flutter/material.dart';
import '../../models/order.dart';
import '../../theme.dart';
import 'status_badge.dart';

/// Row used in Home's "Recent Activity" list: order id, customer, amount,
/// status pill, and time — more compact than the full [OrderCard] used on
/// the Orders tab itself.
class RecentOrderTile extends StatelessWidget {
  final Order order;
  final VoidCallback onTap;

  const RecentOrderTile({super.key, required this.order, required this.onTap});

  String _time(String? raw) {
    if (raw == null) return '';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return '';
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m ${dt.hour >= 12 ? 'PM' : 'AM'}';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('#${order.orderCode}',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: AppTheme.textPrimary(context))),
                  const SizedBox(height: 2),
                  Text(order.customerName ?? '—',
                      style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondary(context))),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('₹${order.total.toStringAsFixed(0)}',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: AppTheme.textPrimary(context))),
                const SizedBox(height: 4),
                Text(_time(order.placedAt), style: TextStyle(fontSize: 11, color: AppTheme.textSecondary(context))),
              ],
            ),
            const SizedBox(width: 10),
            StatusBadge(status: order.orderStatus),
          ],
        ),
      ),
    );
  }
}
