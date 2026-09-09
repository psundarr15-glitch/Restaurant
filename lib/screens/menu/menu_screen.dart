import 'package:flutter/material.dart';
import '../../models/menu_item.dart';
import '../../services/menu_service.dart';
import '../../services/api_client.dart';
import '../../theme.dart';
import '../../widgets/menu_item_tile.dart';
import '../../widgets/common/search_and_filter.dart';
import '../../widgets/common/states.dart';
import '../../widgets/common/buttons.dart';
import 'menu_item_form_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});
  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  Future<MenuData>? _future;
  String _search = '';
  String _category = 'All';

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() => _future = MenuService.menu());
  }

  Future<void> _toggle(MenuItem item) async {
    try {
      await MenuService.toggleAvailability(item.id);
      _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _delete(MenuItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this item?'),
        content: Text('"${item.name}" will be removed from your menu.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await MenuService.delete(item.id);
      _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  void _add() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MenuItemFormScreen())).then((_) => _load());
  }

  void _edit(MenuItem item) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => MenuItemFormScreen(item: item)))
        .then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg(context),
      appBar: AppBar(title: const Text('Menu')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add),
        label: const Text('Add Food'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _load(),
          color: AppTheme.primary,
          child: FutureBuilder<MenuData>(
            future: _future,
            builder: (context, snapshot) {
              if (!snapshot.hasData && !snapshot.hasError) {
                return const LoadingState();
              }
              if (snapshot.hasError) {
                return ListView(children: [
                  const SizedBox(height: 60),
                  ErrorState(message: '${snapshot.error}', onRetry: _load),
                ]);
              }
              final menu = snapshot.data!;
              if (menu.items.isEmpty) {
                return ListView(children: [
                  const SizedBox(height: 60),
                  EmptyState(
                    icon: Icons.restaurant_menu_outlined,
                    title: 'No menu items yet',
                    subtitle: 'Add your first menu item to start receiving orders.',
                    actionLabel: 'Add Item',
                    onAction: _add,
                  ),
                ]);
              }

              final categories = ['All', ...menu.grouped.keys];
              if (!categories.contains(_category)) _category = 'All';

              // categoryByItemId lets the card show its section name even
              // though the "All" view flattens everything into one list.
              final categoryByItemId = <int, String>{};
              menu.grouped.forEach((cat, items) {
                for (final it in items) {
                  categoryByItemId[it.id] = cat;
                }
              });

              var visible = _category == 'All' ? menu.items : (menu.grouped[_category] ?? []);
              if (_search.trim().isNotEmpty) {
                final q = _search.trim().toLowerCase();
                visible = visible.where((i) => i.name.toLowerCase().contains(q)).toList();
              }

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                children: [
                  AppSearchBar(hint: 'Search menu items', onChanged: (v) => setState(() => _search = v)),
                  const SizedBox(height: 12),
                  FilterChipRow(
                    labels: categories,
                    selectedIndex: categories.indexOf(_category),
                    onSelected: (i) => setState(() => _category = categories[i]),
                  ),
                  const SizedBox(height: 14),
                  if (visible.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: EmptyState(icon: Icons.search_off_rounded, title: 'No items match'),
                    )
                  else
                    ...visible.map((item) => MenuItemTile(
                          item: item,
                          categoryName: _category == 'All' ? categoryByItemId[item.id] : null,
                          onAvailabilityChanged: (_) => _toggle(item),
                          onEdit: () => _edit(item),
                          onDelete: () => _delete(item),
                        )),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
