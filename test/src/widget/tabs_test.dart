import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octopus/octopus.dart';

import 'tester_extension.dart';

enum _TabsRoutes with OctopusRoute {
  root('root'),
  tabA('tab-a'),
  tabB('tab-b');

  const _TabsRoutes(this.name);

  @override
  final String name;

  @override
  Widget builder(BuildContext context, OctopusState state, OctopusNode node) =>
      switch (this) {
        _TabsRoutes.root => Scaffold(
            body: OctopusTabs(
              root: _TabsRoutes.root,
              tabs: const [_TabsRoutes.tabA, _TabsRoutes.tabB],
              tabIdentifier: 'tab',
              builder: (context, child, currentIndex, onTabPressed) => Column(
                children: [
                  Text('index=$currentIndex', key: const ValueKey('index')),
                  TextButton(
                    key: const ValueKey('tabA'),
                    onPressed: () => onTabPressed(0),
                    child: const Text('A'),
                  ),
                  TextButton(
                    key: const ValueKey('tabB'),
                    onPressed: () => onTabPressed(1),
                    child: const Text('B'),
                  ),
                  Expanded(child: child),
                ],
              ),
            ),
          ),
        _ => const Scaffold(body: SizedBox.shrink()),
      };
}

void main() => group('OctopusTabs', () {
      testWidgets(
        'updates root node arguments (not global state.arguments)',
        (tester) async {
          final octopus = Octopus(
            routes: _TabsRoutes.values,
            defaultRoute: _TabsRoutes.root,
          );
          final controller = await tester.pumpApp(octopus);
          await controller.pumpAndSettle();

          OctopusNode? rootNode() =>
              octopus.observer.value.findByName(_TabsRoutes.root.name);

          expect(octopus.observer.value.arguments, isEmpty);
          expect(rootNode(), isNotNull);
          expect(rootNode()!.arguments['tab'], anyOf(isNull, isNotEmpty));

          await tester.tap(find.byKey(const ValueKey('tabB')));
          await controller.pumpAndSettle();

          expect(octopus.observer.value.arguments, isEmpty);
          expect(rootNode()!.arguments['tab'], equals(_TabsRoutes.tabB.name));

          await tester.tap(find.byKey(const ValueKey('tabA')));
          await controller.pumpAndSettle();

          expect(octopus.observer.value.arguments, isEmpty);
          expect(rootNode()!.arguments['tab'], equals(_TabsRoutes.tabA.name));
        },
      );

      testWidgets(
        'restores active tab from root node arguments',
        (tester) async {
          final initialState = OctopusState.single(
            _TabsRoutes.root.node(
              arguments: {'tab': _TabsRoutes.tabB.name},
            ),
          );
          final octopus = Octopus(
            routes: _TabsRoutes.values,
            defaultRoute: _TabsRoutes.root,
            initialState: initialState,
          );
          final controller = await tester.pumpApp(octopus);
          await controller.pumpAndSettle();

          expect(find.text('index=1'), findsOneWidget);
          expect(
            octopus.observer.value
                .findByName(_TabsRoutes.root.name)
                ?.arguments['tab'],
            equals(_TabsRoutes.tabB.name),
          );
        },
      );
    });

