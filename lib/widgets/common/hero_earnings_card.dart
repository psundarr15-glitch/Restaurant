import 'package:flutter/material.dart';
import '../../theme.dart';

/// The big red "Today's Sales" card at the top of Home. [percentVsYesterday]
/// is null when there's no revenue yesterday to compare against — in that
/// case the delta row is simply omitted rather than showing a misleading
/// number.
class HeroEarningsCard extends StatelessWidget {
  final double todaySales;
  final double? percentVsYesterday;
  final int ordersToday;

  const HeroEarningsCard({
    super.key,
    required this.todaySales,
    required this.percentVsYesterday,
    required this.ordersToday,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [AppTheme.primary, AppTheme.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(color: AppTheme.primary.withOpacity(0.35), blurRadius: 18, offset: const Offset(0, 8)),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            top: -10,
            child: Icon(Icons.restaurant_rounded, size: 90, color: Colors.white.withOpacity(0.08)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Today's Sales", style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text(
                '₹${todaySales.toStringAsFixed(0)}',
                style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  if (percentVsYesterday != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            percentVsYesterday! >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${percentVsYesterday! >= 0 ? '+' : ''}${percentVsYesterday!.toStringAsFixed(0)}% vs yesterday',
                            style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text('$ordersToday orders today', style: const TextStyle(color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.w500)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
