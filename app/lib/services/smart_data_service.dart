import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/health_models.dart';

// ===========================================================================
// SMART DATA MANAGEMENT SYSTEM - "LIKE" SYSTEM FOR HEALTH DATA
// ===========================================================================
// Intelligent data retention that:
// 1. Keeps high-quality, recent health data
// 2. Archives important historical patterns
// 3. Deletes truly useless/redundant data
// 4. Optimizes storage across local and cloud
// ===========================================================================

class SmartDataService {
  final SupabaseClient _client = Supabase.instance.client;

  // Data retention rules based on data type
  static const Map<String, DataRetentionRule> _retentionRules = {
    'heart_rate': DataRetentionRule(
      keepRecentDays: 30,
      keepDailyAggregatesDays: 365,
      keepWeeklyAggregatesDays: 1825,
      compressAfterDays: 7,
      deleteAfterDays: 365 * 5,
    ),
    'blood_pressure': DataRetentionRule(
      keepRecentDays: 90,
      keepDailyAggregatesDays: 730,
      keepWeeklyAggregatesDays: 3650,
      compressAfterDays: 14,
      deleteAfterDays: 365 * 10,
    ),
    'oxygen': DataRetentionRule(
      keepRecentDays: 30,
      keepDailyAggregatesDays: 365,
      keepWeeklyAggregatesDays: 1825,
      compressAfterDays: 7,
      deleteAfterDays: 365 * 5,
    ),
    'activity': DataRetentionRule(
      keepRecentDays: 60,
      keepDailyAggregatesDays: 730,
      keepWeeklyAggregatesDays: 3650,
      compressAfterDays: 14,
      deleteAfterDays: 365 * 10,
    ),
    'sleep': DataRetentionRule(
      keepRecentDays: 90,
      keepDailyAggregatesDays: 730,
      keepWeeklyAggregatesDays: 3650,
      compressAfterDays: 30,
      deleteAfterDays: 365 * 10,
    ),
    'hrv': DataRetentionRule(
      keepRecentDays: 30,
      keepDailyAggregatesDays: 365,
      keepWeeklyAggregatesDays: 1825,
      compressAfterDays: 7,
      deleteAfterDays: 365 * 5,
    ),
  };

  // =========================================================================
  // DATA STORAGE METHODS
  // =========================================================================

  /// Store health data with smart deduplication and quality scoring
  static Future<void> storeHealthData({
    required String userId,
    required String dataType,
    required Map<String, dynamic> data,
    int qualityScore = 100,
  }) async {
    final client = Supabase.instance.client;

    // Check for duplicates within short time window
    final recentData = await _findRecentDuplicate(client, userId, dataType, data);
    if (recentData != null) {
      // Update existing record instead of creating new one
      await client.from('digital_saver_health_logs').update({
        ...data,
        'metadata': {
          'quality_score': qualityScore,
          'updated_at': DateTime.now().toIso8601String(),
          'merge_count': (recentData['metadata']?['merge_count'] ?? 0) + 1,
        },
      }).eq('id', recentData['id']);
    } else {
      // Insert new record
      await client.from('digital_saver_health_logs').insert({
        'user_id': userId,
        'device_id': data['device_id'],
        'recorded_at': DateTime.now().toIso8601String(),
        ...data,
        'metadata': {
          'quality_score': qualityScore,
          'created_at': DateTime.now().toIso8601String(),
        },
      });
    }

    // Update storage stats
    await _updateStorageStats(userId, dataType);
  }

  /// Find if similar data already exists (within 5 minutes)
  static Future<Map<String, dynamic>?> _findRecentDuplicate(
    SupabaseClient client,
    String userId,
    String dataType,
    Map<String, dynamic> data,
  ) async {
    final fiveMinutesAgo = DateTime.now().subtract(const Duration(minutes: 5));

    // Determine time field based on data type
    String timeField = 'recorded_at';

    final result = await client
        .from('digital_saver_health_logs')
        .select()
        .eq('user_id', userId)
        .gte(timeField, fiveMinutesAgo.toIso8601String())
        .limit(1);

    return result.isNotEmpty ? result.first : null;
  }

  // =========================================================================
  // DATA RETRIEVAL METHODS
  // =========================================================================

  /// Get recent health data with automatic quality filtering
  Future<List<Map<String, dynamic>>> getRecentData({
    required String userId,
    required String dataType,
    int days = 7,
    int minQualityScore = 50,
  }) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));

    final result = await _client
        .from('digital_saver_health_logs')
        .select()
        .eq('user_id', userId)
        .gte('recorded_at', cutoffDate.toIso8601String())
        .order('recorded_at', ascending: false);

    return result
        .where((record) =>
            (record['metadata']?['quality_score'] ?? 100) >= minQualityScore)
        .toList();
  }

  /// Get aggregated daily data for trend analysis
  Future<List<Map<String, dynamic>>> getDailyAggregates({
    required String userId,
    required String dataType,
    int days = 30,
  }) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));

    // Query raw data and aggregate
    final rawData = await _client
        .from('digital_saver_health_logs')
        .select()
        .eq('user_id', userId)
        .gte('recorded_at', cutoffDate.toIso8601String())
        .order('recorded_at', ascending: false);

    // Group by day and aggregate
    final Map<String, List<Map<String, dynamic>>> byDay = {};
    for (var record in rawData) {
      final date = DateTime.parse(record['recorded_at']);
      final dayKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      byDay.putIfAbsent(dayKey, () => []).add(record);
    }

    // Calculate aggregates
    return byDay.entries.map((entry) {
      final records = entry.value;
      return _aggregateRecords(dataType, records, entry.key);
    }).toList();
  }

  static Map<String, dynamic> _aggregateRecords(
    String dataType,
    List<Map<String, dynamic>> records,
    String date,
  ) {
    Map<String, dynamic> aggregate = {
      'date': date,
      'record_count': records.length,
      'quality_avg': records
              .map((r) => r['metadata']?['quality_score'] ?? 100)
              .reduce((a, b) => a + b) /
          records.length,
    };

    // Type-specific aggregations
    switch (dataType) {
      case 'heart_rate':
        aggregate['hr_avg'] = _avg(records, 'heart_rate');
        aggregate['hr_min'] = _min(records, 'heart_rate');
        aggregate['hr_max'] = _max(records, 'heart_rate');
        aggregate['hrv_avg'] = _avg(records, 'hrv_rmssd');
        break;
      case 'blood_pressure':
        aggregate['systolic_avg'] = _avg(records, 'systolic_bp');
        aggregate['diastolic_avg'] = _avg(records, 'diastolic_bp');
        aggregate['bp_record_count'] = records.where((r) => r['systolic_bp'] != null).length;
        break;
      case 'oxygen':
        aggregate['spo2_avg'] = _avg(records, 'spo2');
        aggregate['spo2_min'] = _min(records, 'spo2');
        break;
      case 'activity':
        aggregate['steps_total'] = _sum(records, 'steps');
        aggregate['calories_total'] = _sum(records, 'calories_burned');
        aggregate['active_minutes_total'] = _sum(records, 'active_minutes');
        break;
      case 'sleep':
        aggregate['sleep_avg'] = _avg(records, 'sleep_minutes');
        aggregate['deep_sleep_avg'] = _avg(records, 'deep_sleep_minutes');
        aggregate['rem_sleep_avg'] = _avg(records, 'rem_sleep_minutes');
        break;
    }

    return aggregate;
  }

  static double _avg(List<Map<String, dynamic>> records, String field) {
    final values = records
        .where((r) => r[field] != null)
        .map((r) => (r[field] as num).toDouble())
        .toList();
    return values.isNotEmpty ? values.reduce((a, b) => a + b) / values.length : 0;
  }

  static double _min(List<Map<String, dynamic>> records, String field) {
    final values = records
        .where((r) => r[field] != null)
        .map((r) => (r[field] as num).toDouble())
        .toList();
    return values.isNotEmpty ? values.reduce((a, b) => a < b ? a : b) : 0;
  }

  static double _max(List<Map<String, dynamic>> records, String field) {
    final values = records
        .where((r) => r[field] != null)
        .map((r) => (r[field] as num).toDouble())
        .toList();
    return values.isNotEmpty ? values.reduce((a, b) => a > b ? a : b) : 0;
  }

  static double _sum(List<Map<String, dynamic>> records, String field) {
    final values = records
        .where((r) => r[field] != null)
        .map((r) => (r[field] as num).toDouble())
        .toList();
    return values.isNotEmpty ? values.reduce((a, b) => a + b) : 0;
  }

  // =========================================================================
  // SMART CLEANUP & DATA PRUNING
  // =========================================================================

  /// Analyze and clean up old/redundant data
  Future<CleanupReport> performSmartCleanup(String userId) async {
    final report = CleanupReport();
    final now = DateTime.now();

    for (var entry in _retentionRules.entries) {
      final dataType = entry.key;
      final rule = entry.value;

      // Find records to clean
      final oldRecords = await _findOldRecords(
        userId,
        dataType,
        now.subtract(Duration(days: rule.deleteAfterDays)),
      );

      if (oldRecords.isNotEmpty) {
        // Check if we have good aggregated data
        final hasAggregates = await _hasGoodAggregates(
          userId,
          dataType,
          now.subtract(Duration(days: rule.keepDailyAggregatesDays)),
        );

        if (hasAggregates) {
          // Safe to delete old raw records
          await _deleteRecords(oldRecords.map((r) => r['id']).toList());
          report.deletedRecords[dataType] = oldRecords.length;
          report.freedStorageMB += oldRecords.length * 0.001; // ~1KB per record
        } else {
          // Keep a sample of important records
          final samplesToKeep = oldRecords.take(30).toList();
          final toDelete = oldRecords.skip(30).toList();

          if (toDelete.isNotEmpty) {
            await _deleteRecords(toDelete.map((r) => r['id']).toList());
            report.deletedRecords[dataType] = toDelete.length;
            report.preservedSamples[dataType] = samplesToKeep.length;
          }
        }
      }

      // Compress old but still useful records
      final compressibleRecords = await _findOldRecords(
        userId,
        dataType,
        now.subtract(Duration(days: rule.compressAfterDays)),
      );

      if (compressibleRecords.isNotEmpty) {
        await _compressRecords(compressibleRecords);
        report.compressedRecords[dataType] = compressibleRecords.length;
      }
    }

    // Update storage stats
    await _updateCleanupReport(userId, report);

    return report;
  }

  Future<List<Map<String, dynamic>>> _findOldRecords(
    String userId,
    String dataType,
    DateTime cutoffDate,
  ) async {
    return await _client
        .from('digital_saver_health_logs')
        .select()
        .eq('user_id', userId)
        .lt('recorded_at', cutoffDate.toIso8601String())
        .order('recorded_at', ascending: true)
        .limit(10000);
  }

  Future<bool> _hasGoodAggregates(
    String userId,
    String dataType,
    DateTime since,
  ) async {
    final count = await _client
        .from('digital_saver_health_logs')
        .select('id')
        .eq('user_id', userId)
        .gte('recorded_at', since.toIso8601String())
        .count(CountOption.exact);

    // If we have at least one record per week for the period, we have good aggregates
    final weeksInPeriod = DateTime.now().difference(since).inDays / 7;
    return count >= weeksInPeriod;
  }

  Future<void> _deleteRecords(List<String> ids) async {
    if (ids.isEmpty) return;
    await _client
        .from('digital_saver_health_logs')
        .delete()
        .in_('id', ids);
  }

  Future<void> _compressRecords(List<Map<String, dynamic>> records) async {
    for (var record in records) {
      // Remove detailed RR intervals, keep summary stats
      final compressed = Map<String, dynamic>.from(record);
      compressed['metadata'] = {
        ...record['metadata'] as Map<String, dynamic>? ?? {},
        'compressed': true,
        'compressed_at': DateTime.now().toIso8601String(),
      };
      // Remove raw RR intervals if present
      compressed.remove('rr_intervals_raw');

      await _client
          .from('digital_saver_health_logs')
          .update(compressed)
          .eq('id', record['id']);
    }
  }

  // =========================================================================
  // STORAGE STATISTICS
  // =========================================================================

  Future<void> _updateStorageStats(String userId, String dataType) async {
    final prefs = await SharedPreferences.getInstance();
    final statsKey = 'storage_stats_$userId';
    final existingStats = prefs.getString(statsKey);

    Map<String, dynamic> stats = existingStats != null
        ? Map<String, dynamic>.from(
            Uri.splitQueryString(existingStats).map(
              (k, v) => MapEntry(k, int.tryParse(v) ?? 0),
            ),
          )
        : {};

    stats[dataType] = (stats[dataType] ?? 0) + 1;
    stats['last_updated'] = DateTime.now().millisecondsSinceEpoch;

    await prefs.setString(
      statsKey,
      stats.entries.map((e) => '${e.key}=${e.value}').join('&'),
    );
  }

  Future<void> _updateCleanupReport(String userId, CleanupReport report) async {
    final prefs = await SharedPreferences.getInstance();
    final reportKey = 'cleanup_report_$userId';

    await prefs.setString(reportKey, '''
Last cleanup: ${DateTime.now().toIso8601String()}
Total deleted: ${report.totalDeleted}
Total compressed: ${report.totalCompressed}
Freed storage: ${report.freedStorageMB.toStringAsFixed(2)} MB
''');
  }

  /// Get storage statistics for user
  Future<StorageStats> getStorageStats(String userId) async {
    final prefs = await SharedPreferences.getInstance();

    // Get table counts
    final counts = <String, int>{};
    for (var dataType in _retentionRules.keys) {
      final count = await _client
          .from('digital_saver_health_logs')
          .select('id')
          .eq('user_id', userId)
          .count(CountOption.exact);
      counts[dataType] = count;
    }

    // Get stored stats
    final statsKey = 'storage_stats_$userId';
    final storedStats = prefs.getString(statsKey);
    Map<String, dynamic> localStats = {};
    if (storedStats != null) {
      localStats = Uri.splitQueryString(storedStats);
    }

    return StorageStats(
      totalRecords: counts.values.fold(0, (a, b) => a + b),
      recordsByType: counts,
      estimatedStorageMB: counts.values.fold(0, (a, b) => a + b) * 0.001,
      lastCleanup: localStats['last_updated'] != null
          ? DateTime.fromMillisecondsSinceEpoch(int.parse(localStats['last_updated']))
          : null,
    );
  }

  // =========================================================================
  // DATA QUALITY SCORING
  // =========================================================================

  /// Calculate quality score for health data
  static int calculateQualityScore(HealthSnapshot snapshot) {
    double score = 100;

    // Heart rate quality
    if (snapshot.heartRate.confidence > 0) {
      score -= (100 - snapshot.heartRate.confidence) * 0.2;
    }

    // Blood pressure quality
    if (snapshot.bloodPressure.confidence > 0) {
      score -= (100 - snapshot.bloodPressure.confidence) * 0.2;
    }

    // Oxygen quality
    if (snapshot.oxygen.confidence > 0) {
      score -= (100 - snapshot.oxygen.confidence) * 0.15;
    }

    // Recency bonus (recent data is higher quality)
    final age = DateTime.now().difference(snapshot.heartRate.timestamp);
    if (age.inMinutes < 5) {
      score += 5;
    } else if (age.inMinutes < 30) {
      score += 2;
    }

    return score.round().clamp(0, 100);
  }
}

// ===========================================================================
// DATA CLASSES
// ===========================================================================

class DataRetentionRule {
  final int keepRecentDays;
  final int keepDailyAggregatesDays;
  final int keepWeeklyAggregatesDays;
  final int compressAfterDays;
  final int deleteAfterDays;

  const DataRetentionRule({
    required this.keepRecentDays,
    required this.keepDailyAggregatesDays,
    required this.keepWeeklyAggregatesDays,
    required this.compressAfterDays,
    required this.deleteAfterDays,
  });
}

class CleanupReport {
  final Map<String, int> deletedRecords = {};
  final Map<String, int> compressedRecords = {};
  final Map<String, int> preservedSamples = {};
  double freedStorageMB = 0;

  int get totalDeleted => deletedRecords.values.fold(0, (a, b) => a + b);
  int get totalCompressed => compressedRecords.values.fold(0, (a, b) => a + b);

  String get summary => '''
Cleanup completed:
- Deleted: $totalDeleted records
- Compressed: $totalCompressed records
- Freed: ${freedStorageMB.toStringAsFixed(2)} MB
''';
}

class StorageStats {
  final int totalRecords;
  final Map<String, int> recordsByType;
  final double estimatedStorageMB;
  final DateTime? lastCleanup;

  StorageStats({
    required this.totalRecords,
    required this.recordsByType,
    required this.estimatedStorageMB,
    this.lastCleanup,
  });

  String get formattedSize {
    if (estimatedStorageMB < 1) {
      return '${(estimatedStorageMB * 1024).toStringAsFixed(0)} KB';
    }
    return '${estimatedStorageMB.toStringAsFixed(1)} MB';
  }
}
