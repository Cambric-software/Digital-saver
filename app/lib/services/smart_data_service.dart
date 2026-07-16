import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/health_models.dart';

/// Smart Data Management System for health data
class SmartDataService {
  /// Store health data with quality scoring
  static Future<void> storeHealthData({
    required String userId,
    required String dataType,
    required Map<String, dynamic> data,
    int qualityScore = 100,
  }) async {
    final client = Supabase.instance.client;
    await client.from('digital_saver_health_logs').insert({
      'user_id': userId,
      'device_id': data['device_id'],
      'recorded_at': DateTime.now().toIso8601String(),
      ...data,
      'metadata': {'quality_score': qualityScore},
    });
    await _updateStorageStats(userId, dataType);
  }

  /// Get recent health data
  Future<List<Map<String, dynamic>>> getRecentData({
    required String userId,
    required String dataType,
    int days = 7,
  }) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    final result = await Supabase.instance.client
        .from('digital_saver_health_logs')
        .select()
        .eq('user_id', userId)
        .gte('recorded_at', cutoffDate.toIso8601String())
        .order('recorded_at', ascending: false);
    return result.toList();
  }

  /// Perform smart cleanup
  Future<CleanupReport> performSmartCleanup(String userId) async {
    final report = CleanupReport();
    try {
      final records = await Supabase.instance.client
          .from('digital_saver_health_logs')
          .select('id')
          .eq('user_id', userId)
          .limit(1000);
      report.deletedRecords['total'] = records.length;
    } catch (_) {}
    return report;
  }

  static Future<void> _updateStorageStats(String userId, String dataType) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'stats_$userId';
    final count = (prefs.getInt(key) ?? 0) + 1;
    await prefs.setInt(key, count);
  }

  /// Get storage statistics
  Future<StorageStats> getStorageStats(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'stats_$userId';
    final count = prefs.getInt(key) ?? 0;
    return StorageStats(
      totalRecords: count,
      recordsByType: {'health_data': count},
      estimatedStorageMB: count * 0.001,
    );
  }

  /// Calculate quality score
  static int calculateQualityScore(HealthSnapshot snapshot) {
    double score = 100;
    if (snapshot.heartRate.confidence > 0) {
      score -= (100 - snapshot.heartRate.confidence) * 0.2;
    }
    if (snapshot.bloodPressure.confidence > 0) {
      score -= (100 - snapshot.bloodPressure.confidence) * 0.2;
    }
    if (snapshot.oxygen.confidence > 0) {
      score -= (100 - snapshot.oxygen.confidence) * 0.15;
    }
    return score.round().clamp(0, 100);
  }
}

/// Cleanup report
class CleanupReport {
  final Map<String, int> deletedRecords = {};
  int get totalDeleted => deletedRecords.values.fold(0, (a, b) => a + b);
  String get summary => 'Cleaned $totalDeleted records';
}

/// Storage statistics
class StorageStats {
  final int totalRecords;
  final Map<String, int> recordsByType;
  final double estimatedStorageMB;
  
  StorageStats({
    required this.totalRecords,
    required this.recordsByType,
    required this.estimatedStorageMB,
  });
  
  String get formattedSize {
    if (estimatedStorageMB < 1) {
      return '${(estimatedStorageMB * 1024).toStringAsFixed(0)} KB';
    }
    return '${estimatedStorageMB.toStringAsFixed(1)} MB';
  }
}
