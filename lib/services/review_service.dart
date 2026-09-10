import '../config/api_config.dart';
import '../models/review.dart';
import 'api_client.dart';

class ReviewService {
  static Future<({double overallRating, int totalReviews, Map<String, int> breakdown, List<Review> reviews})> list() async {
    final res = await ApiClient.get(ApiConfig.reviews);
    final breakdownRaw = res['breakdown'] as Map<String, dynamic>? ?? {};
    return (
      overallRating: double.tryParse(res['overall_rating']?.toString() ?? '') ?? 0,
      totalReviews: int.tryParse(res['total_reviews']?.toString() ?? '') ?? 0,
      breakdown: breakdownRaw.map((k, v) => MapEntry(k, int.tryParse(v.toString()) ?? 0)),
      reviews: (res['reviews'] as List<dynamic>? ?? []).map((e) => Review.fromJson(e)).toList(),
    );
  }

  static Future<void> reply(int reviewId, String reply) =>
      ApiClient.post(ApiConfig.replyToReview(reviewId), {'reply': reply});
}
