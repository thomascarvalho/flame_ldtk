import 'package:flame/components.dart';
import '../models/ldtk_entity.dart';

/// A base Flame component representing a LDtk entity.
///
/// This is a simple base class that can be extended to create custom entity components.
/// Override [onLoad] to add your own rendering and behavior.
class LdtkEntityComponent extends PositionComponent {
  /// The entity data from LDtk.
  final LdtkEntity entity;

  LdtkEntityComponent(this.entity) {
    position = entity.position;
    size = entity.size;
  }
}
