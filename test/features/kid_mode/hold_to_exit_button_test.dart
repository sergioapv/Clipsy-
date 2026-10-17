import 'package:clipsy/core/l10n/l10n.dart';
import 'package:clipsy/features/kid_mode/presentation/widgets/hold_to_exit_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<int Function()> pump(WidgetTester tester) async {
    var held = 0;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(
          body: Center(
            child: HoldToExitButton(
              holdDuration: const Duration(seconds: 3),
              onHeld: () => held++,
            ),
          ),
        ),
      ),
    );
    return () => held;
  }

  Future<void> hold(WidgetTester tester, Duration d) async {
    final g = await tester.startGesture(
      tester.getCenter(find.byKey(const Key('kid-exit-button'))),
    );
    await tester.pump();
    await tester.pump(d);
    // Animations complete on the frame after their duration.
    await tester.pump(const Duration(milliseconds: 16));
    await g.up();
    await tester.pumpAndSettle();
  }

  testWidgets('a single full hold fires', (tester) async {
    final held = await pump(tester);
    await hold(tester, const Duration(seconds: 3));
    expect(held(), 1);
  });

  testWidgets('fires only after the full hold', (tester) async {
    final held = await pump(tester);
    await tester.tap(find.byKey(const Key('kid-exit-button')));
    await tester.pumpAndSettle();
    expect(held(), 0);
    await hold(tester, const Duration(milliseconds: 2800));
    expect(held(), 0);
    await hold(tester, const Duration(seconds: 3));
    expect(held(), 1);
  });
}
