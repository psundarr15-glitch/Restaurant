import 'package:flutter/material.dart';
import '../../models/wallet.dart';
import '../../services/finance_service.dart';
import '../../services/api_client.dart';
import '../../theme.dart';
import '../../widgets/common/search_and_filter.dart';
import '../../widgets/common/states.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});
  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  Future<WalletSummary>? _summaryFuture;
  Future<List<WalletTransaction>>? _txFuture;
  String _typeFilter = 'All';

  static const _typeLabels = ['All', 'Order Earnings', 'Commission', 'Refund', 'Settlement', 'Adjustment'];
  static const _typeValues = ['', 'order_earning', 'commission', 'refund', 'settlement', 'adjustment'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _summaryFuture = FinanceService.wallet();
      _txFuture = FinanceService.walletTransactions();
    });
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'order_earning': return 'Order Earning';
      case 'commission': return 'Commission';
      case 'refund': return 'Refund';
      case 'settlement': return 'Settlement';
      case 'adjustment': return 'Adjustment';
      default: return type;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'completed': return Colors.green;
      case 'failed': return Colors.red;
      case 'reversed': return Colors.grey;
      default: return Colors.orange;
    }
  }

  bool _isCredit(String type) => type == 'order_earning';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg(context),
      appBar: AppBar(title: const Text('Wallet')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _load(),
          color: AppTheme.primary,
          child: FutureBuilder<WalletSummary>(
            future: _summaryFuture,
            builder: (context, summarySnap) {
              if (!summarySnap.hasData && !summarySnap.hasError) return const LoadingState();
              if (summarySnap.hasError) {
                return ListView(children: [
                  const SizedBox(height: 60),
                  ErrorState(message: summarySnap.error is ApiException ? (summarySnap.error as ApiException).message : '${summarySnap.error}', onRetry: _load),
                ]);
              }
              final summary = summarySnap.data!;

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
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
                        const Text('Available Balance', style: TextStyle(color: Colors.white70, fontSize: 13)),
                        const SizedBox(height: 6),
                        Text('₹${summary.availableBalance.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text('Pending: ₹${summary.pendingBalance.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white70, fontSize: 12.5)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(color: AppTheme.surface(context), borderRadius: BorderRadius.circular(16)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Total Earned', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary(context))),
                              Text('₹${summary.totalEarned.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(color: AppTheme.surface(context), borderRadius: BorderRadius.circular(16)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Total Settled', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary(context))),
                              Text('₹${summary.totalSettled.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Text('Transactions', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: AppTheme.textPrimary(context))),
                  const SizedBox(height: 10),
                  FilterChipRow(labels: _typeLabels, selectedIndex: _typeLabels.indexOf(_typeFilter), onSelected: (i) => setState(() => _typeFilter = _typeLabels[i])),
                  const SizedBox(height: 12),
                  FutureBuilder<List<WalletTransaction>>(
                    future: _txFuture,
                    builder: (context, txSnap) {
                      if (!txSnap.hasData && !txSnap.hasError) return const Padding(padding: EdgeInsets.only(top: 20), child: LoadingState());
                      if (txSnap.hasError) return ErrorState(message: '${txSnap.error}', onRetry: _load);

                      final selectedValue = _typeValues[_typeLabels.indexOf(_typeFilter)];
                      final txs = selectedValue.isEmpty ? txSnap.data! : txSnap.data!.where((t) => t.type == selectedValue).toList();

                      if (txs.isEmpty) {
                        return const Padding(padding: EdgeInsets.only(top: 30), child: EmptyState(icon: Icons.receipt_long_outlined, title: 'No transactions yet'));
                      }

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(color: AppTheme.surface(context), borderRadius: BorderRadius.circular(18)),
                        child: Column(
                          children: [
                            for (int i = 0; i < txs.length; i++) ...[
                              _txRow(context, txs[i]),
                              if (i != txs.length - 1) Divider(height: 1, color: AppTheme.borderColor(context)),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _txRow(BuildContext context, WalletTransaction tx) {
    final credit = _isCredit(tx.type);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: (credit ? Colors.green : Colors.red).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(credit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, size: 16, color: credit ? Colors.green : Colors.red),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_typeLabel(tx.type), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                if (tx.description != null) Text(tx.description!, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5, color: AppTheme.textSecondary(context))),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${credit ? '+' : '-'}₹${tx.amount.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.w800, color: credit ? Colors.green.shade700 : Colors.red.shade700)),
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(color: _statusColor(tx.status).withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                child: Text(tx.status, style: TextStyle(fontSize: 10, color: _statusColor(tx.status), fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
