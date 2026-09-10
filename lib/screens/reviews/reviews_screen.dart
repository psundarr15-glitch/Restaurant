import 'package:flutter/material.dart';
import '../../models/review.dart';
import '../../services/review_service.dart';
import '../../services/api_client.dart';
import '../../theme.dart';
import '../../widgets/common/states.dart';
import '../../widgets/common/buttons.dart';

class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({super.key});
  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  Future<({double overallRating, int totalReviews, Map<String, int> breakdown, List<Review> reviews})>? _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => setState(() => _future = ReviewService.list());

  Future<void> _openReplySheet(Review review) async {
    final controller = TextEditingController(text: review.reply ?? '');
    final reply = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: AppTheme.scaffoldBg(context), borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(review.reply == null ? 'Reply to review' : 'Edit reply', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                maxLines: 4,
                maxLength: 500,
                decoration: const InputDecoration(hintText: 'Thank the customer or address their feedback...'),
              ),
              const SizedBox(height: 8),
              PrimaryButton(label: 'Send Reply', onPressed: () => Navigator.pop(context, controller.text.trim())),
            ],
          ),
        ),
      ),
    );

    if (reply == null || reply.isEmpty) return;
    try {
      await ReviewService.reply(review.id, reply);
      _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg(context),
      appBar: AppBar(title: const Text('Reviews & Ratings')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _load(),
          color: AppTheme.primary,
          child: FutureBuilder(
            future: _future,
            builder: (context, snapshot) {
              if (!snapshot.hasData && !snapshot.hasError) return const LoadingState();
              if (snapshot.hasError) {
                return ListView(children: [
                  const SizedBox(height: 60),
                  ErrorState(message: snapshot.error is ApiException ? (snapshot.error as ApiException).message : '${snapshot.error}', onRetry: _load),
                ]);
              }
              final data = snapshot.data!;

              if (data.totalReviews == 0) {
                return ListView(children: const [
                  SizedBox(height: 60),
                  EmptyState(icon: Icons.star_border_rounded, title: 'No reviews yet', subtitle: 'Customer reviews will appear here after delivered orders.'),
                ]);
              }

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: AppTheme.surface(context), borderRadius: BorderRadius.circular(18)),
                    child: Column(
                      children: [
                        Text(data.overallRating.toStringAsFixed(1), style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (i) => Icon(
                                i < data.overallRating.round() ? Icons.star_rounded : Icons.star_border_rounded,
                                color: AppTheme.gold, size: 20,
                              )),
                        ),
                        const SizedBox(height: 4),
                        Text('${data.totalReviews} reviews', style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 12.5)),
                        const SizedBox(height: 16),
                        for (int star = 5; star >= 1; star--) _ratingBar(context, star, data.breakdown['$star'] ?? 0, data.totalReviews),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Recent Reviews', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: AppTheme.textPrimary(context))),
                  const SizedBox(height: 10),
                  for (final review in data.reviews) _reviewCard(context, review),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _ratingBar(BuildContext context, int star, int count, int total) {
    final fraction = total > 0 ? count / total : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text('$star', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(width: 4),
          const Icon(Icons.star_rounded, size: 13, color: AppTheme.gold),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(value: fraction, minHeight: 8, backgroundColor: AppTheme.borderColor(context), color: AppTheme.gold),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(width: 24, child: Text('$count', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary(context)))),
        ],
      ),
    );
  }

  Widget _reviewCard(BuildContext context, Review review) {
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
              Row(children: [
                Text(review.customerName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                const SizedBox(width: 8),
                Row(children: List.generate(5, (i) => Icon(i < review.rating ? Icons.star_rounded : Icons.star_border_rounded, size: 14, color: AppTheme.gold))),
              ]),
              if (review.createdAt != null) Text(review.createdAt!.split(' ').first, style: TextStyle(fontSize: 11, color: AppTheme.textSecondary(context))),
            ],
          ),
          if (review.orderCode != null || review.items.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              [if (review.orderCode != null) '#${review.orderCode}', if (review.items.isNotEmpty) review.items.join(', ')].join(' · '),
              style: TextStyle(fontSize: 11.5, color: AppTheme.textSecondary(context)),
            ),
          ],
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(review.comment!, style: const TextStyle(fontSize: 13.5)),
          ],
          if (review.reply != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.06), borderRadius: BorderRadius.circular(10)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.reply_rounded, size: 14, color: AppTheme.primary),
                  const SizedBox(width: 8),
                  Expanded(child: Text(review.reply!, style: const TextStyle(fontSize: 12.5))),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _openReplySheet(review),
              icon: Icon(review.reply == null ? Icons.reply_rounded : Icons.edit_outlined, size: 16),
              label: Text(review.reply == null ? 'Reply' : 'Edit Reply'),
            ),
          ),
        ],
      ),
    );
  }
}
