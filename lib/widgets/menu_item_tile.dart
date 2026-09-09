import 'package:flutter/material.dart';
import '../models/menu_item.dart';
import '../theme.dart';

/// Food item card for the Menu screen — image, name, category, price,
/// veg/non-veg indicator, availability toggle, edit.
class MenuItemTile extends StatelessWidget {
  final MenuItem item;
  final String? categoryName;
  final ValueChanged<bool> onAvailabilityChanged;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const MenuItemTile({
    super.key,
    required this.item,
    this.categoryName,
    required this.onAvailabilityChanged,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: item.image != null
                    ? Image.network(item.image!, width: 64, height: 64, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder())
                    : _placeholder(),
              ),
              if (!item.isAvailable)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.45), borderRadius: BorderRadius.circular(12)),
                    child: const Center(
                      child: Text('OUT', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    width: 13,
                    height: 13,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(border: Border.all(color: item.isVeg ? Colors.green : Colors.red), borderRadius: BorderRadius.circular(3)),
                    child: DecoratedBox(decoration: BoxDecoration(color: item.isVeg ? Colors.green : Colors.red, shape: BoxShape.circle)),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(item.name,
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textPrimary(context)),
                        overflow: TextOverflow.ellipsis),
                  ),
                ]),
                if (categoryName != null) ...[
                  const SizedBox(height: 2),
                  Text(categoryName!, style: TextStyle(fontSize: 11.5, color: AppTheme.textSecondary(context))),
                ],
                const SizedBox(height: 4),
                Text('₹${item.price.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.primary, fontSize: 14.5)),
              ],
            ),
          ),
          Column(
            children: [
              Transform.scale(
                scale: 0.85,
                child: Switch(value: item.isAvailable, onChanged: onAvailabilityChanged, activeColor: AppTheme.primary),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 19),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: onEdit,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 19, color: Colors.red),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: onDelete,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
        width: 64,
        height: 64,
        color: Colors.grey.shade200,
        child: const Icon(Icons.fastfood_outlined, color: Colors.grey),
      );
}
