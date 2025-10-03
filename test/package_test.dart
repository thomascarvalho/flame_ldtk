import 'package:flutter_test/flutter_test.dart';
import 'package:flame_ldtk/flame_ldtk.dart';

void main() {
  test('package exports all necessary classes', () {
    // This test verifies that all main classes are exported
    expect(LdtkLevel, isNotNull);
    expect(LdtkEntity, isNotNull);
    expect(LdtkIntGrid, isNotNull);
    expect(LdtkLevelComponent, isNotNull);
    expect(LdtkEntityComponent, isNotNull);
    expect(LdtkSuperSimpleParser, isNotNull);
  });
}
