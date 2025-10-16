import 'dart:ui';
import 'package:flame/components.dart';
import '../models/ldtk_level.dart';
import '../models/ldtk_entity.dart';
import '../models/ldtk_world.dart';
import '../models/ldtk_render_data.dart';
import '../parsers/ldtk_parser_utils.dart';

/// A standalone LDTK renderer for Oxygen ECS that doesn't rely on Flame's component lifecycle
class LdtkOxygenRenderer {
  /// The LDtk world this renderer uses
  final LdtkWorld world;

  LdtkLevel? _levelData;
  final LdtkRenderData _renderData = LdtkRenderData();

  /// Gets the loaded level data
  LdtkLevel? get levelData => _levelData;

  /// Gets the entities from the loaded level
  List<LdtkEntity> get entities => _levelData?.entities ?? [];

  LdtkOxygenRenderer(this.world);

  /// Clears all render data and level data
  /// This should be called before loading a new level to prevent old data from persisting
  void clear() {
    _renderData.clear();
    _levelData = null;
  }

  /// Loads a level and prepares all render data
  Future<void> loadLevel(
    String levelIdentifier, {
    List<String> intGridLayers = const [],
    int? cellSize,
    bool useComposite = false,
    bool loadBackground = true,
    Map<String, (String, String)> tileEnumGrids = const {},
  }) async {
    // Clear previous level data to prevent data from old levels persisting
    clear();

    // Load level data using the world
    _levelData = await world.loadLevel(
      levelIdentifier,
      intGridLayers: intGridLayers,
      cellSize: cellSize,
      useComposite: useComposite,
      tileEnumGrids: tileEnumGrids,
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
  }

  /// Loads the background image for the level
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

      _renderData.addLayer(
        bgSprite,
        bgSize,
        Vector2(
          levelSize.x * (level.bgPivotX ?? 0.5),
          levelSize.y * (level.bgPivotY ?? 0.5),
        ),
        bgAnchor,
        -10, // Render behind everything
      );
    } catch (e) {
      // Background image is optional, ignore if not found
    }
  }

  /// Loads visual layers for simplified export format
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
        _renderData.addLayer(
          sprite,
          levelSize,
          Vector2.zero(),
          Anchor.topLeft,
          0,
        );
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
            _renderData.addLayer(
              layerSprite,
              levelSize,
              Vector2.zero(),
              Anchor.topLeft,
              -5 + i, // Stack layers in order
            );
          } catch (e) {
            // Layer might not exist, continue
          }
        }
      }
    }
  }

  /// Render the level to a canvas
  void render(Canvas canvas) {
    _renderData.render(canvas);
  }
}
