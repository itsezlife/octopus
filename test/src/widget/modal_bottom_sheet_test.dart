import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octopus/octopus.dart';

import 'fake_routes.dart';
import 'tester_extension.dart';

void main() => group('showModalBottomSheet', () {
      testWidgets('Navigator.pop completes future with result', (tester) async {
        final octopus = Octopus(routes: FakeRoutes.values);
        await tester.pumpApp(octopus);

        final future = octopus.showModalBottomSheet<int>(
          builder: (context) => Center(
            child: TextButton(
              key: const Key('sheet-pop'),
              onPressed: () => Navigator.pop(context, 42),
              child: const Text('Pop'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('sheet-pop')), findsOneWidget);
        expect(
          octopus.observer.value.children.any((n) => n.name == 'm'),
          isTrue,
        );

        await tester.tap(find.byKey(const Key('sheet-pop')));
        await tester.pumpAndSettle();

        expect(await future, 42);
        expect(
          octopus.observer.value.children.any((n) => n.name == 'm'),
          isFalse,
        );
      });

      testWidgets('barrier dismiss completes future with null', (tester) async {
        final octopus = Octopus(routes: FakeRoutes.values);
        await tester.pumpApp(octopus);

        final future = octopus.showModalBottomSheet<int>(
          isDismissible: true,
          builder: (context) => const SizedBox(
            height: 200,
            child: Center(child: Text('Sheet')),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Sheet'), findsOneWidget);

        // Tap the modal barrier (above the sheet content).
        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();

        expect(await future, isNull);
        expect(
          octopus.observer.value.children.any((n) => n.name == 'm'),
          isFalse,
        );
      });

      testWidgets('sequential sheets do not hang completers', (tester) async {
        final octopus = Octopus(routes: FakeRoutes.values);
        await tester.pumpApp(octopus);

        Future<int?> openAndClose(int value) async {
          final future = octopus.showModalBottomSheet<int>(
            builder: (context) => Center(
              child: TextButton(
                key: Key('sheet-$value'),
                onPressed: () => Navigator.pop(context, value),
                child: Text('Pop $value'),
              ),
            ),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(Key('sheet-$value')));
          await tester.pumpAndSettle();
          return future;
        }

        expect(await openAndClose(1), 1);
        expect(await openAndClose(2), 2);
        expect(
          octopus.observer.value.children.any((n) => n.name == 'm'),
          isFalse,
        );
      });

      testWidgets('showDialog still works (regression)', (tester) async {
        final octopus = Octopus(routes: FakeRoutes.values);
        await tester.pumpApp(octopus);

        final future = octopus.showDialog<String>(
          (context) => AlertDialog(
            content: const Text('Dialog'),
            actions: [
              TextButton(
                key: const Key('dialog-ok'),
                onPressed: () => Navigator.pop(context, 'ok'),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Dialog'), findsOneWidget);
        await tester.tap(find.byKey(const Key('dialog-ok')));
        await tester.pumpAndSettle();

        expect(await future, 'ok');
      });
    });
