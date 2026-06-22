import 'package:flutter/material.dart';
import 'package:digital_saver/theme/app_theme.dart';
import 'package:digital_saver/models/health_models.dart';
import 'package:digital_saver/services/health_analysis_service.dart';

class HealthMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;
  final HeartRateStatus status;
  final TrendAnalysis? trend;
  final VoidCallback? onTap;

  const HealthMetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
    required this.status,
    this.trend,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppTheme.softShadow,
          border: Border.all(
            color: _getStatusColor().withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                _buildTrendIndicator(),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: AppTheme.bodySmall.copyWith(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: AppTheme.headlineSmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(),
                  ),
                ),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    unit,
                    style: AppTheme.bodySmall.copyWith(
                      color: isDark ? Colors.grey[500] : Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildStatusBadge(),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendIndicator() {
    if (trend == null) return const SizedBox.shrink();
    
    IconData trendIcon;
    Color trendColor;
    
    switch (trend!.direction) {
      case Trend.up:
        trendIcon = Icons.trending_up_rounded;
        trendColor = AppTheme.warningOrange;
        break;
      case Trend.down:
        trendIcon = Icons.trending_down_rounded;
        trendColor = AppTheme.infoBlue;
        break;
      case Trend.stable:
        trendIcon = Icons.trending_flat_rounded;
        trendColor = AppTheme.healthyGreen;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: trendColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(trendIcon, color: trendColor, size: 16),
    );
  }

  Widget _buildStatusBadge() {
    Color badgeColor;
    String statusText;
    
    switch (status) {
      case HeartRateStatus.normal:
        badgeColor = AppTheme.healthyGreen;
        statusText = 'Normal';
        break;
      case HeartRateStatus.warning:
        badgeColor = AppTheme.warningOrange;
        statusText = 'Warning';
        break;
      case HeartRateStatus.critical:
        badgeColor = AppTheme.dangerRed;
        statusText = 'Critical';
        break;
      case HeartRateStatus.unknown:
        badgeColor = Colors.grey;
        statusText = 'Unknown';
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: badgeColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            statusText,
            style: TextStyle(
              color: badgeColor,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (status) {
      case HeartRateStatus.normal:
        return AppTheme.healthyGreen;
      case HeartRateStatus.warning:
        return AppTheme.warningOrange;
      case HeartRateStatus.critical:
        return AppTheme.dangerRed;
      case HeartRateStatus.unknown:
        return Colors.grey;
    }
  }
}
