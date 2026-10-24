/// Measurable patterns in the samples the watch actually stored.
///
/// The previous file was a 1,150-line "doctor-level" analytics engine with
/// cardiovascular, respiratory, metabolic and stress scores. Nothing imported
/// it, which was fortunate: the scores were built from constants and guessed
/// reference ranges, several used fields the Veyro firmware never reports, and
/// an absent reading was quietly turned into a neutral 50 so the result looked
/// like a measurement instead of a gap.
///
/// This replacement answers three questions that the stored samples can actually
/// support:
///
///  * what the resting heart rate looked like, using the mean of the lowest
///    quarter of measured samples rather than a single reading;
///  * which way heart rate moved, comparing the first and second halves of the
///    samples in time order;
///  * what the lowest oxygen saturation was.
///
/// It needs a real minimum before answering: at least [minimumHeartRateSamples]
/// measured beats across [minimumDays] different local days. Below that the
/// pattern is reported as unavailable and the caller shows `--`, not a number.
/// Zero fields in a [WatchSample] mean "the watch did not measure this", so they
/// are skipped rather than counted as zero.
library;

import 'local_store.dart';

/// Which way measured heart rate moved over the analysed samples.
enum HeartRateDirection {
  /// The second half averaged at least [HealthPatternsService.trendThresholdBpm]
  /// higher than the first.
  rising('Rising'),

  /// The second half averaged at least [HealthPatternsService.trendThresholdBpm]
  /// lower than the first.
  falling('Falling'),

  /// The halves were within the threshold of each other.
  steady('Steady'),

  /// There were not enough measured samples to compare halves.
  unknown('Not enough data');

  const HeartRateDirection(this.label);

  /// A word for the Patterns panel.
  final String label;
}

/// What the stored samples can say, and what they cannot.
class HealthPatterns {
  /// Create a pattern result.
  const HealthPatterns({
    required this.sampleCount,
    required this.heartRateSamples,
    required this.daysWithHeartRate,
    required this.restingHeartRate,
    required this.direction,
    required this.changeBpm,
    required this.lowestOxygen,
    required this.oxygenSamples,
  });

  /// Samples considered, including ones with no measured value.
  final int sampleCount;

  /// Samples that carried a heart rate above zero.
  final int heartRateSamples;

  /// Distinct local days on which a heart rate was measured.
  final int daysWithHeartRate;

  /// Mean of the lowest quarter of measured heart rates, or 0 when there are
  /// not enough samples for the estimate.
  final int restingHeartRate;

  /// Direction of the heart-rate halves, or [HeartRateDirection.unknown].
  final HeartRateDirection direction;

  /// Signed change between the halves in BPM, 0 when unknown.
  final int changeBpm;

  /// Lowest measured oxygen saturation, or 0 when none was measured.
  final int lowestOxygen;

  /// Samples that carried an oxygen saturation above zero.
  final int oxygenSamples;

  /// Whether a resting heart rate could be estimated honestly.
  bool get hasRestingHeartRate =>
      heartRateSamples >= HealthPatternsService.minimumHeartRateSamples &&
      daysWithHeartRate >= HealthPatternsService.minimumDays &&
      restingHeartRate > 0;

  /// Whether there was enough data to compare heart-rate halves.
  bool get hasDirection => hasRestingHeartRate && direction != HeartRateDirection.unknown;

  /// Whether any oxygen saturation was measured.
  bool get hasOxygen => lowestOxygen > 0;

  /// Whether the stored samples carry any measured value at all.
  bool get hasAnyReading => heartRateSamples > 0 || oxygenSamples > 0;
}

/// Computes [HealthPatterns] from stored samples.
abstract final class HealthPatternsService {
  /// Fewer measured heart rates than this cannot support a resting estimate.
  static const int minimumHeartRateSamples = 4;

  /// The estimate must cover at least this many local days.
  static const int minimumDays = 2;

  /// A half-to-half difference smaller than this is called steady.
  static const int trendThresholdBpm = 3;

  /// Summarise [samples]. Order does not matter; samples are sorted by time.
  static HealthPatterns analyze(List<WatchSample> samples) {
    final List<WatchSample> measuredHeartRate = samples
        .where((WatchSample sample) => sample.hr > 0)
        .toList()
      ..sort((WatchSample a, WatchSample b) => a.unix.compareTo(b.unix));

    final int days = measuredHeartRate
        .map((WatchSample sample) => _dayKey(sample.at))
        .toSet()
        .length;

    final List<int> oxygen = samples
        .where((WatchSample sample) => sample.spo2 > 0)
        .map((WatchSample sample) => sample.spo2)
        .toList();

    final bool enough = measuredHeartRate.length >= minimumHeartRateSamples &&
        days >= minimumDays;

    if (!enough) {
      return HealthPatterns(
        sampleCount: samples.length,
        heartRateSamples: measuredHeartRate.length,
        daysWithHeartRate: days,
        restingHeartRate: 0,
        direction: HeartRateDirection.unknown,
        changeBpm: 0,
        lowestOxygen: oxygen.isEmpty ? 0 : oxygen.reduce(_lower),
        oxygenSamples: oxygen.length,
      );
    }

    final List<int> values = measuredHeartRate
        .map((WatchSample sample) => sample.hr)
        .toList()
      ..sort();

    // The lowest quarter is the quietest part of the record. Taking its mean
    // avoids letting one unusually calm minute define the whole estimate.
    final int quartileCount =
        (values.length / 4).ceil().clamp(1, values.length);
    final int quartileSum =
        values.take(quartileCount).fold(0, (int sum, int value) => sum + value);
    final int resting = (quartileSum / quartileCount).round();

    final int half = measuredHeartRate.length ~/ 2;
    final List<WatchSample> first = measuredHeartRate.sublist(0, half);
    final List<WatchSample> second = measuredHeartRate.sublist(half);
    final double firstMean = _mean(first);
    final double secondMean = _mean(second);
    final double difference = secondMean - firstMean;

    final HeartRateDirection direction;
    if (difference >= trendThresholdBpm) {
      direction = HeartRateDirection.rising;
    } else if (difference <= -trendThresholdBpm) {
      direction = HeartRateDirection.falling;
    } else {
      direction = HeartRateDirection.steady;
    }

    return HealthPatterns(
      sampleCount: samples.length,
      heartRateSamples: measuredHeartRate.length,
      daysWithHeartRate: days,
      restingHeartRate: resting,
      direction: direction,
      changeBpm: difference.round(),
      lowestOxygen: oxygen.isEmpty ? 0 : oxygen.reduce(_lower),
      oxygenSamples: oxygen.length,
    );
  }

  static double _mean(List<WatchSample> samples) {
    if (samples.isEmpty) return 0;
    final int total = samples.fold(0, (int sum, WatchSample sample) => sum + sample.hr);
    return total / samples.length;
  }

  static int _lower(int a, int b) => a < b ? a : b;

  static String _dayKey(DateTime time) =>
      '${time.year}-${time.month}-${time.day}';
}
