/// The clock rule and the persisted switch behind "Dim after dark".
///
/// The old dynamic-theme file guessed the weather from the month, which no
/// stored value could support. These tests pin the only rule that remains:
/// the local hour. They also check that an unreadable preference falls back to
/// the documented default rather than preventing the app from rendering.
library;

import 'package:digital_saver/services/dynamic_theme_service.dart';
import 'package:digital_saver/services/storage_service.dart';
import 'package:digital_saver/services/theme_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

ThemeService _serviceAt(int hour, {bool dim = false}) {
  final ThemeService service = ThemeService(
    dynamicTheme: DynamicThemeService(
      clock: () => DateTime(2026, 10, 20, hour),
    ),
    loadStoredPreference: false,
  );
  service.setDimAfterDark(dim);
  addTearDown(service.dispose);
  return service;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('the clock', () {
    test('daylight runs from 07:00 until 20:00', () {
      expect(DynamicThemeService.choiceForHour(7), LightChoice.light);
      expect(DynamicThemeService.choiceForHour(12), LightChoice.light);
      expect(DynamicThemeService.choiceForHour(19), LightChoice.light);
    });

    test('after dark starts at 20:00 and ends before 07:00', () {
      expect(DynamicThemeService.choiceForHour(20), LightChoice.dim);
      expect(DynamicThemeService.choiceForHour(23), LightChoice.dim);
      expect(DynamicThemeService.choiceForHour(0), LightChoice.dim);
      expect(DynamicThemeService.choiceForHour(6), LightChoice.dim);
    });

    test('an impossible hour is rejected rather than guessed', () {
      expect(
        () => DynamicThemeService.choiceForHour(24),
        throwsArgumentError,
      );
      expect(
        () => DynamicThemeService.choiceForHour(-1),
        throwsArgumentError,
      );
    });

    test('the next change is this morning before 07:00', () {
      final DynamicThemeService clock = DynamicThemeService();

      expect(
        clock.nextChangeAfter(DateTime(2026, 10, 20, 6, 30)),
        DateTime(2026, 10, 20, 7),
      );
    });

    test('the next change is tonight between 07:00 and 20:00', () {
      final DynamicThemeService clock = DynamicThemeService();

      expect(
        clock.nextChangeAfter(DateTime(2026, 10, 20, 7)),
        DateTime(2026, 10, 20, 20),
      );
      expect(
        clock.nextChangeAfter(DateTime(2026, 10, 20, 19, 59)),
        DateTime(2026, 10, 20, 20),
      );
    });

    test('the next change rolls to tomorrow after 20:00', () {
      final DynamicThemeService clock = DynamicThemeService();

      expect(
        clock.nextChangeAfter(DateTime(2026, 10, 20, 20)),
        DateTime(2026, 10, 21, 7),
      );
      expect(
        clock.nextChangeAfter(DateTime(2026, 10, 20, 23, 59)),
        DateTime(2026, 10, 21, 7),
      );
    });
  });

  group('the switch', () {
    test('is off by default and does nothing during the day', () async {
      final ThemeService service = _serviceAt(12);
      await service.ready;

      expect(service.dimAfterDark, StorageService.defaultDimAfterDark);
      expect(service.isDimmed, isFalse);
      expect(service.themeMode, ThemeMode.light);
      expect(service.lightChoice, LightChoice.light);
    });

    test('turns the dark theme on after dark, not before', () async {
      final ThemeService service = _serviceAt(21);
      expect(service.themeMode, ThemeMode.light);

      await service.setDimAfterDark(true);

      expect(service.dimAfterDark, isTrue);
      expect(service.isDimmed, isTrue);
      expect(service.themeMode, ThemeMode.dark);
      expect(await StorageService.dimAfterDark(), isTrue);
    });

    test('the clock alone cannot override a daytime choice', () async {
      final ThemeService service = _serviceAt(12);
      await service.setDimAfterDark(true);

      expect(service.isDimmed, isFalse);
      expect(service.themeMode, ThemeMode.light);
    });

    test('an explicit dark choice still works with the switch off', () {
      final ThemeService service = _serviceAt(21);
      service.setTheme(AppThemeMode.dark);

      expect(service.dimAfterDark, isFalse);
      expect(service.themeMode, ThemeMode.dark);
    });

    test('a stored switch is restored before the first frame', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'dim_after_dark': true,
      });
      final ThemeService service = ThemeService(
        dynamicTheme: DynamicThemeService(
          clock: () => DateTime(2026, 10, 20, 22),
        ),
      );
      addTearDown(service.dispose);

      await service.ready;

      expect(service.dimAfterDark, isTrue);
      expect(service.themeMode, ThemeMode.dark);
    });

    test('a corrupt stored value falls back to off', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'dim_after_dark': 'not a boolean',
      });
      final ThemeService service = ThemeService(
        dynamicTheme: DynamicThemeService(
          clock: () => DateTime(2026, 10, 20, 22),
        ),
      );
      addTearDown(service.dispose);

      await service.ready;

      expect(service.dimAfterDark, StorageService.defaultDimAfterDark);
      expect(service.themeMode, ThemeMode.light);
    });

    test('turning it off restores the chosen theme', () async {
      final ThemeService service = _serviceAt(22);
      await service.setDimAfterDark(true);
      expect(service.themeMode, ThemeMode.dark);

      await service.setDimAfterDark(false);

      expect(service.isDimmed, isFalse);
      expect(service.themeMode, ThemeMode.light);
      expect(await StorageService.dimAfterDark(), isFalse);
    });

    testWidgets('an app left open dims at 20:00 and brightens at 07:00',
        (WidgetTester tester) async {
      DateTime now = DateTime(2026, 10, 20, 19, 59);
      final ThemeService service = ThemeService(
        dynamicTheme: DynamicThemeService(clock: () => now),
        loadStoredPreference: false,
      );
      await service.setDimAfterDark(true);
      expect(service.themeMode, ThemeMode.light);

      int notifications = 0;
      service.addListener(() => notifications++);

      now = DateTime(2026, 10, 20, 20, 0, 30);
      await tester.pump(const Duration(minutes: 2));

      expect(service.isDimmed, isTrue);
      expect(service.themeMode, ThemeMode.dark);
      expect(notifications, 1);

      now = DateTime(2026, 10, 21, 7, 0, 30);
      await tester.pump(const Duration(hours: 11));

      expect(service.isDimmed, isFalse);
      expect(service.themeMode, ThemeMode.light);
      expect(notifications, 2);

      service.dispose();
    });

    testWidgets('turning the switch off stops the boundary wake-up',
        (WidgetTester tester) async {
      DateTime now = DateTime(2026, 10, 20, 19, 59);
      final ThemeService service = ThemeService(
        dynamicTheme: DynamicThemeService(clock: () => now),
        loadStoredPreference: false,
      );
      await service.setDimAfterDark(true);
      await service.setDimAfterDark(false);

      int notifications = 0;
      service.addListener(() => notifications++);

      now = DateTime(2026, 10, 20, 20, 0, 30);
      await tester.pump(const Duration(minutes: 2));

      expect(notifications, 0);
      expect(service.themeMode, ThemeMode.light);

      service.dispose();
    });
  });
}
