import 'package:digital_saver/core/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tests for the stored settings and records.
///
/// The point of this service is that a key and its default exist once. These
/// tests pin the defaults and the round trips, so a change to one side without
/// the other fails here rather than in the app as a switch that forgets.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('every setting reports its documented default when nothing is stored',
      () async {
    expect(await StorageService.demoMode(), StorageService.defaultDemoMode);
    expect(await StorageService.watchFace(), StorageService.defaultWatchFace);
    expect(
      await StorageService.autoSyncHistory(),
      StorageService.defaultAutoSyncHistory,
    );
    expect(
      await StorageService.highHrThreshold(),
      StorageService.defaultHighHrThreshold,
    );
    expect(
      await StorageService.lowSpo2Threshold(),
      StorageService.defaultLowSpo2Threshold,
    );
    expect(
      await StorageService.complicationTop(),
      StorageService.defaultComplicationTop,
    );
    expect(
      await StorageService.complicationBottom(),
      StorageService.defaultComplicationBottom,
    );
    expect(await StorageService.quickReplies(),
        StorageService.defaultQuickReplies);
    expect(await StorageService.breathHoldBest(),
        StorageService.defaultBreathHoldBest);
    expect(await StorageService.reflections(), isEmpty);
    expect(await StorageService.medications(), isEmpty);
    expect(
      await StorageService.dimAfterDark(),
      StorageService.defaultDimAfterDark,
    );
  });

  test('each setting round-trips', () async {
    await StorageService.setDemoMode(true);
    await StorageService.setWatchFace(3);
    await StorageService.setAutoSyncHistory(false);
    await StorageService.setHighHrThreshold(135.5);
    await StorageService.setLowSpo2Threshold(88.5);
    await StorageService.setComplicationTop('Battery Level');
    await StorageService.setComplicationBottom('Steps');
    await StorageService.setQuickReplies(<String>['Yes', 'No']);
    await StorageService.setDimAfterDark(true);

    expect(await StorageService.demoMode(), isTrue);
    expect(await StorageService.watchFace(), 3);
    expect(await StorageService.autoSyncHistory(), isFalse);
    expect(await StorageService.highHrThreshold(), 135.5);
    expect(await StorageService.lowSpo2Threshold(), 88.5);
    expect(await StorageService.complicationTop(), 'Battery Level');
    expect(await StorageService.complicationBottom(), 'Steps');
    expect(await StorageService.quickReplies(), <String>['Yes', 'No']);
    expect(await StorageService.dimAfterDark(), isTrue);
  });

  test('a non-boolean dim preference reads as the default', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'dim_after_dark': 'yes please',
    });
    expect(
      await StorageService.dimAfterDark(),
      StorageService.defaultDimAfterDark,
    );
  });

  test('a cleared quick-reply list falls back to the defaults', () async {
    // An empty list would leave someone with no replies and no way to add one
    // back from the watch, so it is treated as "not set".
    await StorageService.setQuickReplies(<String>[]);
    expect(await StorageService.quickReplies(),
        StorageService.defaultQuickReplies);
  });

  test('a reflection is stored against the day it was written', () async {
    final DateTime day = DateTime(2026, 10, 20);
    await StorageService.saveReflection(
      'Walked before work.',
      now: day,
    );

    final Reflection? today = await StorageService.todayReflection(now: day);
    expect(today, isNotNull);
    expect(today!.text, 'Walked before work.');
    expect(today.date, '2026-10-20');

    // A different day has nothing.
    expect(
      await StorageService.todayReflection(now: DateTime(2026, 10, 21)),
      isNull,
    );
  });

  test('writing twice on the same day replaces the entry', () async {
    final DateTime day = DateTime(2026, 10, 20);
    await StorageService.saveReflection('First thought.', now: day);
    await StorageService.saveReflection('Second thought.', now: day);

    final List<Reflection> all = await StorageService.reflections();
    expect(all, hasLength(1));
    expect(all.single.text, 'Second thought.');
  });

  test('the log keeps the newest entries and drops the oldest', () async {
    for (int i = 0; i < StorageService.maxReflections + 5; i++) {
      await StorageService.saveReflection(
        'entry $i',
        now: DateTime(2026, 1, 1).add(Duration(days: i)),
      );
    }
    final List<Reflection> all = await StorageService.reflections();
    expect(all, hasLength(StorageService.maxReflections));
    // Newest first.
    expect(all.first.text, 'entry ${StorageService.maxReflections + 4}');
    expect(all.last.text, 'entry 5');
  });

  test('an empty reflection is not stored', () async {
    await StorageService.saveReflection('   ');
    expect(await StorageService.reflections(), isEmpty);
  });

  test('a corrupt reflection log is survived, not thrown', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'reflections': 'this is not json',
    });
    expect(await StorageService.reflections(), isEmpty);
  });

  test('unreadable entries are skipped and the readable ones kept', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'reflections':
          '[{"date":"2026-10-20","text":"kept"},{"date":42},{"nope":true}]',
    });
    final List<Reflection> all = await StorageService.reflections();
    expect(all, hasLength(1));
    expect(all.single.text, 'kept');
  });

  test('a breath hold is only recorded when it beats the best', () async {
    expect(await StorageService.recordBreathHold(30), 30);
    expect(await StorageService.breathHoldBest(), 30);

    // A shorter attempt leaves the best alone and says so by returning it.
    expect(await StorageService.recordBreathHold(20), 30);
    expect(await StorageService.breathHoldBest(), 30);

    expect(await StorageService.recordBreathHold(45), 45);
    expect(await StorageService.breathHoldBest(), 45);
  });

  test('the medication list round-trips in order', () async {
    await StorageService.setMedications(const <Medication>[
      Medication(name: 'Vitamin D3', dose: '2000 IU'),
      Medication(name: 'Magnesium glycinate'),
    ]);

    final List<Medication> stored = await StorageService.medications();
    expect(stored, hasLength(2));
    expect(stored.first.name, 'Vitamin D3');
    expect(stored.first.dose, '2000 IU');
    expect(stored.last.name, 'Magnesium glycinate');
    expect(stored.last.dose, isEmpty);
  });

  test('unreadable medications are skipped and the readable ones kept',
      () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'medications': '[{"name":"Iron","dose":"50 mg"},{"name":"  "},{},'
          '{"name":42},{"dose":"1 tab"}]',
    });

    final List<Medication> stored = await StorageService.medications();
    expect(stored, hasLength(1));
    expect(stored.single.name, 'Iron');
    expect(stored.single.dose, '50 mg');
  });

  test('a corrupt medication list reads as empty', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'medications': 'this is not json',
    });
    expect(await StorageService.medications(), isEmpty);
  });

  test('an empty medication list is stored as empty, not as a default',
      () async {
    await StorageService.setMedications(const <Medication>[]);
    expect(await StorageService.medications(), isEmpty);
  });

  test('clear forgets what this service owns', () async {
    await StorageService.setDemoMode(true);
    await StorageService.saveReflection('note');
    await StorageService.recordBreathHold(60);
    await StorageService.setMedications(const <Medication>[
      Medication(name: 'Iron'),
    ]);
    await StorageService.setDimAfterDark(true);

    await StorageService.clear();

    expect(await StorageService.demoMode(), StorageService.defaultDemoMode);
    expect(await StorageService.reflections(), isEmpty);
    expect(await StorageService.breathHoldBest(),
        StorageService.defaultBreathHoldBest);
    expect(await StorageService.medications(), isEmpty);
    expect(
      await StorageService.dimAfterDark(),
      StorageService.defaultDimAfterDark,
    );
  });
}
