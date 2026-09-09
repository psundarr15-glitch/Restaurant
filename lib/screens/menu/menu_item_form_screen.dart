import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/menu_item.dart';
import '../../models/category.dart';
import '../../services/menu_service.dart';
import '../../services/api_client.dart';
import '../../theme.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Item' : 'Add Menu Item')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _pickedImage != null
                        ? Image.file(_pickedImage!, width: 120, height: 120, fit: BoxFit.cover)
                        : widget.item?.image != null
                            ? Image.network(widget.item!.image!, width: 120, height: 120, fit: BoxFit.cover)
                            : Container(
                                width: 120,
                                height: 120,
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.add_a_photo_outlined, color: Colors.grey),
                              ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Item name'),
                validator: (v) => (v == null || v.trim().length < 2) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _description,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Description (optional)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _price,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Price (₹)', prefixText: '₹ '),
                validator: (v) => (double.tryParse(v?.trim() ?? '') == null) ? 'Enter a valid price' : null,
              ),
              const SizedBox(height: 12),
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
                          decoration: const InputDecoration(labelText: 'Menu section'),
                          items: data.subCategories.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                          onChanged: (v) => setState(() => _subCategoryId = v),
                        ),
                      ),
                      IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => _addSubCategory(data.categories)),
                    ],
                  );
                },
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                value: _isVeg,
                onChanged: (v) => setState(() => _isVeg = v),
                title: const Text('Vegetarian'),
                activeColor: Colors.green,
                contentPadding: EdgeInsets.zero,
              ),
              SwitchListTile(
                value: _isAvailable,
                onChanged: (v) => setState(() => _isAvailable = v),
                title: const Text('Available'),
                activeColor: AppTheme.primary,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(_isEdit ? 'Save Changes' : 'Add Item'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
