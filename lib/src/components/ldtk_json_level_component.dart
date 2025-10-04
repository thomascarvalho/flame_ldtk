import 'package:flame/components.dart';
import '../models/ldtk_level.dart';
import '../models/ldtk_entity.dart';
import '../parsers/ldtk_json_parser.dart';

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
  ///
  /// Example:
  /// ```dart
  /// await component.loadLevel('assets/world.ldtk', 'Level_0');
  /// ```
  Future<void> loadLevel(String projectPath, String levelIdentifier) async {
    // Parse level data from JSON
    _levelData = await _parser.loadLevel(projectPath, levelIdentifier);

    // Note: JSON format doesn't include composite images like Super Simple Export
    // The level is loaded but rendering is up to the user or tile layer components

    // Call hook for entities (to be overridden by user)
    await onEntitiesLoaded(_levelData!.entities);
  }

  /// Called after entities are loaded. Override this to create custom entity components.
  Future<void> onEntitiesLoaded(List<LdtkEntity> entities) async {
    // Default: do nothing. User can override to create custom components.
  }
}
