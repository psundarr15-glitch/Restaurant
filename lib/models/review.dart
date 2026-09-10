class Review {
  final int id;
  final String customerName;
  final int rating;
  final String? comment;
  final String? reply;
  final String? repliedAt;
  final String? orderCode;
  final List<String> items;
  final String? createdAt;

  Review({
    required this.id,
    required this.customerName,
    required this.rating,
    this.comment,
    this.reply,
    this.repliedAt,
    this.orderCode,
    required this.items,
    this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> j) => Review(
        id: int.tryParse(j['id']?.toString() ?? '') ?? 0,
        customerName: j['customer_name']?.toString() ?? 'Customer',
        rating: int.tryParse(j['rating']?.toString() ?? '') ?? 0,
        comment: j['comment']?.toString(),
        reply: j['reply']?.toString(),
        repliedAt: j['replied_at']?.toString(),
        orderCode: j['order_code']?.toString(),
        items: (j['items'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
        createdAt: j['created_at']?.toString(),
      );
}
