import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
import 'package:flame_ldtk/src/components/ldtk_level_component.dart';
import 'package:flame_ldtk/src/models/ldtk_entity.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LdtkLevelComponent', () {
    test('component starts with null levelData', () {
      final component = LdtkLevelComponent();
      expect(component.levelData, isNull);
    });

    test('can be instantiated', () {
      final component = LdtkLevelComponent();
      expect(component, isA<LdtkLevelComponent>());
      expect(component, isA<PositionComponent>());
    });

    testWithFlameGame('can be added to game', (game) async {
      final component = LdtkLevelComponent();
      await game.ensureAdd(component);

      expect(game.children.contains(component), isTrue);
      expect(component.isMounted, isTrue);
    });

    test('onEntitiesLoaded is called with entities', () async {
      var entitiesLoaded = false;
      final testComponent = _TestLevelComponent(
        onEntitiesCallback: (entities) {
          entitiesLoaded = true;
        },
      );

      // Mock entities
      final entities = [
        LdtkEntity(
          identifier: 'Player',
          position: Vector2(10, 20),
          size: Vector2(16, 16),
        ),
      ];

      await testComponent.onEntitiesLoaded(entities);

      expect(entitiesLoaded, isTrue);
    });

    test('custom entity creation works', () async {
      final entities = <LdtkEntity>[];
      final testComponent = _TestLevelComponent(
        onEntitiesCallback: (loadedEntities) {
          entities.addAll(loadedEntities);
        },
      );

      final testEntities = [
        LdtkEntity(
          identifier: 'Player',
          position: Vector2(32, 32),
          size: Vector2(16, 16),
        ),
        LdtkEntity(
          identifier: 'Enemy',
          position: Vector2(64, 64),
          size: Vector2(16, 16),
        ),
      ];

      await testComponent.onEntitiesLoaded(testEntities);

      expect(entities, hasLength(2));
      expect(entities[0].identifier, 'Player');
      expect(entities[1].identifier, 'Enemy');
    });

    test('can be extended with custom entity handling', () {
      final customComponent = _TestLevelComponent(
        onEntitiesCallback: (entities) {},
      );

      expect(customComponent, isA<LdtkLevelComponent>());
    });

    // Note: Full integration tests with asset loading are in example/test/integration_test.dart
  });
}

/// Test implementation of LdtkLevelComponent for testing custom behavior
class _TestLevelComponent extends LdtkLevelComponent {
  final void Function(List<LdtkEntity> entities) onEntitiesCallback;

  _TestLevelComponent({required this.onEntitiesCallback});

  @override
  Future<void> onEntitiesLoaded(List<LdtkEntity> entities) async {
    onEntitiesCallback(entities);
  }
}
