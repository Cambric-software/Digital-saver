/// What a reading means, in one place.
///
/// Every screen that shows a number needs to decide whether it is normal,
/// elevated, high or critical. When each screen made that decision for itself,
/// the same heart rate could read as healthy on one screen and alarming on
/// another, which is worse than either being wrong on its own - someone cannot
/// tell which screen to believe.
///
/// So the thresholds live here, once, and every screen asks this module.
///
/// These are screening cues, not diagnoses. They exist to prompt someone to
/// look again or contact a clinician, never to tell them what is wrong. Ranges
/// are the commonly cited adult screening bounds; individual baselines differ,
/// and a trained clinician reading the same number may reasonably interpret it
/// differently. [interpretHeartRateAgainstBaseline] exists for that reason:
/// where a personal resting baseline is known, deviating from it matters more
/// than crossing a population threshold.
library;

import '../../../core/models/health_models.dart';
import 'package:cambric_design/cambric_design.dart';

/// A reading at or below this is "no data", not a measurement.
///
/// The watch reports 0 for every sensor until it has a reading. Rendering that
/// as "0 BPM" or "0%" invites someone to act on a number the device never
/// sent, which is the specific failure this guards against.
const int kNoReading = 0;

/// Whether a heart rate value is an actual measurement.
bool hasHeartRate(int bpm) => bpm > kNoReading;

/// Whether a blood pressure pair is an actual measurement.
bool hasBloodPressure(BloodPressureData bp) =>
    bp.systolic > kNoReading && bp.diastolic > kNoReading;

/// Whether an oxygen saturation value is an actual measurement.
bool hasOxygen(int spo2) => spo2 > kNoReading;

// ── Heart rate ─────────────────────────────────────────────────────────

/// Resting band for an adult, used when no personal baseline is known.
const int kRestingLowBpm = 50;
const int kRestingHighBpm = 100;
const int kBradycardiaFloorBpm = 40;
const int kTachycardiaCeilingBpm = 180;
const int kElevatedLowBpm = 60;
const int kElevatedHighBpm = 120;

/// How far from a personal resting baseline counts as raised or high.
const int kBaselineElevatedDeviationBpm = 12;
const int kBaselineHighDeviationBpm = 25;

/// Classify a heart rate in BPM.
///
/// The bands step up rather than jumping straight to the worst case, so the
/// interface can distinguish "slightly raised" from "worth acting on" instead
/// of treating every abnormal number as an emergency.
HealthStatus interpretHeartRate(int bpm) {
  if (!hasHeartRate(bpm)) return HealthStatus.unknown;
  if (bpm < kBradycardiaFloorBpm || bpm > kTachycardiaCeilingBpm) {
    return HealthStatus.critical;
  }
  if (bpm < kRestingLowBpm || bpm > kElevatedHighBpm) return HealthStatus.high;
  if (bpm > kRestingHighBpm) return HealthStatus.elevated;
  return HealthStatus.normal;
}

/// Classify a heart rate against the wearer's own resting baseline.
///
/// A resting rate of 52 is unremarkable for someone whose baseline is 50 and
/// worth a second look for someone whose baseline is 70. Population thresholds
/// cannot tell those apart; a personal baseline can, so it is preferred when
/// one is known.
///
/// Named separately rather than as an optional argument on [interpretHeartRate]
/// because the two answer different questions, and a caller should have to say
/// which one they mean. Passing no baseline returns the population check.
HealthStatus interpretHeartRateAgainstBaseline(int bpm, {required int restingBpm}) {
  final byPopulation = interpretHeartRate(bpm);
  if (restingBpm <= kNoReading || !hasHeartRate(bpm)) {
    return byPopulation;
  }

  // Critical first. A reading far outside any plausible range must not be
  // softened by the baseline logic below - someone with a resting rate of 65
  // and a live reading of 190 needs to know that regardless of their baseline.
  if (byPopulation == HealthStatus.critical) return HealthStatus.critical;

  final deviation = (bpm - _safeResting(restingBpm)).abs();
  if (deviation >= kBaselineHighDeviationBpm) return HealthStatus.high;
  if (deviation >= kBaselineElevatedDeviationBpm) return HealthStatus.elevated;

  return HealthStatus.normal;
}

/// Guards against dividing by a zero or negative baseline.
int _safeResting(int restingBpm) => restingBpm > 0 ? restingBpm : 1;

// ── Blood pressure ─────────────────────────────────────────────────────

const int kSystolicElevated = 130;
const int kSystolicStage1 = 140;
const int kSystolicCrisis = 180;
const int kDiastolicElevated = 85;
const int kDiastolicStage1 = 90;
const int kDiastolicCrisis = 120;

/// Classify a blood pressure reading.
///
/// A single measurement is not a diagnosis of hypertension, and saying so in
/// the interface would be wrong. It is graded so someone knows whether it is
/// unremarkable, worth repeating, or worth acting on now.
HealthStatus interpretBloodPressure(BloodPressureData bp) {
  if (!hasBloodPressure(bp)) return HealthStatus.unknown;
  if (bp.systolic >= kSystolicCrisis || bp.diastolic >= kDiastolicCrisis) {
    return HealthStatus.critical;
  }
  if (bp.systolic >= kSystolicStage1 || bp.diastolic >= kDiastolicStage1) {
    return HealthStatus.high;
  }
  if (bp.systolic >= kSystolicElevated || bp.diastolic >= kDiastolicElevated) {
    return HealthStatus.elevated;
  }
  return HealthStatus.normal;
}

/// Blood pressure as it should be displayed, or dashes when there is none.
String formatBloodPressure(BloodPressureData bp) {
  if (!hasBloodPressure(bp)) return '--';
  return '${bp.systolic}/${bp.diastolic}';
}

// ── Oxygen ────────────────────────────────────────────────────────────

const int kOxygenElevated = 95;
const int kOxygenHigh = 93;
const int kOxygenCritical = 90;

/// Classify oxygen saturation as a percentage.
///
/// The bands are inclusive at the lower edge of each: 95 is treated as
/// borderline rather than comfortably normal, because the difference between
/// 95 and 94 is a rounding matter in the sensor, not a real change in the
/// person.
HealthStatus interpretOxygen(int spo2) {
  if (!hasOxygen(spo2)) return HealthStatus.unknown;
  if (spo2 < kOxygenCritical) return HealthStatus.critical;
  if (spo2 <= kOxygenHigh) return HealthStatus.high;
  if (spo2 <= kOxygenElevated) return HealthStatus.elevated;
  return HealthStatus.normal;
}

// ── Atrial fibrillation probability ────────────────────────────────────

const int kAfibElevated = 25;
const int kAfibHigh = 60;

/// Classify the watch's atrial fibrillation probability.
///
/// This is a screening signal from a wrist sensor, which is not accurate enough
/// to diagnose atrial fibrillation. The wording used with it says "worth
/// checking", never "you have".
HealthStatus interpretAfib(int probability) {
  if (probability <= kNoReading) return HealthStatus.unknown;
  if (probability >= kAfibHigh) return HealthStatus.high;
  if (probability >= kAfibElevated) return HealthStatus.elevated;
  return HealthStatus.normal;
}

// ── Recovery ───────────────────────────────────────────────────────────

const int kLowHrvMs = 20;

/// Whether a low HRV reading is worth mentioning.
///
/// A single low HRV reading is not meaningful - it varies hour to hour with
/// stress, illness, alcohol and sleep. It is flagged, never acted upon.
bool isRecoveryLow({required int hrv, required int restingHrv}) {
  if (hrv <= kNoReading) return false;
  if (restingHrv > kNoReading) return hrv < restingHrv * 0.7;
  return hrv < kLowHrvMs;
}

// ── Presentation ───────────────────────────────────────────────────────

/// Short guidance for a status, phrased as a next step rather than a verdict.
///
/// Deliberately avoids the words "healthy", "normal" and "abnormal". Telling
/// someone their reading is normal is a medical judgement this app is not
/// placed to make; "in the usual range" is a description of the number.
String? guidanceFor(HealthStatus status, String metric) {
  switch (status) {
    case HealthStatus.normal:
      return null;
    case HealthStatus.elevated:
      return 'Slightly outside the usual range for $metric. '
          'Worth another reading in a few minutes.';
    case HealthStatus.high:
      return 'Outside the usual range for $metric. Worth mentioning to a '
          'clinician if it persists.';
    case HealthStatus.critical:
      return 'Well outside the usual range for $metric. If you feel unwell, '
          'contact a clinician or emergency services now.';
    case HealthStatus.unknown:
      return null;
  }
}