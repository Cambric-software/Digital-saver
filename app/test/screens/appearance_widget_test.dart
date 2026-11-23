/// The two appearance choices a person can see immediately: language and size.
///
/// The settings screen writes these values; this test renders the same
/// `MaterialApp` wiring `main.dart` uses, so a change is checked in the tree
/// rather than only in the service.
library;

import 'package:digital_saver/core/localization/app_strings.dart';
import 'package:digital_saver/core/services/app_theme_builder.dart';
import 'package:digital_saver/core/services/theme_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _app(ThemeService service) {
  return ChangeNotifierProvider<ThemeService>.value(
    value: service,
    child: Consumer<ThemeService>(
      builder: (BuildContext context, ThemeService theme, Widget? _) {
        return MaterialApp(
          locale: theme.currentLocale,
          supportedLocales: const <Locale>[
            Locale('en'),
            Locale('ar'),
          ],
          localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: buildAppTheme(
            brightness: Brightness.light,
            accent: theme.accent,
            highContrast: theme.highContrast,
          ),
          builder: (BuildContext context, Widget? child) {
            final MediaQueryData media = MediaQuery.of(context);
            return MediaQuery(
              data: media.copyWith(
                textScaler: TextScaler.linear(
                  effectiveTextScale(
                    media.textScaler.scale(1.0),
                    theme.textScale,
                  ),
                ),
              ),
              child: Directionality(
                textDirection: theme.textDirection,
                child: child ?? const SizedBox(),
              ),
            );
          },
          home: Builder(
            builder: (BuildContext context) => Scaffold(
              body: Text(AppStrings.of(context).text('settings.title')),
            ),
          ),
        );
      },
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('Arabic switches the interface and reads right to left',
      (WidgetTester tester) async {
    final ThemeService service = ThemeService(loadStoredPreference: false);
    addTearDown(service.dispose);
    await service.setLanguage('ar');

    await tester.pumpWidget(_app(service));
    await tester.pumpAndSettle();

    expect(find.text('الإعدادات'), findsOneWidget);
    final BuildContext context = tester.element(find.text('الإعدادات'));
    expect(Directionality.of(context), TextDirection.rtl);
  });

  testWidgets('the text size setting scales the interface',
      (WidgetTester tester) async {
    final ThemeService service = ThemeService(loadStoredPreference: false);
    addTearDown(service.dispose);
    await service.setTextScale(1.5);

    await tester.pumpWidget(_app(service));
    await tester.pumpAndSettle();

    final BuildContext context = tester.element(find.text('Settings'));
    expect(MediaQuery.textScalerOf(context).scale(10), closeTo(15, 0.01));
  });
}
