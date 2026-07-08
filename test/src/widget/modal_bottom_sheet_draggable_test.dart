import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octopus/octopus.dart';

import 'fake_routes.dart';
import 'tester_extension.dart';

void main() => group('showModalBottomSheet + DraggableScrollableSheet', () {
      testWidgets(
        'isScrollControlled sheet with nested DraggableScrollableSheet '
        'stays open',
        (tester) async {
          final octopus = Octopus(routes: FakeRoutes.values);
          await tester.pumpApp(octopus);
          await tester.pumpAndSettle();

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
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
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

          expect(
            octopus.observer.value.children.any((n) => n.name == 'm'),
            isTrue,
          );
          expect(find.byKey(const Key('sheet-item')), findsOneWidget);

          await tester.tap(find.byKey(const Key('sheet-item')));
          await tester.pumpAndSettle();
          expect(await future, 0);
        },
      );
    });
