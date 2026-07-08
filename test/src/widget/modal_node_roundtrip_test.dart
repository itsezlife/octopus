import 'package:flutter_test/flutter_test.dart';
import 'package:octopus/octopus.dart';

void main() {
  test('modal node survives encode/decode', () {
    final state = OctopusState.single(
      OctopusNode.mutable('home'),
    ).mutate()
      ..children.add(
        OctopusNode.mutable('m', arguments: {'k': 'ab12'}),
      );
    final uri = state.uri;
    final restored = OctopusState.fromLocation(uri.toString());
    expect(restored.children.map((n) => n.name).toList(), ['home', 'm']);
    expect(restored.children.last.arguments['k'], 'ab12');
  });
}
