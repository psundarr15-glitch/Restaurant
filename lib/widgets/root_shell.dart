import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/orders/orders_screen.dart';
import '../screens/menu/menu_screen.dart';
import '../screens/earnings/earnings_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/chat/chats_screen.dart';

class RootShell extends StatefulWidget {
  final int initialIndex;

  const RootShell({super.key, this.initialIndex = 0});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  late int _index = widget.initialIndex;

  static const _tabs = [
    DashboardScreen(),
    OrdersScreen(),
    MenuScreen(),
    EarningsScreen(),
    ProfileScreen(),
    ChatsScreen(),
  ];

  static const _items = [
    (Icons.home_rounded, Icons.home_outlined, 'Home'),
    (Icons.receipt_long_rounded, Icons.receipt_long_outlined, 'Orders'),
    (Icons.restaurant_menu_rounded, Icons.restaurant_menu_outlined, 'Menu'),
    (Icons.account_balance_wallet_rounded, Icons.account_balance_wallet_outlined, 'Earnings'),
    (Icons.storefront_rounded, Icons.storefront_outlined, 'Profile'),
    (Icons.chat_bubble_rounded, Icons.chat_bubble_outline_rounded, 'Chats'),
  ];

  @override
  Widget build(BuildContext context) {
    final pending = context.watch<AppState>().pendingOrderCount;

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: _tabs,
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: AppTheme.surface(context),
          boxShadow: const [
            BoxShadow(
              color: Color(0x16000000),
              blurRadius: 20,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 78,
            child: Row(
              children: List.generate(_items.length, (i) {
                final selected = i == _index;
                final item = _items[i];

                return Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _index = i),
                    borderRadius: BorderRadius.circular(18),
                    child: Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 60,
                        height: 58,
                        decoration: BoxDecoration(
                          color: selected ? AppTheme.softRed : Colors.transparent,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Icon(
                                  selected ? item.$1 : item.$2,
                                  size: 23,
                                  color: selected
                                      ? AppTheme.primary
                                      : AppTheme.textSecondary(context),
                                ),
                                if (i == 1 && pending > 0)
                                  Positioned(
                                    right: -8,
                                    top: -8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primary,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '$pending',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.$3,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: selected
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: selected
                                    ? AppTheme.primary
                                    : AppTheme.textSecondary(context),
                              ),
                            ),
                          ],
                        ),
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
