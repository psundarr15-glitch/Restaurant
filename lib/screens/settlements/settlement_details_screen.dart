import 'package:flutter/material.dart';
import '../../models/settlement.dart';
import '../../models/wallet.dart';
import '../../services/finance_service.dart';
import '../../services/api_client.dart';
import '../../theme.dart';
import '../../widgets/common/states.dart';

class SettlementDetailsScreen extends StatefulWidget {
  final int settlementId;
  const SettlementDetailsScreen({super.key, required this.settlementId});

  @override
  State<SettlementDetailsScreen> createState() => _SettlementDetailsScreenState();
}

class _SettlementDetailsScreenState extends State<SettlementDetailsScreen> {
  Future<({Settlement settlement, List<WalletTransaction> transactions})>? _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => setState(() => _future = FinanceService.settlementDetails(widget.settlementId));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg(context),
      appBar: AppBar(title: const Text('Settlement Details')),
      body: FutureBuilder(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData && !snapshot.hasError) return const LoadingState();
          if (snapshot.hasError) return ErrorState(message: snapshot.error is ApiException ? (snapshot.error as ApiException).message : '${snapshot.error}', onRetry: _load);

          final settlement = snapshot.data!.settlement;
          final transactions = snapshot.data!.transactions;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('#${settlement.settlementCode}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 6),
                    Text('₹${settlement.amount.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text('${settlement.periodStart} to ${settlement.periodEnd}', style: const TextStyle(color: Colors.white70, fontSize: 12.5)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _sectionCard(context, title: 'Settlement Information', children: [
                _row(context, 'Status', settlement.status[0].toUpperCase() + settlement.status.substring(1)),
                _row(context, 'Orders', '${settlement.orderCount}'),
                if (settlement.settlementDate != null) _row(context, 'Settlement Date', settlement.settlementDate),
              ]),
              const SizedBox(height: 14),
              if (settlement.bankAccountNumber != null)
                _sectionCard(context, title: 'Bank Account', children: [
                  _row(context, 'Account Holder', settlement.bankAccountHolder ?? '—'),
                  _row(context, 'Account Number', _maskAccount(settlement.bankAccountNumber)),
                  _row(context, 'IFSC', settlement.bankIfsc ?? '—'),
                ]),
              const SizedBox(height: 14),
              _sectionCard(context, title: 'Included Transactions (${transactions.length})', children: [
                if (transactions.isEmpty)
                  Text('No linked transactions.', style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 13))
                else
                  for (final t in transactions)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(t.description ?? t.type, style: const TextStyle(fontSize: 13))),
                          Text('₹${t.amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
              ]),
            ],
          );
        },
      ),
    );
  }

  String _maskAccount(String number) => number.length > 4 ? '•••• ${number.substring(number.length - 4)}' : number;

  Widget _sectionCard(BuildContext context, {required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.surface(context), borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppTheme.textPrimary(context))),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 13)),
          Text(value, style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary(context))),
        ],
      ),
    );
  }
}
