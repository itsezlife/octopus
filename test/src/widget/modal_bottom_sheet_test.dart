import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octopus/octopus.dart';

import 'fake_routes.dart';
import 'tester_extension.dart';

/// Simulates Android/iOS system back via the navigation method channel.
Future<void> _pressSystemBack(WidgetTester tester) async {
  final message = const JSONMethodCodec().encodeMethodCall(
    const MethodCall('popRoute'),
  );
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    'flutter/navigation',
    message,
    (_) {},
  );
}

List<String> _routeNames(Octopus octopus) =>
    octopus.observer.value.children.map((n) => n.name).toList();

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

      testWidgets(
        'system back closes only the sheet and keeps underlay routes',
        (tester) async {
          final octopus = Octopus(routes: FakeRoutes.values);
          await tester.pumpApp(octopus);
          await octopus.pushNamed(FakeRoutes.shop.name);
          await tester.pumpAndSettle();

          expect(_routeNames(octopus), ['home', 'shop']);

          final future = octopus.showModalBottomSheet<int>(
            builder: (context) => const SizedBox(
              height: 200,
              child: Center(child: Text('Sheet')),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.text('Sheet'), findsOneWidget);
          expect(_routeNames(octopus), ['home', 'shop', 'm']);

          await _pressSystemBack(tester);
          await tester.pumpAndSettle();

          expect(find.text('Sheet'), findsNothing);
          expect(await future, isNull);
          // Sheet gone; underlay stack unchanged (back must not pop shop).
          expect(_routeNames(octopus), ['home', 'shop']);
        },
      );

      testWidgets(
        'routerDelegate.popRoute closes sheet via onPopPage',
        (tester) async {
          final octopus = Octopus(routes: FakeRoutes.values);
          await tester.pumpApp(octopus);

          final future = octopus.showModalBottomSheet<int>(
            builder: (context) => const SizedBox(
              height: 200,
              child: Center(child: Text('Sheet')),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.text('Sheet'), findsOneWidget);

          final handled = await octopus.config.routerDelegate.popRoute();
          await tester.pumpAndSettle();

          expect(handled, isTrue);
          expect(await future, isNull);
          expect(_routeNames(octopus), ['home']);
        },
      );

      testWidgets(
        'system back closes sheet above PopScope(canPop: false) underlay',
        (tester) async {
          final octopus = Octopus(
            routes: FakeRoutes.values,
            defaultRoute: FakeRoutes.home,
          );
          await tester.pumpApp(
            octopus,
            builder: (context, child) => PopScope(
              canPop: false,
              child: child,
            ),
          );

          final future = octopus.showModalBottomSheet<String>(
            builder: (context) => const SizedBox(
              height: 200,
              child: Center(child: Text('Sheet')),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.text('Sheet'), findsOneWidget);
          expect(_routeNames(octopus), contains('m'));

          await _pressSystemBack(tester);
          await tester.pumpAndSettle();

          expect(find.text('Sheet'), findsNothing);
          expect(await future, isNull);
          // Underlay stays; back must not bubble to SystemNavigator.pop.
          expect(_routeNames(octopus), ['home']);
        },
      );

      testWidgets(
        'system back closes top sheet only when another overlay sits under it',
        (tester) async {
          final octopus = Octopus(routes: FakeRoutes.values);
          await tester.pumpApp(octopus);

          final first = octopus.showModalBottomSheet<String>(
            builder: (context) => const SizedBox(
              height: 160,
              child: Center(child: Text('First Sheet')),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.text('First Sheet'), findsOneWidget);

          final second = octopus.showDialog<String>(
            (context) => AlertDialog(
              content: const Text('Dialog Over Sheet'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, 'ok'),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
          await tester.pumpAndSettle();
          expect(find.text('Dialog Over Sheet'), findsOneWidget);
          expect(_routeNames(octopus), containsAll(<String>['m', 'd']));

          // First back should close only the dialog.
          await _pressSystemBack(tester);
          await tester.pumpAndSettle();
          expect(await second, isNull);
          expect(find.text('Dialog Over Sheet'), findsNothing);
          expect(find.text('First Sheet'), findsOneWidget);
          expect(_routeNames(octopus), contains('m'));
          expect(_routeNames(octopus), isNot(contains('d')));

          // Second back closes the sheet and leaves home.
          await _pressSystemBack(tester);
          await tester.pumpAndSettle();
          expect(await first, isNull);
          expect(find.text('First Sheet'), findsNothing);
          expect(_routeNames(octopus), ['home']);
        },
      );

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

      testWidgets(
        'isScrollControlled nested DraggableScrollableSheet stays open',
        (tester) async {
          final octopus = Octopus(routes: FakeRoutes.values);
          await tester.pumpApp(octopus);

          final future = octopus.showModalBottomSheet<int>(
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            useSafeArea: true,
            builder: (sheetContext) => DraggableScrollableSheet(
              initialChildSize: 0.95,
              minChildSize: 0.35,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) => Material(
                color: Colors.white,
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: 20,
                  itemBuilder: (context, index) => ListTile(
                    key: index == 0 ? const Key('sheet-item') : null,
                    title: Text('Item $index'),
                    onTap: () => Navigator.of(sheetContext).pop(index),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.byKey(const Key('sheet-item')), findsOneWidget);
          expect(
            octopus.observer.value.children.any((n) => n.name == 'm'),
            isTrue,
          );

          await tester.tap(find.byKey(const Key('sheet-item')));
          await tester.pumpAndSettle();
          expect(await future, 0);
        },
      );

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
