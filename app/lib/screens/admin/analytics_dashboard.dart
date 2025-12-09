import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/firestore_service.dart';

class AnalyticsDashboard extends ConsumerWidget {
  const AnalyticsDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firestoreService = ref.watch(firestoreServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('📊 Analytics')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Stats Cards
            FutureBuilder<Map<String, int>>(
              future: firestoreService.getUserCountsByRole(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final counts = snapshot.data!;
                return Row(
                  children: [
                    Expanded(child: _buildStatCard('Admins', counts['admin'] ?? 0, Colors.red)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildStatCard('Guards', counts['guard'] ?? 0, Colors.blue)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildStatCard('Residents', counts['resident'] ?? 0, Colors.green)),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),
            const Text('📈 Visitor Trends (Last 7 Days)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            // Bar Chart - Real Data
            FutureBuilder<List<Map<String, dynamic>>>(
              future: firestoreService.getDailyVisitorCounts(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox(height: 300, child: Center(child: CircularProgressIndicator()));
                }

                final dailyData = snapshot.data!;
                return Container(
                  height: 300,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: _getMaxY(dailyData),
                      gridData: const FlGridData(show: false),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() >= 0 && value.toInt() < dailyData.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    dailyData[value.toInt()]['dayName'],
                                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                                  ),
                                );
                              }
                              return const SizedBox();
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (val, meta) => Text(
                              val.toInt().toString(),
                              style: const TextStyle(color: Colors.white54, fontSize: 10),
                            ),
                          ),
                        ),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: List.generate(
                        dailyData.length,
                        (index) => BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: dailyData[index]['count'].toDouble(),
                              color: Colors.white,
                              width: 20,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 32),
            const Text('🥧 Visitor Status Distribution', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            // Pie Chart - Real Data
            FutureBuilder<Map<String, int>>(
              future: firestoreService.getVisitorCountsByStatus(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
                }

                final statusCounts = snapshot.data!;
                final total = statusCounts.values.fold(0, (sum, count) => sum + count);

                if (total == 0) {
                  return const Center(child: Text('No visitor data yet'));
                }

                return Container(
                  height: 200,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: _buildPieSections(statusCounts, total),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, int count, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(count.toString(), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  double _getMaxY(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return 10;
    final max = data.map((d) => d['count'] as int).reduce((a, b) => a > b ? a : b);
    return (max + 5).toDouble();
  }

  List<PieChartSectionData> _buildPieSections(Map<String, int> statusCounts, int total) {
    final colors = {
      'pending': Colors.orange,
      'approved': Colors.blue,
      'inside': Colors.green,
      'exited': Colors.grey,
    };

    return statusCounts.entries.map((entry) {
      final percentage = ((entry.value / total) * 100).toInt();
      return PieChartSectionData(
        value: entry.value.toDouble(),
        title: '$percentage%',
        color: colors[entry.key] ?? Colors.purple,
        radius: 50,
        titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
      );
    }).toList();
  }
}
