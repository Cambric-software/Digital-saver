import 'package:flutter_test/flutter_test.dart';

import 'package:digital_saver/services/local_store.dart';

void main() {
  test('watch samples round-trip through the history CSV format', () {
    final sample = WatchSample(
      unix: 1700000000,
      hr: 72,
      spo2: 98,
      bps: 120,
      bpd: 80,
      hrv: 44,
      steps: 1250,
      fall: true,
      bat: 76,
    );

    final parsed = WatchSample.parseCsv(sample.toCsv());

    expect(parsed, isNotNull);
    expect(parsed!.unix, sample.unix);
    expect(parsed.hr, sample.hr);
    expect(parsed.spo2, sample.spo2);
    expect(parsed.bps, sample.bps);
    expect(parsed.bpd, sample.bpd);
    expect(parsed.hrv, sample.hrv);
    expect(parsed.steps, sample.steps);
    expect(parsed.fall, isTrue);
    expect(parsed.bat, sample.bat);
  });

  test('invalid history rows are rejected', () {
    expect(WatchSample.parseCsv('not,a,health,row'), isNull);
    expect(WatchSample.parseCsv('0,72,98,120,80,44,1250,0,76'), isNotNull);
  });
}
