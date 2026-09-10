class WalletSummary {
  final double availableBalance, pendingBalance, totalEarned, totalSettled;
  WalletSummary({required this.availableBalance, required this.pendingBalance, required this.totalEarned, required this.totalSettled});

  factory WalletSummary.fromJson(Map<String, dynamic> j) => WalletSummary(
        availableBalance: double.tryParse(j['available_balance']?.toString() ?? '') ?? 0,
        pendingBalance: double.tryParse(j['pending_balance']?.toString() ?? '') ?? 0,
        totalEarned: double.tryParse(j['total_earned']?.toString() ?? '') ?? 0,
        totalSettled: double.tryParse(j['total_settled']?.toString() ?? '') ?? 0,
      );
}

class WalletTransaction {
  final int id;
  final String type; // order_earning | commission | refund | settlement | adjustment
  final double amount;
  final String status; // pending | completed | failed | reversed
  final String? description;
  final int? orderId;
  final String? createdAt;

  WalletTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.status,
    this.description,
    this.orderId,
    this.createdAt,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> j) => WalletTransaction(
        id: int.tryParse(j['id']?.toString() ?? '') ?? 0,
        type: j['type']?.toString() ?? '',
        amount: double.tryParse(j['amount']?.toString() ?? '') ?? 0,
        status: j['status']?.toString() ?? 'pending',
        description: j['description']?.toString(),
        orderId: int.tryParse(j['order_id']?.toString() ?? ''),
        createdAt: j['created_at']?.toString(),
      );
}
