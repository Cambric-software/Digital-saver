/// Per-person appearance, accent and text-size behaviour.
///
/// These tests pin the promises the settings screen makes: a new person starts
/// from the defaults, every choice survives a restart, the text size is kept
/// inside the offered range, and the accent tints the theme without repainting
/// the surfaces or the warning colours.
library;

import 'package:digital_saver/core/services/app_theme_builder.dart';
import 'package:digital_saver/core/services/theme_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('a new person starts from the defaults, not the current settings',
      () async {
    final ThemeService service = ThemeService(loadStoredPreference: false);
    addTearDown(service.dispose);

    await service.setAccent(AppAccent.purple);
    await service.setTextScale(1.4);
    await service.setLanguage('ar');
    await service.setTheme(AppThemeMode.dark);
    await service.setHighContrast(true);

    final PersonProfile created = await service.addProfile('Sam');

    expect(service.activeProfileId, created.id);
    expect(service.accent, AppAccent.blue);
    expect(service.textScale, 1.0);
    expect(service.languageCode, 'en');
    expect(service.themeModeType, AppThemeMode.light);
    expect(service.highContrast, isFalse);

    await service.selectProfile(PersonProfile.defaults.id);
    expect(service.accent, AppAccent.purple);
    expect(service.textScale, 1.4);
    expect(service.languageCode, 'ar');
    expect(service.themeModeType, AppThemeMode.dark);
    expect(service.highContrast, isTrue);
  });

  test('the text size is clamped to the range the app offers', () async {
    final ThemeService service = ThemeService(loadStoredPreference: false);
    addTearDown(service.dispose);

    await service.setTextScale(0.1);
    expect(service.textScale, ThemeService.minTextScale);

    await service.setTextScale(9.0);
    expect(service.textScale, ThemeService.maxTextScale);
  });

  test('profiles and the active person survive a restart', () async {
    final ThemeService first = ThemeService(loadStoredPreference: false);
    await first.setAccent(AppAccent.amber);
    await first.setTextScale(1.25);
    await first.setLanguage('ar');
    await first.setHighContrast(true);
    await first.addProfile('Sam');
    first.dispose();

    final ThemeService second = ThemeService();
    addTearDown(second.dispose);
    await second.ready;

    expect(second.profiles.length, 2);
    expect(second.activeProfile.name, 'Sam');
    expect(second.languageCode, 'en');

    await second.selectProfile(PersonProfile.defaults.id);
    expect(second.accent, AppAccent.amber);
    expect(second.textScale, 1.25);
    expect(second.languageCode, 'ar');
    expect(second.highContrast, isTrue);
  });

  test('an existing language choice is carried into the first profile',
      () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'app_language': 'العربية',
    });
    final ThemeService service = ThemeService();
    addTearDown(service.dispose);
    await service.ready;

    expect(service.languageCode, 'ar');
    expect(service.isArabic, isTrue);
    expect(service.currentLanguage, 'العربية');
    expect(service.currentLocale, const Locale('ar'));
    expect(service.textDirection, TextDirection.rtl);
  });

  test('the last person cannot be deleted', () async {
    final ThemeService service = ThemeService(loadStoredPreference: false);
    addTearDown(service.dispose);

    expect(await service.deleteProfile(PersonProfile.defaults.id), isFalse);
    expect(service.profiles.length, 1);

    final PersonProfile second = await service.addProfile('Sam');
    expect(await service.deleteProfile(second.id), isTrue);
    expect(service.profiles.length, 1);
  });

  test('restore returns the active person to the defaults', () async {
    final ThemeService service = ThemeService(loadStoredPreference: false);
    addTearDown(service.dispose);

    await service.setAccent(AppAccent.green);
    await service.setTextScale(1.5);
    await service.setLanguage('ar');
    await service.setTheme(AppThemeMode.dark);
    await service.restoreDefaults();

    expect(service.activeProfile.name, PersonProfile.defaults.name);
    expect(service.accent, AppAccent.blue);
    expect(service.textScale, 1.0);
    expect(service.languageCode, 'en');
    expect(service.themeModeType, AppThemeMode.light);
  });

  test('the system text scale multiplies the app scale and stays bounded', () {
    expect(effectiveTextScale(1.0, 1.5), closeTo(1.5, 0.0001));
    expect(effectiveTextScale(1.3, 1.1), closeTo(1.43, 0.0001));
    expect(effectiveTextScale(2.0, 1.6), closeTo(3.0, 0.0001));
    expect(effectiveTextScale(0.0, 1.0), closeTo(1.0, 0.0001));
    expect(effectiveTextScale(double.nan, 1.0), closeTo(1.0, 0.0001));
  });

  test('the accent tints the primary colour but not the error colour', () {
    final ThemeData blue = buildAppTheme(
      brightness: Brightness.light,
      accent: AppAccent.blue,
      highContrast: false,
    );
    final ThemeData green = buildAppTheme(
      brightness: Brightness.light,
      accent: AppAccent.green,
      highContrast: false,
    );

    expect(blue.colorScheme.primary, isNot(green.colorScheme.primary));
    expect(blue.colorScheme.error, green.colorScheme.error);
    expect(blue.colorScheme.surface, green.colorScheme.surface);
  });

  test('high contrast strengthens borders without moving the surfaces', () {
    final ThemeData plain = buildAppTheme(
      brightness: Brightness.light,
      accent: AppAccent.blue,
      highContrast: false,
    );
    final ThemeData strong = buildAppTheme(
      brightness: Brightness.light,
      accent: AppAccent.blue,
      highContrast: true,
    );

    expect(strong.dividerTheme.thickness, 2.0);
    expect(plain.dividerTheme.thickness, 1.0);
    expect(strong.colorScheme.outline, isNot(plain.colorScheme.outline));
    expect(strong.colorScheme.surface, plain.colorScheme.surface);
    expect(strong.colorScheme.error, plain.colorScheme.error);
  });
}
