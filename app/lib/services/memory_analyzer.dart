import 'local_store.dart';
import 'veyro_protocol.dart';

class MemoryReport {
  final int samples;
  final DateTime? first;
  final DateTime? last;
  final DateTime deletesAfter;
  final int avgHr;
  final int minHr;
  final int maxHr;
  final int avgSpo2;
  final int restHr;
  final int falls;
  final int lastSteps;
  final List<String> notes;

  MemoryReport({
    required this.samples,
    required this.first,
    required this.last,
    required this.deletesAfter,
    required this.avgHr,
    required this.minHr,
    required this.maxHr,
    required this.avgSpo2,
    required this.restHr,
    required this.falls,
    required this.lastSteps,
    required this.notes,
  });
}

class MemoryAnalyzer {
  static MemoryReport analyze(List<WatchSample> samples) {
    final now = DateTime.now();
    final deletesAfter = now.add(const Duration(days: VeyroProtocol.retainDays));
    if (samples.isEmpty) {
      return MemoryReport(
        samples: 0,
        first: null,
        last: null,
        deletesAfter: deletesAfter,
        avgHr: 0,
        minHr: 0,
        maxHr: 0,
        avgSpo2: 0,
        restHr: 0,
        falls: 0,
        lastSteps: 0,
        notes: [
          'No watch memory yet. Connect Veyro. It stores one sample a minute while it sees a pulse or steps.',
          'Samples older than ${VeyroProtocol.retainDays} days are deleted on the watch and on this phone. That is normal, not data loss.',
        ],
      );
    }

    final hrs = samples.where((s) => s.hr >= 40 && s.hr <= 180).map((s) => s.hr).toList()..sort();
    final o2s = samples.where((s) => s.spo2 >= 80).map((s) => s.spo2).toList();
    final avgHr = hrs.isEmpty ? 0 : hrs.reduce((a, b) => a + b) ~/ hrs.length;
    final rest = hrs.isEmpty ? 0 : hrs[hrs.length ~/ 10];
    final avgO2 = o2s.isEmpty ? 0 : o2s.reduce((a, b) => a + b) ~/ o2s.length;
    final falls = samples.where((s) => s.fall).length;
    samples.sort((a, b) => a.unix.compareTo(b.unix));

    final notes = <String>[];
    notes.add('${samples.length} samples from ${samples.first.at.toLocal()} to ${samples.last.at.toLocal()}.');
    notes.add('Anything older than ${VeyroProtocol.retainDays} days is wiped automatically to keep flash free.');
    if (avgHr > 0) {
      notes.add('Average heart rate while sampled: $avgHr bpm. Night/rest estimate: $rest bpm.');
    } else {
      notes.add('Heart rate is empty in the log. The MAX30102 needs skin contact and a finger or wrist that is not moving too much.');
    }
    if (avgO2 > 0) {
      notes.add('Average SpO2 estimate: $avgO2%. Optical SpO2 on this chip is a trend, not a hospital reading.');
    }
    if (falls > 0) {
      notes.add('$falls fall/SOS flags. Confirm with the wearer — the IMU false-triggers on sports.');
    }
    if (samples.last.steps > 0) {
      notes.add('Last step count on the watch: ${samples.last.steps} (resets when the watch reboots unless you add a later firmware).');
    }
    if (hrs.length >= 20) {
      final spread = hrs.last - hrs.first;
      if (spread > 50) {
        notes.add('Heart rate varied a lot ($spread bpm range). That is often motion or a loose strap, not an illness.');
      }
    }

    return MemoryReport(
      samples: samples.length,
      first: samples.first.at,
      last: samples.last.at,
      deletesAfter: samples.first.at.add(const Duration(days: VeyroProtocol.retainDays)),
      avgHr: avgHr,
      minHr: hrs.isEmpty ? 0 : hrs.first,
      maxHr: hrs.isEmpty ? 0 : hrs.last,
      avgSpo2: avgO2,
      restHr: rest,
      falls: falls,
      lastSteps: samples.last.steps,
      notes: notes,
    );
  }
}
