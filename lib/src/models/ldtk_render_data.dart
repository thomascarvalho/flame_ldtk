import 'package:flame/components.dart';
import 'dart:ui';

/// Contains all the rendering data for a LDTK level
/// This allows rendering without relying on the Flame component lifecycle
class LdtkRenderData {
  final List<LayerRenderData> layers = [];

  void addLayer(Sprite sprite, Vector2 size, Vector2 position, Anchor anchor,
      int priority) {
    layers.add(LayerRenderData(
      sprite: sprite,
      size: size,
      position: position,
      anchor: anchor,
      priority: priority,
    ));
  }

  /// Clears all render layers
  /// This should be called before loading a new level to prevent old data from persisting
  void clear() {
    layers.clear();
  }

  /// Render all layers to a canvas
  void render(Canvas canvas) {
    // Sort by priority (lowest first = background)
    final sortedLayers = List<LayerRenderData>.from(layers)
      ..sort((a, b) => a.priority.compareTo(b.priority));

    for (final layer in sortedLayers) {
      canvas.save();

      // Apply position
      canvas.translate(layer.position.x, layer.position.y);

      // Apply anchor offset
      final anchorOffset = Vector2(
        -layer.size.x * layer.anchor.x,
        -layer.size.y * layer.anchor.y,
      );
      canvas.translate(anchorOffset.x, anchorOffset.y);

      // Render the sprite
      layer.sprite.render(canvas, size: layer.size);

      canvas.restore();
    }
  }
}

/// Data for rendering a single layer
class LayerRenderData {
  final Sprite sprite;
  final Vector2 size;
  final Vector2 position;
  final Anchor anchor;
  final int priority;

  LayerRenderData({
    required this.sprite,
    required this.size,
    required this.position,
    required this.anchor,
    required this.priority,
  });
}
