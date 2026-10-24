import 'package:digital_saver/features/screens/lock_screen.dart';
import 'package:digital_saver/core/services/app_lock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tests that a set PIN actually keeps the app shut.
///
/// The lock used to be stored and never asked for: Settings could set a PIN,
/// AppLock verified it correctly, and the app opened without it. These tests
/// wrap content in the real gate, so "the PIN works" means the content is not
/// reachable until it is entered.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  Future<AppLock> loadedLock() async {
    final AppLock lock = AppLock();
    await lock.load();
    return lock;
  }

  Widget gate(AppLock lock) {
    return ChangeNotifierProvider<AppLock>.value(
      value: lock,
      child: const MaterialApp(
        home: LockGate(child: Text('app content')),
      ),
    );
  }

  Future<void> pumpGate(WidgetTester tester, AppLock lock) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(gate(lock));
    await tester.pump();
  }

  testWidgets('with no PIN set, the app opens normally', (tester) async {
    final AppLock lock = await loadedLock();
    expect(lock.hasLock, isFalse);

    await pumpGate(tester, lock);

    expect(find.text('app content'), findsOneWidget);
    expect(find.text('Digital Saver is locked'), findsNothing);
  });

  testWidgets('a set PIN hides the app until it is entered', (tester) async {
    final AppLock lock = await loadedLock();
    await lock.setPin('123456');
    await lock.lockNow();

    await pumpGate(tester, lock);

    // The shell must not be built while the lock is shut.
    expect(find.text('app content'), findsNothing);
    expect(find.text('Digital Saver is locked'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '123456');
    await tester.tap(find.text('Unlock'));
    await tester.pumpAndSettle();

    expect(find.text('app content'), findsOneWidget);
    expect(find.text('Digital Saver is locked'), findsNothing);
  });

  testWidgets('a wrong PIN says so and clears the field', (tester) async {
    final AppLock lock = await loadedLock();
    await lock.setPin('123456');
    await lock.lockNow();

    await pumpGate(tester, lock);

    await tester.enterText(find.byType(TextField), '000000');
    await tester.tap(find.text('Unlock'));
    await tester.pumpAndSettle();

    expect(find.text('That PIN is not right.'), findsOneWidget);
    expect(find.text('app content'), findsNothing);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
  });

  testWidgets('a PIN of the wrong length is refused before it is checked',
      (tester) async {
    final AppLock lock = await loadedLock();
    await lock.setPin('123456');
    await lock.lockNow();

    await pumpGate(tester, lock);

    await tester.enterText(find.byType(TextField), '123');
    await tester.tap(find.text('Unlock'));
    await tester.pump();

    expect(find.text('The PIN is six digits.'), findsOneWidget);
    expect(find.text('app content'), findsNothing);
  });

  testWidgets('locking again requires the PIN again', (tester) async {
    final AppLock lock = await loadedLock();
    await lock.setPin('123456');

    await pumpGate(tester, lock);
    expect(find.text('app content'), findsOneWidget);

    await lock.lockNow();
    await tester.pump();

    expect(find.text('app content'), findsNothing);
    expect(find.text('Digital Saver is locked'), findsOneWidget);
  });

  testWidgets('the lock screen is usable at a phone width', (tester) async {
    final AppLock lock = await loadedLock();
    await lock.setPin('123456');
    await lock.lockNow();

    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(gate(lock));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
