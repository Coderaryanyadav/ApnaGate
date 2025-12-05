import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

class AnalyticsDashboard extends ConsumerWidget {
  const AnalyticsDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Force dark chart colors
    final isDark = true; 
    
    return Scaffold(
      appBar: AppBar(title: const Text('📊 Analytics')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('📈 Visitor Trends (Last 7 Days)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            // 📊 Bar Chart
            Container(
              height: 300,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 60,
                  gridData: const FlGridData(show: false),
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                          if (value.toInt() >= 0 && value.toInt() < days.length) {
                             return Padding(
                               padding: const EdgeInsets.only(top: 8),
                               child: Text(days[value.toInt()], style: const TextStyle(fontSize: 12, color: Colors.white70)),
                             );
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, getTitlesWidget: (val, meta) => Text(val.toInt().toString(), style: const TextStyle(color: Colors.white54, fontSize: 10)))),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: _getDemoData(),
                ),
              ),
            ),

            const SizedBox(height: 32),
            const Text('🥧 Visitor Types', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            // 🥧 Pie Chart
            Container(
              height: 200,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: [
                    PieChartSectionData(value: 40, title: '40%', color: Colors.orange, radius: 50, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    PieChartSectionData(value: 30, title: '30%', color: Colors.blue, radius: 50, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    PieChartSectionData(value: 20, title: '20%', color: Colors.yellow, radius: 50, titleStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    PieChartSectionData(value: 10, title: '10%', color: Colors.purple, radius: 50, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            
            // Legend
            const SizedBox(height: 16),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                 _ChartLegend(color: Colors.orange, label: 'Delivery'),
                 _ChartLegend(color: Colors.blue, label: 'Guest'),
                 _ChartLegend(color: Colors.yellow, label: 'Cab'),
                 _ChartLegend(color: Colors.purple, label: 'Other'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<BarChartGroupData> _getDemoData() {
    return List.generate(7, (index) {
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: (index + 1) * 5.0 + (index % 3) * 10,
            color: Colors.indigo,
            width: 16,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    });
  }
}

class _ChartLegend extends StatelessWidget {
  final Color color;
  final String label;

  const _ChartLegend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
