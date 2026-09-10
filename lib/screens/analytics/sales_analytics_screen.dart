import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/sales_analytics.dart';
import '../../services/finance_service.dart';
import '../../services/api_client.dart';
import '../../theme.dart';
import '../../widgets/common/search_and_filter.dart';
import '../../widgets/common/states.dart';

class SalesAnalyticsScreen extends StatefulWidget {
  const SalesAnalyticsScreen({super.key});
  @override
  State<SalesAnalyticsScreen> createState() => _SalesAnalyticsScreenState();
}

class _SalesAnalyticsScreenState extends State<SalesAnalyticsScreen> {
  static const _ranges = ['7d', '30d', '90d', '180d', '365d'];
  static const _labels = ['7 Days', '30 Days', '3 Months', '6 Months', '1 Year'];

  Future<SalesAnalyticsData>? _future;
  int _rangeIndex = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() => _future = FinanceService.salesAnalytics(_ranges[_rangeIndex]));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg(context),
      appBar: AppBar(title: const Text('Sales Analytics')),
      body: SafeArea(
        child: FutureBuilder<SalesAnalyticsData>(
          future: _future,
          builder: (context, snapshot) {
            if (!snapshot.hasData && !snapshot.hasError) return const LoadingState();
            if (snapshot.hasError) return ErrorState(message: snapshot.error is ApiException ? (snapshot.error as ApiException).message : '${snapshot.error}', onRetry: _load);

            final data = snapshot.data!;
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                FilterChipRow(labels: _labels, selectedIndex: _rangeIndex, onSelected: (i) {
                  setState(() => _rangeIndex = i);
                  _load();
                }),
                const SizedBox(height: 16),
                _card(context, title: 'Sales Trend', child: data.salesChart.isEmpty
                    ? const EmptyState(icon: Icons.show_chart_rounded, title: 'No sales in this period')
                    : SizedBox(height: 200, child: _salesLineChart(context, data.salesChart))),
                const SizedBox(height: 16),
                _card(context, title: 'Orders Trend', child: data.salesChart.isEmpty
                    ? const EmptyState(icon: Icons.bar_chart_rounded, title: 'No orders in this period')
                    : SizedBox(height: 180, child: _ordersBarChart(context, data.salesChart))),
                const SizedBox(height: 16),
                _card(context, title: 'Peak Hours', child: data.peakHours.isEmpty
                    ? const EmptyState(icon: Icons.access_time_rounded, title: 'Not enough data yet')
                    : SizedBox(height: 180, child: _peakHoursChart(context, data.peakHours))),
                const SizedBox(height: 16),
                _card(context, title: 'Top Selling Foods', child: data.topFoods.isEmpty
                    ? const EmptyState(icon: Icons.restaurant_outlined, title: 'No orders in this period')
                    : Column(children: [
                        for (int i = 0; i < data.topFoods.length; i++) _topFoodRow(context, i + 1, data.topFoods[i]),
                      ])),
                const SizedBox(height: 16),
                _card(context, title: 'Top Categories', child: EmptyState(icon: Icons.category_outlined, title: 'Not available yet', subtitle: data.topCategoriesNote)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _card(BuildContext context, {required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.surface(context), borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppTheme.textPrimary(context))),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _salesLineChart(BuildContext context, List<SalesDay> days) {
    final spots = <FlSpot>[for (int i = 0; i < days.length; i++) FlSpot(i.toDouble(), days[i].sales)];
    return LineChart(LineChartData(
      gridData: const FlGridData(show: true, drawVerticalLine: false),
      titlesData: FlTitlesData(
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 26, getTitlesWidget: (v, meta) {
          final i = v.toInt();
          if (i < 0 || i >= days.length || (days.length > 8 && i % (days.length ~/ 6).clamp(1, 999) != 0)) return const SizedBox.shrink();
          return Padding(padding: const EdgeInsets.only(top: 6), child: Text('${days[i].day.day}/${days[i].day.month}', style: const TextStyle(fontSize: 10)));
        })),
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: (v, meta) => Text('₹${v.toInt()}', style: const TextStyle(fontSize: 9)))),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: AppTheme.primary,
          barWidth: 3,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: true, color: AppTheme.primary.withOpacity(0.1)),
        ),
      ],
    ));
  }

  Widget _ordersBarChart(BuildContext context, List<SalesDay> days) {
    return BarChart(BarChartData(
      gridData: const FlGridData(show: false),
      titlesData: FlTitlesData(
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 26, getTitlesWidget: (v, meta) {
          final i = v.toInt();
          if (i < 0 || i >= days.length || (days.length > 8 && i % (days.length ~/ 6).clamp(1, 999) != 0)) return const SizedBox.shrink();
          return Padding(padding: const EdgeInsets.only(top: 6), child: Text('${days[i].day.day}/${days[i].day.month}', style: const TextStyle(fontSize: 10)));
        })),
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, getTitlesWidget: (v, meta) => Text('${v.toInt()}', style: const TextStyle(fontSize: 9)))),
      ),
      borderData: FlBorderData(show: false),
      barGroups: [
        for (int i = 0; i < days.length; i++)
          BarChartGroupData(x: i, barRods: [BarChartRodData(toY: days[i].orders.toDouble(), color: AppTheme.gold, width: 10, borderRadius: BorderRadius.circular(4))]),
      ],
    ));
  }

  Widget _peakHoursChart(BuildContext context, List<PeakHour> hours) {
    final byHour = {for (final h in hours) h.hour: h.orders};
    return BarChart(BarChartData(
      gridData: const FlGridData(show: false),
      titlesData: FlTitlesData(
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 24, getTitlesWidget: (v, meta) {
          final h = v.toInt();
          if (h % 3 != 0) return const SizedBox.shrink();
          return Text('$h', style: const TextStyle(fontSize: 9));
        })),
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, getTitlesWidget: (v, meta) => Text('${v.toInt()}', style: const TextStyle(fontSize: 9)))),
      ),
      borderData: FlBorderData(show: false),
      barGroups: [
        for (int h = 0; h < 24; h++)
          BarChartGroupData(x: h, barRods: [BarChartRodData(toY: (byHour[h] ?? 0).toDouble(), color: Colors.blue, width: 6, borderRadius: BorderRadius.circular(3))]),
      ],
    ));
  }

  Widget _topFoodRow(BuildContext context, int rank, TopFood food) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(radius: 13, backgroundColor: AppTheme.primary.withOpacity(0.1), child: Text('$rank', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w800, fontSize: 12))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(food.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                Text('${food.orderCount} orders · ${food.quantity} sold', style: TextStyle(fontSize: 11.5, color: AppTheme.textSecondary(context))),
              ],
            ),
          ),
          Text('₹${food.revenue.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
