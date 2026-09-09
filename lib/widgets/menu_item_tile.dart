import 'package:flutter/material.dart';
import '../models/menu_item.dart';
import '../theme.dart';

class MenuItemTile extends StatelessWidget {
  final MenuItem item;
  final ValueChanged<bool> onAvailabilityChanged;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const MenuItemTile({
    super.key,
    required this.item,
    required this.onAvailabilityChanged,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: item.image != null
                  ? Image.network(item.image!, width: 56, height: 56, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder())
                  : _placeholder(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.circle, size: 10, color: item.isVeg ? Colors.green : Colors.red),
                    const SizedBox(width: 6),
                    Expanded(child: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                  ]),
                  const SizedBox(height: 4),
                  Text('₹${item.price.toStringAsFixed(0)}', style: TextStyle(color: AppTheme.textSecondary(context))),
                ],
              ),
            ),
            Column(
              children: [
                Switch(value: item.isAvailable, onChanged: onAvailabilityChanged, activeColor: AppTheme.primary),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.edit_outlined, size: 20), onPressed: onEdit),
                    IconButton(icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red), onPressed: onDelete),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        width: 56,
        height: 56,
        color: Colors.grey.shade200,
        child: const Icon(Icons.fastfood_outlined, color: Colors.grey),
      );
}
