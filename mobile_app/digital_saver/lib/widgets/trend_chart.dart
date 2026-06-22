import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:digital_saver/theme/app_theme.dart';

class TrendChart extends StatelessWidget {
  final List<double> data;
  final Color lineColor;
  final String title;
  final double? minY;
  final double? maxY;

  const TrendChart({
    super.key,
    required this.data,
    required this.lineColor,
    this.title = '',
    this.minY,
    this.maxY,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (data.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            'No data available',
            style: AppTheme.bodyMedium,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty) ...[
            Text(title, style: AppTheme.titleMedium),
            const SizedBox(height: 16),
          ],
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: _calculateInterval(),
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: AppTheme.bodySmall,
                      ),
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() % (data.length ~/ 4).clamp(1, 10) == 0) {
                          return Text(
                            _formatLabel(value.toInt()),
                            style: AppTheme.bodySmall,
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (data.length - 1).toDouble(),
                minY: minY ?? _getMinY(),
                maxY: maxY ?? _getMaxY(),
                lineBarsData: [
                  LineChartBarData(
                    spots: data.asMap().entries.map((e) {
                      return FlSpot(e.key.toDouble(), e.value);
                    }).toList(),
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: lineColor,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: lineColor,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          lineColor.withOpacity(0.3),
                          lineColor.withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => isDark ? Colors.grey[800]! : Colors.grey[100]!,
                    tooltipRoundedRadius: 12,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        return LineTooltipItem(
                          spot.y.toStringAsFixed(1),
                          TextStyle(
                            color: lineColor,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _getMinY() {
    if (minY != null) return minY!;
    final min = data.reduce((a, b) => a < b ? a : b);
    return (min * 0.9).floorToDouble();
  }

  double _getMaxY() {
    if (maxY != null) return maxY!;
    final max = data.reduce((a, b) => a > b ? a : b);
    return (max * 1.1).ceilToDouble();
  }

  double _calculateInterval() {
    final range = _getMaxY() - _getMinY();
    return (range / 4).ceilToDouble();
  }

  String _formatLabel(int index) {
    return 'P$index';
  }
}
