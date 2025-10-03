import 'package:flutter/material.dart';
import 'ldtk_entity.dart';
import 'ldtk_intgrid.dart';

/// Represents a LDtk level loaded from Super Simple Export format.
@immutable
class LdtkLevel {
  /// The name/identifier of the level.
  final String name;

  /// The width of the level in pixels.
  final int width;

  /// The height of the level in pixels.
  final int height;

  /// The background color of the level.
  final Color? bgColor;

  /// List of entities in this level.
  final List<LdtkEntity> entities;

  /// IntGrid layers in this level, indexed by layer name.
  final Map<String, LdtkIntGrid> intGrids;

  /// Custom data fields from the level.
  final Map<String, dynamic> customData;

  const LdtkLevel({
    required this.name,
    required this.width,
    required this.height,
    this.bgColor,
    this.entities = const [],
    this.intGrids = const {},
    this.customData = const {},
  });
}
