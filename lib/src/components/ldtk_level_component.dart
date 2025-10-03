import 'package:flame/components.dart';
import '../models/ldtk_level.dart';
import '../models/ldtk_entity.dart';
import '../parsers/ldtk_super_simple_parser.dart';

/// A Flame component that loads and displays a LDtk level.
class LdtkLevelComponent extends PositionComponent {
  static final LdtkSuperSimpleParser _parser = LdtkSuperSimpleParser();

  LdtkLevel? _levelData;

  /// Gets the loaded level data.
  LdtkLevel? get levelData => _levelData;

  /// Loads a level from the specified path.
  ///
  /// The [levelPath] should point to the level folder containing
  /// the Super Simple Export files.
  ///
  /// The [intGridLayers] parameter specifies which IntGrid layers to load (e.g., ['Collisions']).
  /// The [cellSize] parameter allows overriding the calculated cell size (useful when grid dimensions don't exactly match level size).
  Future<void> loadLevel(String levelPath,
      {List<String> intGridLayers = const [], int? cellSize}) async {
    // Parse level data
    _levelData = await _parser.parseLevel(levelPath);

    // Load IntGrid layers if specified
    if (intGridLayers.isNotEmpty) {
      _levelData = await _parser.loadIntGridLayers(
          levelPath, _levelData!, intGridLayers,
          cellSize: cellSize);
    }

    // Load composite image
    final compositeImage =
        await _parser.loadComposite('$levelPath/_composite.png');

    // Create sprite from image
    final sprite = Sprite(compositeImage);

    // Create sprite component and add it as a child
    final spriteComponent = SpriteComponent(
      sprite: sprite,
      size:
          Vector2(_levelData!.width.toDouble(), _levelData!.height.toDouble()),
    );

    await add(spriteComponent);

    // Call hook for entities (to be overridden by user)
    await onEntitiesLoaded(_levelData!.entities);
  }

  /// Called after entities are loaded. Override this to create custom entity components.
  Future<void> onEntitiesLoaded(List<LdtkEntity> entities) async {
    // Default: do nothing. User can override to create custom components.
  }
}
