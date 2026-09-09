import 'package:flutter/material.dart';
import '../../theme.dart';

/// Home screen greeting header — "☰  Hello, <Restaurant> 👋" plus an
/// open/closed status pill and subtitle.
///
/// The pill is read-only, not a tappable toggle: restaurant managers
/// can't flip the restaurant's is_active switch themselves (that's a
/// deliberate superadmin-only control on the backend — see
/// ManagerApiController::updateRestaurant), so this reflects the
/// current is_active + opening/closing-hours state rather than letting
/// the manager change it here.
class AppHeader extends StatelessWidget {
  final String restaurantName;
  final bool isOpen;
  final VoidCallback onMenuTap;

  const AppHeader({
    super.key,
    required this.restaurantName,
    required this.isOpen,
    required this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onMenuTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppTheme.surface(context), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.menu_rounded, size: 22),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(children: [
                  TextSpan(
                      text: 'Hello, $restaurantName ',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary(context))),
                  const TextSpan(text: '👋'),
                ]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                'Manage your restaurant, orders & earnings',
                style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondary(context)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: (isOpen ? Colors.green : Colors.grey).withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: isOpen ? Colors.green.shade600 : Colors.grey.shade600, shape: BoxShape.circle),
              ),
              const SizedBox(width: 5),
              Text(
                isOpen ? 'Online' : 'Offline',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: isOpen ? Colors.green.shade700 : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
