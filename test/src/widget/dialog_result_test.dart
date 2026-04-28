import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octopus/octopus.dart';

import 'fake_routes.dart';
import 'tester_extension.dart';

void main() => group('Dialog results', () {
  testWidgets('showDialog completes with Navigator.pop(result)', (
    tester,
  ) async {
    final octopus = Octopus(routes: FakeRoutes.values);
    final controller = await tester.pumpApp(octopus);

    final future = octopus.showDialog<String>(
      (context) => const AlertDialog(content: Text('Hello')),
    );
    await controller.pumpAndSettle();

    tester.state<NavigatorState>(find.byType(OctopusNavigator)).pop('ok');
    await controller.pumpAndSettle();

    await expectLater(future, completion(equals('ok')));
    expect(octopus.observer.value.children, hasLength(1));
  });

  testWidgets('showGeneralDialog completes with Navigator.pop(result)', (
    tester,
  ) async {
    final octopus = Octopus(routes: FakeRoutes.values);
    final controller = await tester.pumpApp(octopus);

    final future = octopus.showGeneralDialog<String>(
      pageBuilder: (context, _, __) =>
          const AlertDialog(content: Text('Hello')),
      barrierLabel: 'Dismiss',
      barrierDismissible: true,
    );
    await controller.pumpAndSettle();

    tester.state<NavigatorState>(find.byType(OctopusNavigator)).pop('ok');
    await controller.pumpAndSettle();

    await expectLater(future, completion(equals('ok')));
    expect(octopus.observer.value.children, hasLength(1));
  });
});
