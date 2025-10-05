import 'dart:ui' as ui;
import 'package:flame/components.dart';
import '../models/ldtk_tile_layer.dart';
import '../models/ldtk_json_models.dart';

/// Component that renders a tile layer from LDtk.
class LdtkTileLayerComponent extends PositionComponent {
  final LdtkTileLayer tileLayer;

  LdtkTileLayerComponent(this.tileLayer);

  @override
  Future<void> onLoad() async {
    // For each tile in the layer, create a sprite component
    for (final tile in tileLayer.tiles) {
      final tileComponent = _LdtkTileComponent(
        tileLayer.tilesetImage,
        tile,
        tileLayer.tileSize,
      );
      await add(tileComponent);
    }
  }
}

/// Individual tile sprite component.
class _LdtkTileComponent extends PositionComponent {
  final ui.Image tilesetImage;
  final LdtkTileInstance tile;
  final int tileSize;

  _LdtkTileComponent(this.tilesetImage, this.tile, this.tileSize);

  @override
  Future<void> onLoad() async {
    // Set position from tile data
    position = Vector2(
      tile.px[0].toDouble(),
      tile.px[1].toDouble(),
    );

    // Create sprite from tileset
    final sprite = Sprite(
      tilesetImage,
      srcPosition: Vector2(
        tile.src[0].toDouble(),
        tile.src[1].toDouble(),
      ),
      srcSize: Vector2.all(tileSize.toDouble()),
    );

    // Add sprite component
    final spriteComponent = SpriteComponent(
      sprite: sprite,
      size: Vector2.all(tileSize.toDouble()),
    );

    // Handle flip/rotation flags according to LDtk specification:
    // Bit 0 (value 1): X flip
    // Bit 1 (value 2): Y flip
    // The flags can be combined (e.g., 3 = both flips)
    if ((tile.f & 1) != 0) {
      spriteComponent.flipHorizontally();
    }
    if ((tile.f & 2) != 0) {
      spriteComponent.flipVertically();
    }

    await add(spriteComponent);
  }
}
