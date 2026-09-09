import 'package:flutter/material.dart';
import '../../models/menu_item.dart';
import '../../services/menu_service.dart';
import '../../services/api_client.dart';
import '../../theme.dart';
import '../../widgets/menu_item_tile.dart';
import 'menu_item_form_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});
  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  Future<MenuData>? _future;

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
      appBar: AppBar(
        title: const Text('Menu'),
        actions: [IconButton(icon: const Icon(Icons.add), onPressed: _add)],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _load(),
        child: FutureBuilder<MenuData>(
          future: _future,
          builder: (context, snapshot) {
            if (!snapshot.hasData && !snapshot.hasError) {
              return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
            }
            if (snapshot.hasError) {
              return ListView(children: [const SizedBox(height: 80), Center(child: Text('${snapshot.error}'))]);
            }
            final menu = snapshot.data!;
            if (menu.items.isEmpty) {
              return ListView(children: [
                const SizedBox(height: 100),
                Center(
                  child: Column(children: [
                    Icon(Icons.restaurant_menu_outlined, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text('No menu items yet.', style: TextStyle(color: AppTheme.textSecondary(context))),
                    const SizedBox(height: 12),
                    ElevatedButton(onPressed: _add, child: const Text('Add your first item')),
                  ]),
                ),
              ]);
            }
            return ListView(
              padding: const EdgeInsets.all(16),
              children: menu.grouped.entries.map((entry) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8, top: 8),
                      child: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    ...entry.value.map((item) => MenuItemTile(
                          item: item,
                          onAvailabilityChanged: (_) => _toggle(item),
                          onEdit: () => _edit(item),
                          onDelete: () => _delete(item),
                        )),
                  ],
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }
}
