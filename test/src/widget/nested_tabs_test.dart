import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octopus/octopus.dart';

import 'tester_extension.dart';

enum _NestedTabsRoutes with OctopusRoute {
  home('home'),
  tab1('home-tab1'),
  tab2('home-tab2'),
  tab1tab1('home-tab1-tab1'),
  tab1tab2('home-tab1-tab2');

  const _NestedTabsRoutes(this.name);

  @override
  final String name;

  @override
  Widget builder(BuildContext context, OctopusState state, OctopusNode node) =>
      switch (this) {
        _NestedTabsRoutes.home => Scaffold(
          body: OctopusTabs(
            root: _NestedTabsRoutes.home,
            tabs: const [_NestedTabsRoutes.tab1, _NestedTabsRoutes.tab2],
            tabIdentifier: 'outerTab',
            tabBuilder: (context, _, __, ___) => const SizedBox.shrink(),
            builder: (context, child, outerIndex, onOuterPressed) => Column(
              children: [
                Text(
                  'outerIndex=$outerIndex',
                  key: const ValueKey('outerIndex'),
                ),
                TextButton(
                  key: const ValueKey('outerTab1'),
                  onPressed: () => onOuterPressed(0),
                  child: const Text('Outer1'),
                ),
                TextButton(
                  key: const ValueKey('outerTab2'),
                  onPressed: () => onOuterPressed(1),
                  child: const Text('Outer2'),
                ),
                if (outerIndex == 0)
                  OctopusTabs(
                    root: _NestedTabsRoutes.tab1,
                    tabs: const [
                      _NestedTabsRoutes.tab1tab1,
                      _NestedTabsRoutes.tab1tab2,
                    ],
                    tabIdentifier: 'innerTab',
                    tabBuilder: (context, _, __, ___) =>
                        const SizedBox.shrink(),
                    builder: (context, child, innerIndex, onInnerPressed) =>
                        Column(
                          children: [
                            Text(
                              'innerIndex=$innerIndex',
                              key: const ValueKey('innerIndex'),
                            ),
                            TextButton(
                              key: const ValueKey('innerTab1'),
                              onPressed: () => onInnerPressed(0),
                              child: const Text('Inner1'),
                            ),
                            TextButton(
                              key: const ValueKey('innerTab2'),
                              onPressed: () => onInnerPressed(1),
                              child: const Text('Inner2'),
                            ),
                          ],
                        ),
                  ),
              ],
            ),
          ),
        ),
        _ => const Scaffold(body: SizedBox.shrink()),
      };
}

void main() => group('OctopusTabs (nested)', () {
  testWidgets(
    'updates global arguments for outer + inner (tabIdentifier keys)',
    (tester) async {
      final initialState = OctopusState(
        children: [
          _NestedTabsRoutes.home.node(
            children: [
              _NestedTabsRoutes.tab1.node(
                children: [
                  _NestedTabsRoutes.tab1tab1.node(),
                  _NestedTabsRoutes.tab1tab2.node(),
                ],
              ),
              _NestedTabsRoutes.tab2.node(),
            ],
          ),
        ],
        arguments: const <String, String>{},
        intention: OctopusStateIntention.neglect,
      );
      final octopus = Octopus(
        routes: _NestedTabsRoutes.values,
        defaultRoute: _NestedTabsRoutes.home,
        initialState: initialState,
      );
      final controller = await tester.pumpApp(octopus);
      await controller.pumpAndSettle();

      OctopusNode? homeNode() =>
          octopus.observer.value.findByName(_NestedTabsRoutes.home.name);
      OctopusNode? tab1Node() =>
          octopus.observer.value.findByName(_NestedTabsRoutes.tab1.name);

      expect(homeNode(), isNotNull);
      expect(tab1Node(), isNotNull);

      await tester.tap(find.byKey(const ValueKey('outerTab2')));
      await controller.pumpAndSettle();
      expect(
        octopus.observer.value.arguments['outerTab'],
        _NestedTabsRoutes.tab2.name,
      );

      await tester.tap(find.byKey(const ValueKey('outerTab1')));
      await controller.pumpAndSettle();
      expect(
        octopus.observer.value.arguments['outerTab'],
        _NestedTabsRoutes.tab1.name,
      );

      await tester.tap(find.byKey(const ValueKey('innerTab2')));
      await controller.pumpAndSettle();
      expect(
        octopus.observer.value.arguments['innerTab'],
        _NestedTabsRoutes.tab1tab2.name,
      );

      // Switching away and back should not overwrite inner selection.
      await tester.tap(find.byKey(const ValueKey('outerTab2')));
      await controller.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('outerTab1')));
      await controller.pumpAndSettle();

      expect(
        octopus.observer.value.arguments['innerTab'],
        _NestedTabsRoutes.tab1tab2.name,
      );
      expect(find.text('innerIndex=1'), findsOneWidget);
    },
  );
});
