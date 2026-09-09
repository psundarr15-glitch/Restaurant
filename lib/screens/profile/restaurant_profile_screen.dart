import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/restaurant.dart';
import '../../services/restaurant_service.dart';
import '../../services/api_client.dart';
import '../../theme.dart';
import '../../widgets/common/buttons.dart';
import '../../widgets/common/states.dart';

class RestaurantProfileScreen extends StatefulWidget {
  const RestaurantProfileScreen({super.key});
  @override
  State<RestaurantProfileScreen> createState() => _RestaurantProfileScreenState();
}

class _RestaurantProfileScreenState extends State<RestaurantProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  Future<Restaurant>? _future;
  bool _saving = false;
  File? _pickedImage;
  File? _pickedLogo;

  // Controllers are created once the restaurant loads (see _bind()).
  final _name = TextEditingController();
  final _ownerName = TextEditingController();
  final _ownerPhone = TextEditingController();
  final _phone = TextEditingController();
  final _description = TextEditingController();
  final _cuisine = TextEditingController();
  final _costForTwo = TextEditingController();
  final _prepMin = TextEditingController();
  final _prepMax = TextEditingController();
  final _discountLabel = TextEditingController();
  final _address = TextEditingController();
  final _fssaiNumber = TextEditingController();
  final _tinNumber = TextEditingController();
  final _bankAccountNumber = TextEditingController();
  final _bankIfsc = TextEditingController();
  final _bankAccountHolder = TextEditingController();

  TimeOfDay? _openingTime;
  TimeOfDay? _closingTime;
  String _foodType = 'both';
  Restaurant? _restaurant;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final future = RestaurantService.view();
    setState(() => _future = future);
    future.then(_bind);
  }

  void _bind(Restaurant r) {
    _restaurant = r;
    _name.text = r.name;
    _ownerName.text = r.ownerName ?? '';
    _ownerPhone.text = r.ownerPhone ?? '';
    _phone.text = r.phone ?? '';
    _description.text = r.description ?? '';
    _cuisine.text = r.cuisine ?? '';
    _costForTwo.text = r.costForTwo > 0 ? r.costForTwo.toStringAsFixed(0) : '';
    _prepMin.text = '${r.prepTimeMin}';
    _prepMax.text = '${r.prepTimeMax}';
    _discountLabel.text = r.discountLabel ?? '';
    _address.text = r.address ?? '';
    _fssaiNumber.text = r.fssaiNumber ?? '';
    _tinNumber.text = r.tinNumber ?? '';
    _bankAccountNumber.text = r.bankAccountNumber ?? '';
    _bankIfsc.text = r.bankIfsc ?? '';
    _bankAccountHolder.text = r.bankAccountHolder ?? '';
    _foodType = r.foodType;
    _openingTime = _parseTime(r.openingTime);
    _closingTime = _parseTime(r.closingTime);
    setState(() {});
  }

  TimeOfDay? _parseTime(String? value) {
    if (value == null || value.isEmpty) return null;
    final parts = value.split(':');
    if (parts.length < 2) return null;
    return TimeOfDay(hour: int.tryParse(parts[0]) ?? 0, minute: int.tryParse(parts[1]) ?? 0);
  }

  String? _formatTime(TimeOfDay? t) =>
      t == null ? null : '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) setState(() => _pickedImage = File(picked.path));
  }

  Future<void> _pickLogo() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) setState(() => _pickedLogo = File(picked.path));
  }

  Future<void> _pickTime(bool isOpening) async {
    final picked = await showTimePicker(context: context, initialTime: (isOpening ? _openingTime : _closingTime) ?? TimeOfDay.now());
    if (picked != null) setState(() => isOpening ? _openingTime = picked : _closingTime = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await RestaurantService.update({
        'name': _name.text.trim(),
        'owner_name': _ownerName.text.trim(),
        'owner_phone': _ownerPhone.text.trim(),
        'phone': _phone.text.trim(),
        'description': _description.text.trim(),
        'cuisine': _cuisine.text.trim(),
        'food_type': _foodType,
        'cost_for_two': _costForTwo.text.trim(),
        'prep_time_min': _prepMin.text.trim(),
        'prep_time_max': _prepMax.text.trim(),
        'discount_label': _discountLabel.text.trim(),
        'address': _address.text.trim(),
        'opening_time': _formatTime(_openingTime),
        'closing_time': _formatTime(_closingTime),
        'fssai_number': _fssaiNumber.text.trim(),
        'tin_number': _tinNumber.text.trim(),
        'bank_account_number': _bankAccountNumber.text.trim(),
        'bank_ifsc': _bankIfsc.text.trim(),
        'bank_account_holder': _bankAccountHolder.text.trim(),
      }, image: _pickedImage, logo: _pickedLogo);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Restaurant profile updated.')));
        Navigator.of(context).pop();
      }
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg(context),
      appBar: AppBar(title: const Text('Restaurant Profile')),
      body: FutureBuilder<Restaurant>(
        future: _future,
        builder: (context, snapshot) {
          if (_restaurant == null && !snapshot.hasError) {
            return const LoadingState();
          }
          if (snapshot.hasError) return ErrorState(message: '${snapshot.error}', onRetry: _load);

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                // --- Cover image + logo ---
                Stack(
                  alignment: Alignment.bottomLeft,
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: _pickedImage != null
                            ? Image.file(_pickedImage!, width: double.infinity, height: 130, fit: BoxFit.cover)
                            : _restaurant?.image != null
                                ? Image.network(_restaurant!.image!, width: double.infinity, height: 130, fit: BoxFit.cover)
                                : Container(
                                    width: double.infinity,
                                    height: 130,
                                    decoration: BoxDecoration(color: AppTheme.surface(context), borderRadius: BorderRadius.circular(18)),
                                    child: Center(child: Icon(Icons.add_photo_alternate_outlined, color: AppTheme.textSecondary(context), size: 32)),
                                  ),
                      ),
                    ),
                    Positioned(
                      left: 16,
                      bottom: -28,
                      child: GestureDetector(
                        onTap: _pickLogo,
                        child: Container(
                          width: 64,
                          height: 64,
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(color: AppTheme.scaffoldBg(context), shape: BoxShape.circle),
                          child: ClipOval(
                            child: _pickedLogo != null
                                ? Image.file(_pickedLogo!, fit: BoxFit.cover)
                                : _restaurant?.logo != null
                                    ? Image.network(_restaurant!.logo!, fit: BoxFit.cover)
                                    : Container(
                                        color: AppTheme.surface(context),
                                        child: Icon(Icons.storefront, color: AppTheme.textSecondary(context)),
                                      ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                _sectionCard(context, title: 'Basic Info', children: [
                  TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Restaurant name'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
                  const SizedBox(height: 12),
                  TextFormField(controller: _cuisine, decoration: const InputDecoration(labelText: 'Cuisine (e.g. South Indian, Chinese)')),
                  const SizedBox(height: 12),
                  TextFormField(controller: _description, maxLines: 3, decoration: const InputDecoration(labelText: 'Description')),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _foodType,
                    decoration: const InputDecoration(labelText: 'Food type'),
                    items: const [
                      DropdownMenuItem(value: 'veg', child: Text('Pure Veg')),
                      DropdownMenuItem(value: 'non_veg', child: Text('Non-Veg')),
                      DropdownMenuItem(value: 'both', child: Text('Veg & Non-Veg')),
                    ],
                    onChanged: (v) => setState(() => _foodType = v ?? 'both'),
                  ),
                ]),
                const SizedBox(height: 14),
                _sectionCard(context, title: 'Contact', children: [
                  TextFormField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Restaurant phone')),
                  const SizedBox(height: 12),
                  TextFormField(controller: _ownerName, decoration: const InputDecoration(labelText: 'Owner name')),
                  const SizedBox(height: 12),
                  TextFormField(controller: _ownerPhone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Owner phone')),
                  const SizedBox(height: 12),
                  TextFormField(controller: _address, maxLines: 2, decoration: const InputDecoration(labelText: 'Address')),
                ]),
                const SizedBox(height: 14),
                _sectionCard(context, title: 'Opening Hours & Delivery', children: [
                  Row(
                    children: [
                      Expanded(child: _timeField(context, 'Opens at', _openingTime, () => _pickTime(true))),
                      const SizedBox(width: 12),
                      Expanded(child: _timeField(context, 'Closes at', _closingTime, () => _pickTime(false))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: TextFormField(controller: _prepMin, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Prep time min (mins)'))),
                      const SizedBox(width: 12),
                      Expanded(child: TextFormField(controller: _prepMax, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Prep time max (mins)'))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(controller: _costForTwo, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Approx. cost for two (₹)')),
                  const SizedBox(height: 12),
                  TextFormField(controller: _discountLabel, decoration: const InputDecoration(labelText: 'Discount badge (e.g. "20% OFF") — optional')),
                ]),
                const SizedBox(height: 14),
                _sectionCard(context, title: 'Tax / GST Details', children: [
                  TextFormField(controller: _fssaiNumber, decoration: const InputDecoration(labelText: 'FSSAI number')),
                  const SizedBox(height: 12),
                  TextFormField(controller: _tinNumber, decoration: const InputDecoration(labelText: 'GST / TIN number')),
                ]),
                const SizedBox(height: 14),
                _sectionCard(context, title: 'Bank / Payment Settings', children: [
                  TextFormField(controller: _bankAccountHolder, decoration: const InputDecoration(labelText: 'Account holder name')),
                  const SizedBox(height: 12),
                  TextFormField(controller: _bankAccountNumber, decoration: const InputDecoration(labelText: 'Bank account number')),
                  const SizedBox(height: 12),
                  TextFormField(controller: _bankIfsc, decoration: const InputDecoration(labelText: 'IFSC code')),
                ]),
                const SizedBox(height: 24),
                PrimaryButton(label: 'Save Changes', loading: _saving, onPressed: _save),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _sectionCard(BuildContext context, {required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.surface(context), borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppTheme.textPrimary(context))),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _timeField(BuildContext context, String label, TimeOfDay? value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Text(value != null ? value.format(context) : 'Not set'),
      ),
    );
  }
}
