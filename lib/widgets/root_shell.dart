import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/orders/orders_screen.dart';
import '../screens/menu/menu_screen.dart';
import '../screens/earnings/earnings_screen.dart';
import '../screens/profile/profile_screen.dart';

/// Bottom nav, per the Phase 5 brief's navigation note: primary nav
/// stays Home/Orders/Menu/Earnings/Profile; Analytics/Wallet/
/// Settlements live inside EarningsScreen as secondary navigation
/// instead of getting their own tabs (see that screen).
class RootShell extends StatefulWidget {
  final int initialIndex;
  const RootShell({super.key, this.initialIndex = 0});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  late int _index = widget.initialIndex;

  static final _tabs = [
    const DashboardScreen(),
    const OrdersScreen(),
    const MenuScreen(),
    const EarningsScreen(),
    const ProfileScreen(),
  ];

  static const _items = [
    (icon: Icons.home_rounded, outline: Icons.home_outlined, label: 'Home'),
    (icon: Icons.receipt_long_rounded, outline: Icons.receipt_long_outlined, label: 'Orders'),
    (icon: Icons.restaurant_menu_rounded, outline: Icons.restaurant_menu_outlined, label: 'Menu'),
    (icon: Icons.account_balance_wallet_rounded, outline: Icons.account_balance_wallet_outlined, label: 'Earnings'),
    (icon: Icons.storefront_rounded, outline: Icons.storefront_outlined, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final pending = context.watch<AppState>().pendingOrderCount;

    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: AppTheme.surface(context),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, -4))],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_items.length, (i) {
                final item = _items[i];
                final selected = i == _index;
                final showBadge = i == 1 && pending > 0;
                return Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _index = i),
                    borderRadius: BorderRadius.circular(16),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? AppTheme.primary.withOpacity(0.10) : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Icon(selected ? item.icon : item.outline,
                                  size: 23, color: selected ? AppTheme.primary : AppTheme.textSecondary(context)),
                              if (showBadge)
                                Positioned(
                                  right: -6,
                                  top: -4,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(10)),
                                    constraints: const BoxConstraints(minWidth: 16),
                                    child: Text('$pending',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                              color: selected ? AppTheme.primary : AppTheme.textSecondary(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
