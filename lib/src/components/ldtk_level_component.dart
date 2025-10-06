import 'package:flame/components.dart';
import '../models/ldtk_level.dart';
import '../models/ldtk_entity.dart';
import '../models/ldtk_world.dart';
import '../parsers/ldtk_parser_utils.dart';

/// A Flame component that loads and displays a LDtk level using a LdtkWorld.
///
/// This component simplifies level loading by using a [LdtkWorld] instance
/// which manages paths and configuration.
///
/// Example usage:
/// ```dart
/// final world = await LdtkWorld.load('assets/my-project.ldtk');
/// final levelComponent = LdtkLevelComponent(world);
/// await levelComponent.loadLevel('Level_0', intGridLayers: ['Collisions']);
/// await add(levelComponent);
/// ```
class LdtkLevelComponent extends PositionComponent {
  /// The LDtk world this level belongs to.
  final LdtkWorld world;

  LdtkLevel? _levelData;

  /// Gets the loaded level data.
  LdtkLevel? get levelData => _levelData;

  LdtkLevelComponent(this.world);

  /// Loads a level by its identifier.
  ///
  /// The [levelIdentifier] is the name of the level in LDtk.
  ///
  /// Optional parameters:
  /// - [intGridLayers]: List of IntGrid layer names to load (e.g., ['Collisions']).
  /// - [cellSize]: Override the calculated cell size for IntGrid layers.
  /// - [useComposite]: For simplified export, whether to use composite image.
  /// - [loadBackground]: Whether to load the background image if defined (default: true).
  ///
  /// Example:
  /// ```dart
  /// await component.loadLevel('Level_0', intGridLayers: ['Collisions']);
  /// ```
  Future<void> loadLevel(
    String levelIdentifier, {
    List<String> intGridLayers = const [],
    int? cellSize,
    bool useComposite = false,
    bool loadBackground = true,
  }) async {
    // Load level data using the world
    _levelData = await world.loadLevel(
      levelIdentifier,
      intGridLayers: intGridLayers,
      cellSize: cellSize,
      useComposite: useComposite,
    );

    final levelSize =
        Vector2(_levelData!.width.toDouble(), _levelData!.height.toDouble());

    // Load background image if enabled
    if (loadBackground) {
      final bgPath = world.getBackgroundPath(levelIdentifier);
      if (bgPath != null) {
        await _loadBackground(levelIdentifier, levelSize, bgPath);
      }
    }

    // Load level visuals
    if (world.isSimplified) {
      await _loadSimplifiedVisuals(levelIdentifier, levelSize, useComposite);
    }

    // Call hook for entities (to be overridden by user)
    await onEntitiesLoaded(_levelData!.entities);
  }

  /// Loads the background image for the level.
  Future<void> _loadBackground(
    String levelIdentifier,
    Vector2 levelSize,
    String bgPath,
  ) async {
    try {
      final level =
          world.levels.firstWhere((l) => l.identifier == levelIdentifier);
      final bgImage = await LdtkParserUtils.loadImage(bgPath);
      final bgSprite = Sprite(bgImage);

      // Calculate size based on bgPos mode
      final Vector2 bgSize;
      final Anchor bgAnchor;

      switch (level.bgPos) {
        case 'Cover':
          bgSize = levelSize;
          bgAnchor = Anchor.center;
          break;
        case 'Contain':
          final scaleX = levelSize.x / bgImage.width.toDouble();
          final scaleY = levelSize.y / bgImage.height.toDouble();
          final scale = scaleX < scaleY ? scaleX : scaleY;
          bgSize = Vector2(bgImage.width.toDouble() * scale,
              bgImage.height.toDouble() * scale);
          bgAnchor = Anchor.center;
          break;
        case 'Unscaled':
          bgSize = Vector2(bgImage.width.toDouble(), bgImage.height.toDouble());
          bgAnchor = Anchor.topLeft;
          break;
        default:
          bgSize = levelSize;
          bgAnchor = Anchor.center;
      }

      final bgComponent = SpriteComponent(
        sprite: bgSprite,
        size: bgSize,
        anchor: bgAnchor,
        position: Vector2(
          levelSize.x * (level.bgPivotX ?? 0.5),
          levelSize.y * (level.bgPivotY ?? 0.5),
        ),
        priority: -10, // Render behind everything
      );
      await add(bgComponent);
    } catch (e) {
      // Background image is optional, ignore if not found
    }
  }

  /// Loads visual layers for simplified export format.
  Future<void> _loadSimplifiedVisuals(
    String levelIdentifier,
    Vector2 levelSize,
    bool useComposite,
  ) async {
    final levelPath = world.getSimplifiedLevelPath(levelIdentifier);
    if (levelPath == null) return;

    if (useComposite) {
      // Load composite image (all layers merged)
      try {
        final compositeImage =
            await LdtkParserUtils.loadImage('$levelPath/_composite.png');
        final sprite = Sprite(compositeImage);
        final spriteComponent = SpriteComponent(
          sprite: sprite,
          size: levelSize,
          priority: 0,
        );
        await add(spriteComponent);
      } catch (e) {
        // Composite might not exist
      }
    } else {
      // Load individual layer images from data.json
      final dataJson = _levelData!.customData;
      final layers = dataJson['layers'] as List<dynamic>?;

      if (layers != null && layers.isNotEmpty) {
        // Render layers from bottom to top
        for (int i = 0; i < layers.length; i++) {
          final layerFileName = layers[i] as String;
          try {
            final layerImage =
                await LdtkParserUtils.loadImage('$levelPath/$layerFileName');
            final layerSprite = Sprite(layerImage);
            final layerComponent = SpriteComponent(
              sprite: layerSprite,
              size: levelSize,
              priority: -5 + i, // Stack layers in order
            );
            await add(layerComponent);
          } catch (e) {
            // Layer might not exist, continue
          }
        }
      }
    }
  }

  /// Called after entities are loaded. Override this to create custom entity components.
  Future<void> onEntitiesLoaded(List<LdtkEntity> entities) async {
    // Default: do nothing. User can override to create custom components.
  }
}
