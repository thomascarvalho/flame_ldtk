import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flame_ldtk/flame_ldtk.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Super Simple Export - Integration Tests', () {
    late LdtkSuperSimpleParser parser;

    setUp(() {
      parser = LdtkSuperSimpleParser();
    });

    test('loads and parses real level data', () async {
      final level = await parser.parseLevel(
        'assets/world-simplified/simplified/Level_0',
      );

      expect(level.name, 'Level_0');
      expect(level.width, 360);
      expect(level.height, 360);
      expect(level.bgColor, isNotNull);
    });

    test('parses entities correctly from real data', () async {
      final level = await parser.parseLevel(
        'assets/world-simplified/simplified/Level_0',
      );

      expect(level.entities, isNotEmpty);

      final player = level.entities.firstWhere(
        (e) => e.identifier == 'Player',
      );

      expect(player.position.x, 192);
      expect(player.position.y, 300);
      expect(player.size.x, 18);
      expect(player.size.y, 18);
    });

    test('loads IntGrid layers correctly', () async {
      final level = await parser.parseLevel(
        'assets/world-simplified/simplified/Level_0',
      );

      final levelWithCollisions = await parser.loadIntGridLayers(
        'assets/world-simplified/simplified/Level_0',
        level,
        ['Collisions'],
        cellSize: 18,
      );

      expect(levelWithCollisions.intGrids, contains('Collisions'));

      final collisions = levelWithCollisions.intGrids['Collisions']!;
      expect(collisions.width, 20);
      expect(collisions.height, 20);
      expect(collisions.cellSize, 18);

      // Test specific collision values from the CSV
      expect(
          collisions.getValue(0, 19), 1); // Bottom-left corner should be solid
      expect(collisions.getValue(0, 0), 0); // Top-left should be empty
    });

    test('loads composite image', () async {
      final image = await parser.loadImage(
        'assets/world-simplified/simplified/Level_0/_composite.png',
      );

      expect(image.width, 360);
      expect(image.height, 360);
    });

    test('loads individual layer image', () async {
      final image = await parser.loadImage(
        'assets/world-simplified/simplified/Level_0/Tiles.png',
      );

      expect(image, isNotNull);
      expect(image.width, 360);
      expect(image.height, 360);
    });

    test('parses custom fields from real data', () async {
      final level = await parser.parseLevel(
        'assets/world-simplified/simplified/Level_0',
      );

      // The data.json has layers in customData
      expect(level.customData, contains('layers'));
      expect(level.customData['layers'], isA<List>());
    });

    testWithFlameGame('LdtkLevelComponent loads level correctly', (game) async {
      final world = await LdtkWorld.load('assets/world-simplified.ldtk');
      final levelComponent = LdtkLevelComponent(world);

      await game.ensureAdd(levelComponent);

      await levelComponent.loadLevel(
        'Level_0',
        intGridLayers: ['Collisions'],
        cellSize: 18,
      );

      expect(levelComponent.levelData, isNotNull);
      expect(levelComponent.levelData!.name, 'Level_0');
      expect(levelComponent.levelData!.entities, isNotEmpty);
      expect(levelComponent.levelData!.intGrids, contains('Collisions'));
    });

    testWithFlameGame('LdtkLevelComponent with background image', (game) async {
      final world = await LdtkWorld.load('assets/world-simplified.ldtk');
      final levelComponent = LdtkLevelComponent(world);

      await game.ensureAdd(levelComponent);

      await levelComponent.loadLevel(
        'Level_0',
        intGridLayers: ['Collisions'],
        useComposite: false,
      );

      // Verify level loaded successfully
      expect(levelComponent.levelData, isNotNull);
      expect(levelComponent.levelData!.entities, isNotEmpty);
    });

    test('isSolidAtPixel works with real collision data', () async {
      final level = await parser.parseLevel(
        'assets/world-simplified/simplified/Level_0',
      );

      final levelWithCollisions = await parser.loadIntGridLayers(
        'assets/world-simplified/simplified/Level_0',
        level,
        ['Collisions'],
        cellSize: 18,
      );

      final collisions = levelWithCollisions.intGrids['Collisions']!;

      // Bottom row should be solid (y = 342 is row 19)
      expect(collisions.isSolidAtPixel(0, 342), isTrue);
      expect(collisions.isSolidAtPixel(100, 342), isTrue);

      // Top-left area should be empty
      expect(collisions.isSolidAtPixel(0, 0), isFalse);
      expect(collisions.isSolidAtPixel(18, 18), isFalse);
    });
  });
}
