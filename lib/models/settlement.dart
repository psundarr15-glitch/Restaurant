class Settlement {
  final int id;
  final String settlementCode;
  final double amount;
  final String periodStart, periodEnd;
  final int orderCount;
  final String? bankAccountNumber, bankIfsc, bankAccountHolder;
  final String status; // pending | processing | paid | failed
  final String? settlementDate;

  Settlement({
    required this.id,
    required this.settlementCode,
    required this.amount,
    required this.periodStart,
    required this.periodEnd,
    required this.orderCount,
    this.bankAccountNumber,
    this.bankIfsc,
    this.bankAccountHolder,
    required this.status,
    this.settlementDate,
  });

  factory Settlement.fromJson(Map<String, dynamic> j) => Settlement(
        id: int.tryParse(j['id']?.toString() ?? '') ?? 0,
        settlementCode: j['settlement_code']?.toString() ?? '',
        amount: double.tryParse(j['amount']?.toString() ?? '') ?? 0,
        periodStart: j['period_start']?.toString() ?? '',
        periodEnd: j['period_end']?.toString() ?? '',
        orderCount: int.tryParse(j['order_count']?.toString() ?? '') ?? 0,
        bankAccountNumber: j['bank_account_number']?.toString(),
        bankIfsc: j['bank_ifsc']?.toString(),
        bankAccountHolder: j['bank_account_holder']?.toString(),
        status: j['status']?.toString() ?? 'pending',
        settlementDate: j['settlement_date']?.toString(),
      );
}
