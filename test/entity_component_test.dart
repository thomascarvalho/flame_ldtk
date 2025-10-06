import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flame_ldtk/flame_ldtk.dart';

void main() {
  group('LdtkEntityComponent', () {
    test('initializes with entity data', () {
      final entity = LdtkEntity(
        identifier: 'Player',
        position: Vector2(100, 200),
        size: Vector2(32, 48),
      );

      final component = LdtkEntityComponent(entity);

      expect(component.entity.identifier, 'Player');
      expect(component.position, Vector2(100, 200));
      expect(component.size, Vector2(32, 48));
    });

    test('stores entity reference', () {
      final entity = LdtkEntity(
        identifier: 'Enemy',
        position: Vector2.zero(),
        size: Vector2(16, 16),
        fields: const {'health': 50},
      );

      final component = LdtkEntityComponent(entity);

      expect(component.entity, same(entity));
      expect(component.entity.fields['health'], 50);
    });

    testWithFlameGame('can be added to game', (game) async {
      final entity = LdtkEntity(
        identifier: 'Item',
        position: Vector2(50, 50),
        size: Vector2(8, 8),
      );

      final component = LdtkEntityComponent(entity);

      await game.ensureAdd(component);

      expect(game.children.contains(component), true);
      expect(component.isMounted, true);
    });

    testWithFlameGame('position is set from entity', (game) async {
      final entity = LdtkEntity(
        identifier: 'Chest',
        position: Vector2(150, 250),
        size: Vector2(24, 24),
      );

      final component = LdtkEntityComponent(entity);

      await game.ensureAdd(component);

      expect(component.position.x, 150);
      expect(component.position.y, 250);
      expect(component.size.x, 24);
      expect(component.size.y, 24);
    });
  });
}
