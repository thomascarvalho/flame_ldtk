import 'package:flame/components.dart';
import '../models/ldtk_level.dart';
import '../models/ldtk_entity.dart';
import '../parsers/ldtk_json_parser.dart';
import '../parsers/ldtk_parser_utils.dart';

/// A Flame component that loads and displays a LDtk level from JSON format.
class LdtkJsonLevelComponent extends PositionComponent {
  static final LdtkJsonParser _parser = LdtkJsonParser();

  LdtkLevel? _levelData;

  /// Gets the loaded level data.
  LdtkLevel? get levelData => _levelData;

  /// Loads a level from a LDtk project file.
  ///
  /// The [projectPath] should point to the .ldtk file.
  /// The [levelIdentifier] is the name of the level to load.
  /// The [loadBackground] parameter controls whether to load the background image if defined (default: true).
  ///
  /// Example:
  /// ```dart
  /// await component.loadLevel('assets/world.ldtk', 'Level_0');
  /// ```
  Future<void> loadLevel(
    String projectPath,
    String levelIdentifier, {
    bool loadBackground = true,
  }) async {
    // Load project and get JSON level
    final project = await _parser.loadProject(projectPath);
    final jsonLevel = project.levels.firstWhere(
      (level) => level.identifier == levelIdentifier,
      orElse: () => throw Exception(
          'Level "$levelIdentifier" not found in project "$projectPath"'),
    );

    // Parse level data from JSON
    _levelData = await _parser.loadLevel(projectPath, levelIdentifier);

    final levelSize =
        Vector2(_levelData!.width.toDouble(), _levelData!.height.toDouble());

    // Load background image if enabled and defined
    if (loadBackground && jsonLevel.bgRelPath != null) {
      try {
        final basePath = LdtkParserUtils.getBasePath(projectPath);
        final bgImagePath = '$basePath/${jsonLevel.bgRelPath}';
        final bgImage = await LdtkParserUtils.loadImage(bgImagePath);

        final bgSprite = Sprite(bgImage);

        // Handle different background positioning modes
        final Vector2 bgSize;
        final Anchor bgAnchor;

        switch (jsonLevel.bgPos) {
          case 'Cover':
            // Cover the entire level, may crop
            bgSize = levelSize;
            bgAnchor = Anchor.center;
            break;
          case 'Contain':
            // Fit within level, may have borders
            final scale = (levelSize.x / bgImage.width.toDouble())
                .clamp(0.0, levelSize.y / bgImage.height.toDouble());
            bgSize = Vector2(bgImage.width.toDouble() * scale,
                bgImage.height.toDouble() * scale);
            bgAnchor = Anchor.center;
            break;
          case 'Unscaled':
            // Original size
            bgSize =
                Vector2(bgImage.width.toDouble(), bgImage.height.toDouble());
            bgAnchor = Anchor.topLeft;
            break;
          default:
            // CoverDirty or unknown - use Cover
            bgSize = levelSize;
            bgAnchor = Anchor.center;
        }

        final bgComponent = SpriteComponent(
          sprite: bgSprite,
          size: bgSize,
          anchor: bgAnchor,
          position: Vector2(
            levelSize.x * (jsonLevel.bgPivotX ?? 0.5),
            levelSize.y * (jsonLevel.bgPivotY ?? 0.5),
          ),
          priority: -1, // Render behind everything
        );

        await add(bgComponent);
      } catch (e) {
        // Background image is optional, ignore if not found
      }
    }

    // Call hook for entities (to be overridden by user)
    await onEntitiesLoaded(_levelData!.entities);
  }

  /// Called after entities are loaded. Override this to create custom entity components.
  Future<void> onEntitiesLoaded(List<LdtkEntity> entities) async {
    // Default: do nothing. User can override to create custom components.
  }
}
