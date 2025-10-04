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

    // Handle flip flags (f: 0=no flip, 1=X flip, 2=Y flip, 3=XY flip)
    if (tile.f == 1 || tile.f == 3) {
      spriteComponent.flipHorizontally();
    }
    if (tile.f == 2 || tile.f == 3) {
      spriteComponent.flipVertically();
    }

    await add(spriteComponent);
  }
}
