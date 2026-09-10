import 'package:flutter/material.dart';
import '../../models/offer.dart';
import '../../services/offer_service.dart';
import '../../services/api_client.dart';
import '../../theme.dart';
import '../../widgets/common/search_and_filter.dart';
import '../../widgets/common/states.dart';
import 'add_edit_offer_screen.dart';

class OffersScreen extends StatefulWidget {
  const OffersScreen({super.key});
  @override
  State<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends State<OffersScreen> {
  Future<List<Offer>>? _future;
  int _tab = 0;
  static const _labels = ['Active', 'Scheduled', 'Expired'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => setState(() => _future = OfferService.list());

  List<Offer> _bucket(List<Offer> all, int tab) {
    final today = DateTime.now();
    final todayStr = '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    switch (tab) {
      case 0:
        return all.where((o) => o.endDate.compareTo(todayStr) >= 0 && o.startDate.compareTo(todayStr) <= 0).toList();
      case 1:
        return all.where((o) => o.startDate.compareTo(todayStr) > 0).toList();
      default:
        return all.where((o) => o.endDate.compareTo(todayStr) < 0).toList();
    }
  }

  Future<void> _toggle(Offer offer) async {
    try {
      await OfferService.toggle(offer.id);
      _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _delete(Offer offer) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this offer?'),
        content: Text('"${offer.title}" will be removed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await OfferService.delete(offer.id);
      _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg(context),
      appBar: AppBar(title: const Text('Offers & Promotions')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add),
        label: const Text('New Offer'),
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddEditOfferScreen())).then((_) => _load()),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _load(),
          color: AppTheme.primary,
          child: FutureBuilder<List<Offer>>(
            future: _future,
            builder: (context, snapshot) {
              if (!snapshot.hasData && !snapshot.hasError) return const LoadingState();
              if (snapshot.hasError) {
                return ListView(children: [
                  const SizedBox(height: 60),
                  ErrorState(message: snapshot.error is ApiException ? (snapshot.error as ApiException).message : '${snapshot.error}', onRetry: _load),
                ]);
              }
              final all = snapshot.data!;
              final buckets = List.generate(3, (i) => _bucket(all, i));

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: FilterChipRow(labels: _labels, counts: buckets.map((b) => b.length).toList(), selectedIndex: _tab, onSelected: (i) => setState(() => _tab = i)),
                  ),
                  Expanded(
                    child: buckets[_tab].isEmpty
                        ? ListView(children: [
                            const SizedBox(height: 60),
                            EmptyState(
                              icon: Icons.local_offer_outlined,
                              title: 'No ${_labels[_tab].toLowerCase()} offers',
                              actionLabel: _tab == 0 ? 'Create Offer' : null,
                              onAction: _tab == 0 ? () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddEditOfferScreen())).then((_) => _load()) : null,
                            ),
                          ])
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                            itemCount: buckets[_tab].length,
                            itemBuilder: (context, i) => _offerCard(context, buckets[_tab][i]),
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _offerCard(BuildContext context, Offer offer) {
    final discountText = offer.discountType == 'percentage' ? '${offer.discountValue.toStringAsFixed(0)}% OFF' : '₹${offer.discountValue.toStringAsFixed(0)} OFF';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.surface(context), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(offer.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text(discountText, style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w800, fontSize: 12.5)),
                    ),
                  ],
                ),
              ),
              Switch(value: offer.isActive, activeColor: AppTheme.primary, onChanged: (_) => _toggle(offer)),
            ],
          ),
          if (offer.description != null && offer.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(offer.description!, style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondary(context))),
          ],
          const SizedBox(height: 10),
          Wrap(spacing: 6, runSpacing: 6, children: [
            _pill(context, 'Min order ₹${offer.minOrderValue.toStringAsFixed(0)}'),
            if (offer.maxDiscount != null) _pill(context, 'Max ₹${offer.maxDiscount!.toStringAsFixed(0)}'),
            _pill(context, offer.applicableTo == 'restaurant' ? 'Entire menu' : offer.applicableTo == 'item' ? '${offer.items.length} items' : '${offer.categories.length} categories'),
            if (offer.usageLimit != null) _pill(context, 'Used ${offer.usedCount}/${offer.usageLimit}'),
          ]),
          const SizedBox(height: 8),
          Text('${offer.startDate} to ${offer.endDate}', style: TextStyle(fontSize: 11.5, color: AppTheme.textSecondary(context))),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddEditOfferScreen(offer: offer))).then((_) => _load()),
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Edit'),
              ),
              TextButton.icon(
                onPressed: () => _delete(offer),
                icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                label: const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill(BuildContext context, String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: AppTheme.scaffoldBg(context), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.borderColor(context))),
        child: Text(text, style: TextStyle(fontSize: 10.5, color: AppTheme.textSecondary(context), fontWeight: FontWeight.w600)),
      );
}
