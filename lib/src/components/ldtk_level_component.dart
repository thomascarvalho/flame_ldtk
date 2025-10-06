import 'dart:convert';
import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import '../models/ldtk_level.dart';
import '../models/ldtk_entity.dart';
import '../parsers/ldtk_super_simple_parser.dart';
import '../parsers/ldtk_parser_utils.dart';

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
  /// The [ldtklPath] parameter is the path to the .ldtkl file to read background image info from (optional).
  ///   Example: 'assets/world/Level_0.ldtkl'
  /// The [assetBasePath] parameter is the base path for background images (default: same directory as ldtklPath).
  ///   Example: 'assets' if your bgRelPath in LDtk is relative to assets folder
  /// The [useComposite] parameter controls whether to use the composite image or individual layers (default: false for better flexibility).
  Future<void> loadLevel(
    String levelPath, {
    List<String> intGridLayers = const [],
    int? cellSize,
    String? ldtklPath,
    String? assetBasePath,
    bool useComposite = false,
  }) async {
    // Parse level data
    _levelData = await _parser.parseLevel(levelPath);

    // Load IntGrid layers if specified
    if (intGridLayers.isNotEmpty) {
      _levelData = await _parser.loadIntGridLayers(
          levelPath, _levelData!, intGridLayers,
          cellSize: cellSize);
    }

    final levelSize =
        Vector2(_levelData!.width.toDouble(), _levelData!.height.toDouble());

    // Load background image from .ldtkl if provided
    if (ldtklPath != null) {
      try {
        // Parse .ldtkl file to get background info
        final ldtklString = await rootBundle.loadString(ldtklPath);
        final ldtklJson = jsonDecode(ldtklString) as Map<String, dynamic>;

        final bgRelPath = ldtklJson['bgRelPath'] as String?;
        final bgPos = ldtklJson['bgPos'] as String?;
        final bgPivotX = (ldtklJson['bgPivotX'] as num?)?.toDouble() ?? 0.5;
        final bgPivotY = (ldtklJson['bgPivotY'] as num?)?.toDouble() ?? 0.5;

        if (bgRelPath != null) {
          // Get base path for assets
          final basePath =
              assetBasePath ?? LdtkParserUtils.getBasePath(ldtklPath);
          final bgImagePath = '$basePath/$bgRelPath';
          final bgImage = await LdtkParserUtils.loadImage(bgImagePath);
          final bgSprite = Sprite(bgImage);

          // Calculate size based on bgPos mode
          final Vector2 bgSize;
          final Anchor bgAnchor;

          switch (bgPos) {
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
              bgSize =
                  Vector2(bgImage.width.toDouble(), bgImage.height.toDouble());
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
            position: Vector2(levelSize.x * bgPivotX, levelSize.y * bgPivotY),
            priority: -10, // Render behind everything
          );
          await add(bgComponent);
        }
      } catch (e) {
        // Background image is optional, ignore if not found
      }
    }

    if (useComposite) {
      // Load composite image (all layers merged, includes background color)
      final compositeImage =
          await _parser.loadImage('$levelPath/_composite.png');
      final sprite = Sprite(compositeImage);
      final spriteComponent = SpriteComponent(
        sprite: sprite,
        size: levelSize,
        priority: 0,
      );
      await add(spriteComponent);
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
                await _parser.loadImage('$levelPath/$layerFileName');
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

    // Call hook for entities (to be overridden by user)
    await onEntitiesLoaded(_levelData!.entities);
  }

  /// Called after entities are loaded. Override this to create custom entity components.
  Future<void> onEntitiesLoaded(List<LdtkEntity> entities) async {
    // Default: do nothing. User can override to create custom components.
  }
}
