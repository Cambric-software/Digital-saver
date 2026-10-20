/// Tests for the daily counters and short entries.
///
/// The point of this service is that a value belongs to one day and one owner.
/// These tests pin the round trips, the day boundary and the fallbacks, so a
/// change that silently turns "nothing logged" into an exception or into
/// yesterday's count fails here rather than on the phone.
library;

import 'package:digital_saver/services/daily_log.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final DateTime monday = DateTime(2026, 10, 19, 8, 30);
  final DateTime tuesday = DateTime(2026, 10, 20, 9, 15);

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('an untouched day reports zero and nothing', () async {
    expect(await DailyLog.counter(DailyLog.hydrationGlasses, now: monday), 0);
    expect(await DailyLog.entry(DailyLog.mood, now: monday), isNull);
    expect(await DailyLog.time(DailyLog.fastingStart, now: monday), isNull);
    expect(await DailyLog.strideCm(), isNull);
    expect(await DailyLog.fastingPlan(), isNull);
  });

  test('counters round-trip and negative values become zero', () async {
    await DailyLog.setCounter(DailyLog.hydrationGlasses, 3, now: monday);
    await DailyLog.setCounter(DailyLog.coffees, 2, now: monday);

    expect(await DailyLog.counter(DailyLog.hydrationGlasses, now: monday), 3);
    expect(await DailyLog.counter(DailyLog.coffees, now: monday), 2);

    await DailyLog.setCounter(DailyLog.coffees, -4, now: monday);
    expect(await DailyLog.counter(DailyLog.coffees, now: monday), 0);
  });

  test('entries round-trip and an empty entry removes the value', () async {
    await DailyLog.setEntry(DailyLog.mood, '  Good  ', now: monday);
    expect(await DailyLog.entry(DailyLog.mood, now: monday), 'Good');

    await DailyLog.setEntry(DailyLog.mood, '   ', now: monday);
    expect(await DailyLog.entry(DailyLog.mood, now: monday), isNull);
  });

  test('timestamps round-trip and can be cleared', () async {
    await DailyLog.setTime(DailyLog.fastingStart, monday, now: monday);
    expect(await DailyLog.time(DailyLog.fastingStart, now: monday), monday);

    await DailyLog.setTime(DailyLog.fastingStart, null, now: monday);
    expect(await DailyLog.time(DailyLog.fastingStart, now: monday), isNull);
  });

  test('each day is isolated from the next', () async {
    await DailyLog.setCounter(DailyLog.hydrationGlasses, 6, now: monday);
    await DailyLog.setEntry(DailyLog.mood, 'Tired', now: monday);
    await DailyLog.setTime(DailyLog.lastCoffee, monday, now: monday);

    expect(await DailyLog.counter(DailyLog.hydrationGlasses, now: tuesday), 0);
    expect(await DailyLog.entry(DailyLog.mood, now: tuesday), isNull);
    expect(await DailyLog.time(DailyLog.lastCoffee, now: tuesday), isNull);

    // Writing Tuesday does not disturb Monday.
    await DailyLog.setCounter(DailyLog.hydrationGlasses, 1, now: tuesday);
    expect(await DailyLog.counter(DailyLog.hydrationGlasses, now: monday), 6);
  });

  test('an effort rating and its note are stored with the day', () async {
    await DailyLog.setCounter(DailyLog.rpe, 7, now: monday);
    await DailyLog.setEntry(DailyLog.rpeNote, 'Steady until the last lap',
        now: monday);

    expect(await DailyLog.counter(DailyLog.rpe, now: monday), 7);
    expect(
      await DailyLog.entry(DailyLog.rpeNote, now: monday),
      'Steady until the last lap',
    );

    // The next day starts with nothing logged.
    expect(await DailyLog.counter(DailyLog.rpe, now: tuesday), 0);
    expect(await DailyLog.entry(DailyLog.rpeNote, now: tuesday), isNull);
  });

  test('a corrupt day reads as empty instead of throwing', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'daily_log_2026-10-20': 'this is not json',
    });

    expect(await DailyLog.counter(DailyLog.hydrationGlasses, now: tuesday), 0);
    expect(await DailyLog.entry(DailyLog.mood, now: tuesday), isNull);
    expect(await DailyLog.time(DailyLog.fastingStart, now: tuesday), isNull);
  });

  test('values of the wrong type are skipped, readable ones kept', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'daily_log_2026-10-20': '{"counters":{"hydration_glasses":"three",'
          '"coffees":2},"entries":{"mood":42,"mood_tags":"Busy day"},'
          '"times":{"fasting_start":7,"last_coffee":"2026-10-20T08:00:00"}}',
    });

    expect(await DailyLog.counter(DailyLog.hydrationGlasses, now: tuesday), 0);
    expect(await DailyLog.counter(DailyLog.coffees, now: tuesday), 2);
    expect(await DailyLog.entry(DailyLog.mood, now: tuesday), isNull);
    expect(
      await DailyLog.entry(DailyLog.moodTags, now: tuesday),
      'Busy day',
    );
    expect(await DailyLog.time(DailyLog.fastingStart, now: tuesday), isNull);
    expect(
      await DailyLog.time(DailyLog.lastCoffee, now: tuesday),
      DateTime(2026, 10, 20, 8),
    );
  });

  test('a section that is not an object is ignored', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'daily_log_2026-10-20': '{"counters":[],"entries":"nope"}',
    });

    expect(await DailyLog.counter(DailyLog.coffees, now: tuesday), 0);
    expect(await DailyLog.entry(DailyLog.mood, now: tuesday), isNull);
  });

  test('clearing one day leaves the other days alone', () async {
    await DailyLog.setCounter(DailyLog.hydrationGlasses, 6, now: monday);
    await DailyLog.setCounter(DailyLog.hydrationGlasses, 2, now: tuesday);

    await DailyLog.clearDay(now: tuesday);

    expect(await DailyLog.counter(DailyLog.hydrationGlasses, now: tuesday), 0);
    expect(await DailyLog.counter(DailyLog.hydrationGlasses, now: monday), 6);
  });

  test('stride and fasting plan are stored preferences, not daily values',
      () async {
    await DailyLog.setStrideCm(76.5);
    await DailyLog.setFastingPlan('18:6');

    // A different day still sees them: they describe the person, not the day.
    expect(await DailyLog.strideCm(), 76.5);
    expect(await DailyLog.fastingPlan(), '18:6');

    await DailyLog.setStrideCm(null);
    await DailyLog.setFastingPlan(null);
    expect(await DailyLog.strideCm(), isNull);
    expect(await DailyLog.fastingPlan(), isNull);
  });

  test('an implausible or unreadable stride is treated as unset', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'daily_log_setting_stride_cm': 'wide',
    });
    expect(await DailyLog.strideCm(), isNull);

    SharedPreferences.setMockInitialValues(<String, Object>{
      'daily_log_setting_stride_cm': '5',
    });
    expect(await DailyLog.strideCm(), isNull);
  });

  test('clear forgets every day and every preference it owns', () async {
    await DailyLog.setCounter(DailyLog.hydrationGlasses, 6, now: monday);
    await DailyLog.setEntry(DailyLog.mood, 'Good', now: monday);
    await DailyLog.setCounter(DailyLog.breaks, 2, now: tuesday);
    await DailyLog.setStrideCm(72);
    await DailyLog.setFastingPlan('16:8');

    await DailyLog.clear();

    expect(await DailyLog.counter(DailyLog.hydrationGlasses, now: monday), 0);
    expect(await DailyLog.entry(DailyLog.mood, now: monday), isNull);
    expect(await DailyLog.counter(DailyLog.breaks, now: tuesday), 0);
    expect(await DailyLog.strideCm(), isNull);
    expect(await DailyLog.fastingPlan(), isNull);
  });
}
