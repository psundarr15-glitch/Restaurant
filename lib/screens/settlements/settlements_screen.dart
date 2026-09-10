import 'package:flutter/material.dart';
import '../../models/settlement.dart';
import '../../services/finance_service.dart';
import '../../services/api_client.dart';
import '../../theme.dart';
import '../../widgets/common/states.dart';
import 'settlement_details_screen.dart';

class SettlementsScreen extends StatefulWidget {
  const SettlementsScreen({super.key});
  @override
  State<SettlementsScreen> createState() => _SettlementsScreenState();
}

class _SettlementsScreenState extends State<SettlementsScreen> {
  Future<List<Settlement>>? _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => setState(() => _future = FinanceService.settlements());

  Color _statusColor(String status) {
    switch (status) {
      case 'paid': return Colors.green;
      case 'processing': return Colors.blue;
      case 'failed': return Colors.red;
      default: return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg(context),
      appBar: AppBar(title: const Text('Settlements')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _load(),
          color: AppTheme.primary,
          child: FutureBuilder<List<Settlement>>(
            future: _future,
            builder: (context, snapshot) {
              if (!snapshot.hasData && !snapshot.hasError) return const LoadingState();
              if (snapshot.hasError) {
                return ListView(children: [
                  const SizedBox(height: 60),
                  ErrorState(message: snapshot.error is ApiException ? (snapshot.error as ApiException).message : '${snapshot.error}', onRetry: _load),
                ]);
              }
              final settlements = snapshot.data!;
              if (settlements.isEmpty) {
                return ListView(children: const [
                  SizedBox(height: 60),
                  EmptyState(
                    icon: Icons.account_balance_outlined,
                    title: 'No settlements yet',
                    subtitle: 'Payouts to your bank account will show up here once processed.',
                  ),
                ]);
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                itemCount: settlements.length,
                itemBuilder: (context, i) {
                  final s = settlements[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Material(
                      color: AppTheme.surface(context),
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => SettlementDetailsScreen(settlementId: s.id))),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('#${s.settlementCode}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(color: _statusColor(s.status).withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                                    child: Text(s.status[0].toUpperCase() + s.status.substring(1), style: TextStyle(color: _statusColor(s.status), fontSize: 11.5, fontWeight: FontWeight.w700)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text('₹${s.amount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                              const SizedBox(height: 4),
                              Text('${s.periodStart} to ${s.periodEnd} · ${s.orderCount} orders', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary(context))),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
