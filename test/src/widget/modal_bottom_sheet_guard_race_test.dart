import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octopus/octopus.dart';

import 'fake_routes.dart';
import 'tester_extension.dart';

/// Delays every call so concurrent refresh can enqueue a stale snapshot.
class _SlowGuard extends OctopusGuard {
  _SlowGuard({super.refresh});

  @override
  Future<OctopusState> call(
    List<OctopusHistoryEntry> history,
    OctopusState$Mutable state,
    Map<String, Object?> context,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 20));
    return state;
  }
}

void main() => group('showModalBottomSheet + guard refresh race', () {
      testWidgets(
        'stale replace queued during in-flight modal must not wipe sheet',
        (tester) async {
          final refresh = ChangeNotifier();
          final octopus = Octopus(
            routes: FakeRoutes.values,
            guards: <IOctopusGuard>[
              _SlowGuard(refresh: refresh),
            ],
          );
          await tester.pumpApp(octopus);
          await tester.pumpAndSettle();

          // Start modal; SlowGuard keeps the navigate state in-flight.
          final future = octopus.showModalBottomSheet<int>(
            builder: (context) => Center(
              child: TextButton(
                key: const Key('sheet-pop'),
                onPressed: () => Navigator.pop(context, 7),
                child: const Text('Pop'),
              ),
            ),
          );

          // Observer still has no `m` while the modal navigate is processing.
          expect(
            octopus.observer.value.children.any((n) => n.name == 'm'),
            isFalse,
          );
          // Enqueue replace of the stale [home] snapshot.
          refresh.notifyListeners();

          await tester.pumpAndSettle();

          expect(
            octopus.observer.value.children.map((n) => n.name).toList(),
            contains('m'),
            reason: 'stale guard refresh must not wipe the modal node',
          );
          expect(find.byKey(const Key('sheet-pop')), findsOneWidget);

          await tester.tap(find.byKey(const Key('sheet-pop')));
          await tester.pumpAndSettle();
          expect(await future, 7);
        },
      );
    });
