import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/menu_item.dart';
import '../../models/category.dart';
import '../../services/menu_service.dart';
import '../../services/api_client.dart';
import '../../theme.dart';
import '../../widgets/common/buttons.dart';

/// Add/Edit Food form. Fields are limited to what the backend's
/// menu_items table actually supports (name, description, price,
/// category, veg/non-veg, availability, image) — the spec's
/// discount/GST/prep-time fields don't have backing columns yet, so
/// they're left out rather than added as UI that silently saves
/// nowhere (see MenuItemModel::$allowedFields).
class MenuItemFormScreen extends StatefulWidget {
  final MenuItem? item;
  const MenuItemFormScreen({super.key, this.item});

  @override
  State<MenuItemFormScreen> createState() => _MenuItemFormScreenState();
}

class _MenuItemFormScreenState extends State<MenuItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.item?.name ?? '');
  late final _description = TextEditingController(text: widget.item?.description ?? '');
  late final _price = TextEditingController(text: widget.item?.price.toStringAsFixed(0) ?? '');
  late bool _isVeg = widget.item?.isVeg ?? true;
  late bool _isAvailable = widget.item?.isAvailable ?? true;
  int? _subCategoryId;
  File? _pickedImage;
  bool _saving = false;
  bool get _isEdit => widget.item != null;

  Future<CategoryData>? _categoriesFuture;

  @override
  void initState() {
    super.initState();
    _subCategoryId = widget.item?.subCategoryId;
    _categoriesFuture = MenuService.categories();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) setState(() => _pickedImage = File(picked.path));
  }

  Future<void> _addSubCategory(List<Category> categories) async {
    if (categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No categories available yet.')));
      return;
    }
    int selectedCategoryId = categories.first.id;
    final nameController = TextEditingController();

    final created = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('New menu section'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                initialValue: selectedCategoryId,
                items: categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                onChanged: (v) => setDialogState(() => selectedCategoryId = v!),
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              const SizedBox(height: 12),
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Section name (e.g. Starters)')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Add')),
          ],
        ),
      ),
    );

    if (created == true && nameController.text.trim().isNotEmpty) {
      try {
        final sub = await MenuService.addSubCategory(categoryId: selectedCategoryId, name: nameController.text.trim());
        setState(() {
          _categoriesFuture = MenuService.categories();
          _subCategoryId = sub.id;
        });
      } on ApiException catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      if (_isEdit) {
        await MenuService.update(
          widget.item!.id,
          name: _name.text.trim(),
          description: _description.text.trim(),
          price: double.parse(_price.text.trim()),
          subCategoryId: _subCategoryId,
          isVeg: _isVeg,
          isAvailable: _isAvailable,
          image: _pickedImage,
        );
      } else {
        await MenuService.add(
          name: _name.text.trim(),
          description: _description.text.trim(),
          price: double.parse(_price.text.trim()),
          subCategoryId: _subCategoryId,
          isVeg: _isVeg,
          isAvailable: _isAvailable,
          image: _pickedImage,
        );
      }
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg(context),
      appBar: AppBar(title: Text(_isEdit ? 'Edit Item' : 'Add Menu Item')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: _pickedImage != null
                          ? Image.file(_pickedImage!, width: 130, height: 130, fit: BoxFit.cover)
                          : widget.item?.image != null
                              ? Image.network(widget.item!.image!, width: 130, height: 130, fit: BoxFit.cover)
                              : Container(
                                  width: 130,
                                  height: 130,
                                  decoration: BoxDecoration(color: AppTheme.surface(context), borderRadius: BorderRadius.circular(18)),
                                  child: Icon(Icons.add_a_photo_outlined, color: AppTheme.textSecondary(context), size: 30),
                                ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
                        child: const Icon(Icons.edit, size: 15, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _sectionLabel('Food Name'),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(hintText: 'e.g. Chicken Biryani'),
              validator: (v) => (v == null || v.trim().length < 2) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            _sectionLabel('Description'),
            TextFormField(
              controller: _description,
              maxLines: 2,
              decoration: const InputDecoration(hintText: 'Optional — ingredients, spice level, etc.'),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionLabel('Price'),
                      TextFormField(
                        controller: _price,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(prefixText: '₹ '),
                        validator: (v) => (double.tryParse(v?.trim() ?? '') == null) ? 'Invalid' : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _sectionLabel('Category'),
            FutureBuilder<CategoryData>(
              future: _categoriesFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();
                final data = snapshot.data!;
                return Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: data.subCategories.any((s) => s.id == _subCategoryId) ? _subCategoryId : null,
                        decoration: const InputDecoration(hintText: 'Select category'),
                        items: data.subCategories.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                        onChanged: (v) => setState(() => _subCategoryId = v),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: AppTheme.primary),
                      onPressed: () => _addSubCategory(data.categories),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            _sectionLabel('Veg / Non-Veg'),
            Row(
              children: [
                Expanded(
                  child: _vegToggleOption(context, label: 'Veg', color: Colors.green, selected: _isVeg, onTap: () => setState(() => _isVeg = true)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _vegToggleOption(context, label: 'Non-Veg', color: Colors.red, selected: !_isVeg, onTap: () => setState(() => _isVeg = false)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(color: AppTheme.surface(context), borderRadius: BorderRadius.circular(14)),
              child: SwitchListTile(
                value: _isAvailable,
                onChanged: (v) => setState(() => _isAvailable = v),
                title: const Text('Available for orders', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                activeColor: AppTheme.primary,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(child: SecondaryButton(label: 'Cancel', onPressed: () => Navigator.of(context).pop())),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: PrimaryButton(label: 'Save Item', loading: _saving, onPressed: _save),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _vegToggleOption(BuildContext context, {required String label, required Color color, required bool selected, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.12) : AppTheme.surface(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? color : AppTheme.borderColor(context)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 14,
              height: 14,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(border: Border.all(color: color), borderRadius: BorderRadius.circular(3)),
              child: DecoratedBox(decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            ),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: selected ? color : AppTheme.textPrimary(context))),
          ],
        ),
      ),
    );
  }
}
