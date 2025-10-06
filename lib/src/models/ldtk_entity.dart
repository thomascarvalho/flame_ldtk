import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Represents an entity from a LDtk level.
@immutable
class LdtkEntity {
  /// The identifier/type of the entity.
  final String identifier;

  /// The position of the entity (x, y).
  final Vector2 position;

  /// The size of the entity (width, height).
  final Vector2 size;

  /// Custom fields associated with this entity.
  final Map<String, dynamic> fields;

  /// Optional color tag for the entity.
  final Color? color;

  /// Optional sprite from the entity's tile definition.
  /// This sprite can be used to render the entity's visual representation.
  final Sprite? sprite;

  const LdtkEntity({
    required this.identifier,
    required this.position,
    required this.size,
    this.fields = const {},
    this.color,
    this.sprite,
  });
}
