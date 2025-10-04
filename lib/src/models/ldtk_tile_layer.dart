import 'dart:ui' as ui;
import 'ldtk_json_models.dart';

/// Represents a tile layer with its tileset image and tile data.
class LdtkTileLayer {
  final String layerName;
  final ui.Image tilesetImage;
  final int tileSize;
  final List<LdtkTileInstance> tiles;

  const LdtkTileLayer({
    required this.layerName,
    required this.tilesetImage,
    required this.tileSize,
    required this.tiles,
  });
}
