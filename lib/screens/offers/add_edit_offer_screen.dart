import 'package:flutter/material.dart';
import '../../models/offer.dart';
import '../../models/menu_item.dart';
import '../../services/offer_service.dart';
import '../../services/menu_service.dart';
import '../../services/api_client.dart';
import '../../theme.dart';
import '../../widgets/common/buttons.dart';

class AddEditOfferScreen extends StatefulWidget {
  final Offer? offer;
  const AddEditOfferScreen({super.key, this.offer});

  @override
  State<AddEditOfferScreen> createState() => _AddEditOfferScreenState();
}

class _AddEditOfferScreenState extends State<AddEditOfferScreen> {
  final _formKey = GlobalKey<FormState>();
  bool get _isEdit => widget.offer != null;
  bool _saving = false;

  late final _title = TextEditingController(text: widget.offer?.title ?? '');
  late final _description = TextEditingController(text: widget.offer?.description ?? '');
  late final _discountValue = TextEditingController(text: widget.offer?.discountValue.toStringAsFixed(0) ?? '');
  late final _minOrderValue = TextEditingController(text: widget.offer?.minOrderValue.toStringAsFixed(0) ?? '0');
  late final _maxDiscount = TextEditingController(text: widget.offer?.maxDiscount?.toStringAsFixed(0) ?? '');
  late final _usageLimit = TextEditingController(text: widget.offer?.usageLimit?.toString() ?? '');

  late String _discountType = widget.offer?.discountType ?? 'percentage';
  late String _applicableTo = widget.offer?.applicableTo ?? 'restaurant';
  late bool _isActive = widget.offer?.isActive ?? true;
  DateTime? _startDate;
  DateTime? _endDate;
  final Set<int> _selectedItemIds = {};
  final Set<int> _selectedCategoryIds = {};

  Future<MenuData>? _menuFuture;

  @override
  void initState() {
    super.initState();
    _startDate = widget.offer != null ? DateTime.tryParse(widget.offer!.startDate) : DateTime.now();
    _endDate = widget.offer != null ? DateTime.tryParse(widget.offer!.endDate) : DateTime.now().add(const Duration(days: 7));
    _selectedItemIds.addAll(widget.offer?.items.map((e) => e.id) ?? []);
    _selectedCategoryIds.addAll(widget.offer?.categories.map((e) => e.id) ?? []);
    if (_applicableTo != 'restaurant') {
      _menuFuture = MenuService.menu();
    }
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isStart ? _startDate : _endDate) ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked != null) setState(() => isStart ? _startDate = picked : _endDate = picked);
  }

  String _fmt(DateTime? d) => d == null ? 'Select date' : '${d.day}/${d.month}/${d.year}';

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select start and end dates.')));
      return;
    }
    if (_endDate!.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('End date must be after the start date.')));
      return;
    }
    if (_applicableTo == 'item' && _selectedItemIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select at least one food item.')));
      return;
    }
    if (_applicableTo == 'category' && _selectedCategoryIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select at least one category.')));
      return;
    }

    setState(() => _saving = true);
    try {
      final params = (
        title: _title.text.trim(),
        description: _description.text.trim().isEmpty ? null : _description.text.trim(),
        discountType: _discountType,
        discountValue: double.parse(_discountValue.text.trim()),
        minOrderValue: double.tryParse(_minOrderValue.text.trim()) ?? 0,
        maxDiscount: _maxDiscount.text.trim().isEmpty ? null : double.tryParse(_maxDiscount.text.trim()),
        startDate: _startDate!,
        endDate: _endDate!,
        usageLimit: _usageLimit.text.trim().isEmpty ? null : int.tryParse(_usageLimit.text.trim()),
        applicableTo: _applicableTo,
        isActive: _isActive,
        itemIds: _applicableTo == 'item' ? _selectedItemIds.toList() : null,
        categoryIds: _applicableTo == 'category' ? _selectedCategoryIds.toList() : null,
      );

      if (_isEdit) {
        await OfferService.update(
          widget.offer!.id,
          title: params.title, description: params.description, discountType: params.discountType,
          discountValue: params.discountValue, minOrderValue: params.minOrderValue, maxDiscount: params.maxDiscount,
          startDate: params.startDate, endDate: params.endDate, usageLimit: params.usageLimit,
          applicableTo: params.applicableTo, isActive: params.isActive, itemIds: params.itemIds, categoryIds: params.categoryIds,
        );
      } else {
        await OfferService.add(
          title: params.title, description: params.description, discountType: params.discountType,
          discountValue: params.discountValue, minOrderValue: params.minOrderValue, maxDiscount: params.maxDiscount,
          startDate: params.startDate, endDate: params.endDate, usageLimit: params.usageLimit,
          applicableTo: params.applicableTo, isActive: params.isActive, itemIds: params.itemIds, categoryIds: params.categoryIds,
        );
      }
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _label(String text) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg(context),
      appBar: AppBar(title: Text(_isEdit ? 'Edit Offer' : 'New Offer')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            _label('Offer Name'),
            TextFormField(controller: _title, decoration: const InputDecoration(hintText: 'e.g. Weekend Special'), validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
            const SizedBox(height: 16),
            _label('Description'),
            TextFormField(controller: _description, maxLines: 2, decoration: const InputDecoration(hintText: 'Optional')),
            const SizedBox(height: 16),
            _label('Discount Type'),
            Row(children: [
              Expanded(child: _typeChip('Percentage Discount', 'percentage')),
              const SizedBox(width: 10),
              Expanded(child: _typeChip('Fixed Amount', 'fixed')),
            ]),
            const SizedBox(height: 16),
            _label(_discountType == 'percentage' ? 'Discount Percentage' : 'Discount Amount'),
            TextFormField(
              controller: _discountValue,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(prefixText: _discountType == 'fixed' ? '₹ ' : null, suffixText: _discountType == 'percentage' ? '%' : null),
              validator: (v) {
                final val = double.tryParse(v?.trim() ?? '');
                if (val == null || val <= 0) return 'Enter a valid discount';
                if (_discountType == 'percentage' && val > 100) return 'Cannot exceed 100%';
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _label('Minimum Order Value'),
                  TextFormField(
                    controller: _minOrderValue,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(prefixText: '₹ '),
                    validator: (v) => (double.tryParse(v?.trim() ?? '0') ?? -1) < 0 ? 'Cannot be negative' : null,
                  ),
                ]),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _label('Max Discount (optional)'),
                  TextFormField(controller: _maxDiscount, keyboardType: TextInputType.number, decoration: const InputDecoration(prefixText: '₹ ')),
                ]),
              ),
            ]),
            const SizedBox(height: 16),
            _label('Usage Limit (optional)'),
            TextFormField(
              controller: _usageLimit,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: 'Leave blank for unlimited'),
              validator: (v) => v != null && v.trim().isNotEmpty && (int.tryParse(v.trim()) ?? -1) < 0 ? 'Cannot be negative' : null,
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _label('Start Date'),
                  InkWell(onTap: () => _pickDate(true), child: InputDecorator(decoration: const InputDecoration(), child: Text(_fmt(_startDate)))),
                ]),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _label('End Date'),
                  InkWell(onTap: () => _pickDate(false), child: InputDecorator(decoration: const InputDecoration(), child: Text(_fmt(_endDate)))),
                ]),
              ),
            ]),
            const SizedBox(height: 16),
            _label('Applicable To'),
            DropdownButtonFormField<String>(
              initialValue: _applicableTo,
              items: const [
                DropdownMenuItem(value: 'restaurant', child: Text('Entire Restaurant')),
                DropdownMenuItem(value: 'item', child: Text('Specific Food')),
                DropdownMenuItem(value: 'category', child: Text('Specific Category')),
              ],
              onChanged: (v) {
                setState(() {
                  _applicableTo = v ?? 'restaurant';
                  if (_applicableTo != 'restaurant' && _menuFuture == null) _menuFuture = MenuService.menu();
                });
              },
            ),
            if (_applicableTo != 'restaurant') ...[
              const SizedBox(height: 12),
              FutureBuilder<MenuData>(
                future: _menuFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: LinearProgressIndicator());
                  final menu = snapshot.data!;
                  if (_applicableTo == 'item') {
                    return Wrap(
                      spacing: 8, runSpacing: 8,
                      children: menu.items.map((item) => FilterChip(
                            label: Text(item.name),
                            selected: _selectedItemIds.contains(item.id),
                            onSelected: (sel) => setState(() => sel ? _selectedItemIds.add(item.id) : _selectedItemIds.remove(item.id)),
                            selectedColor: AppTheme.primary.withOpacity(0.15),
                          )).toList(),
                    );
                  }
                  return Wrap(
                    spacing: 8, runSpacing: 8,
                    children: menu.grouped.keys.map((catName) {
                      // Categories here are identified by name for selection
                      // display; the id used for the API call comes from
                      // the first item's subCategoryId in that group.
                      final id = menu.grouped[catName]!.first.subCategoryId;
                      if (id == null) return const SizedBox.shrink();
                      return FilterChip(
                        label: Text(catName),
                        selected: _selectedCategoryIds.contains(id),
                        onSelected: (sel) => setState(() => sel ? _selectedCategoryIds.add(id) : _selectedCategoryIds.remove(id)),
                        selectedColor: AppTheme.primary.withOpacity(0.15),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(color: AppTheme.surface(context), borderRadius: BorderRadius.circular(14)),
              child: SwitchListTile(
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
                title: const Text('Active', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                activeColor: AppTheme.primary,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(height: 28),
            PrimaryButton(label: 'Save Offer', loading: _saving, onPressed: _save),
          ],
        ),
      ),
    );
  }

  Widget _typeChip(String label, String value) {
    final selected = _discountType == value;
    return InkWell(
      onTap: () => setState(() => _discountType = value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary.withOpacity(0.1) : AppTheme.surface(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? AppTheme.primary : AppTheme.borderColor(context)),
        ),
        child: Text(label, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: selected ? AppTheme.primary : AppTheme.textPrimary(context))),
      ),
    );
  }
}
