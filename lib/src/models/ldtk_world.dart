import 'dart:convert';
import 'package:flutter/services.dart';
import '../parsers/ldtk_super_simple_parser.dart';
import '../parsers/ldtk_json_parser.dart';
import '../parsers/ldtk_parser_utils.dart';
import 'ldtk_level.dart';
import 'ldtk_json_models.dart';

/// Represents a LDtk world/project that can load levels.
///
/// This class simplifies level loading by managing paths and configuration.
///
/// Example usage:
/// ```dart
/// // Load the world
/// final world = await LdtkWorld.load('assets/my-project.ldtk');
///
/// // Load a level
/// final level = await world.loadLevel('Level_0', intGridLayers: ['Collisions']);
/// ```
class LdtkWorld {
  /// The path to the .ldtk project file.
  final String projectPath;

  /// Whether this project uses simplified export format.
  final bool isSimplified;

  /// Whether this project uses external levels.
  final bool hasExternalLevels;

  /// Base path for assets (tilesets, backgrounds, etc).
  /// Defaults to the directory containing the .ldtk file.
  final String assetBasePath;

  /// Path to the simplified export folder (if using simplified export).
  /// Example: "assets/my-project/simplified"
  final String? simplifiedPath;

  /// All available levels in this world.
  final List<LdtkJsonLevel> levels;

  /// Project definitions (layers, entities, tilesets).
  final LdtkDefinitions? defs;

  const LdtkWorld._({
    required this.projectPath,
    required this.isSimplified,
    required this.hasExternalLevels,
    required this.assetBasePath,
    this.simplifiedPath,
    required this.levels,
    this.defs,
  });

  /// Creates a LdtkWorld instance for testing purposes.
  ///
  /// This constructor is only intended for use in tests to create mock worlds.
  const LdtkWorld.forTesting({
    required this.projectPath,
    required this.isSimplified,
    required this.hasExternalLevels,
    required this.assetBasePath,
    this.simplifiedPath,
    required this.levels,
    this.defs,
  });

  /// Loads a LDtk world from the specified project file.
  ///
  /// The [projectPath] should point to the .ldtk file.
  ///
  /// Optional parameters:
  /// - [assetBasePath]: Override the default asset base path.
  ///   Defaults to the directory containing the .ldtk file.
  /// - [simplifiedPath]: Override the simplified export folder path.
  ///   Defaults to "{projectDir}/simplified" if simplified export is used.
  ///
  /// Example:
  /// ```dart
  /// final world = await LdtkWorld.load('assets/world.ldtk');
  /// ```
  static Future<LdtkWorld> load(
    String projectPath, {
    String? assetBasePath,
    String? simplifiedPath,
  }) async {
    // Load the project file
    final jsonString = await rootBundle.loadString(projectPath);
    final json = jsonDecode(jsonString) as Map<String, dynamic>;

    // Parse project metadata
    final isSimplified = json['simplifiedExport'] as bool? ?? false;
    final hasExternalLevels = json['externalLevels'] as bool? ?? false;

    // Calculate base path
    final calculatedBasePath =
        assetBasePath ?? LdtkParserUtils.getBasePath(projectPath);

    // Calculate simplified path if needed
    // Example: if projectPath is 'assets/world.ldtk', simplified path is 'assets/world/simplified'
    String? calculatedSimplifiedPath;
    if (isSimplified) {
      if (simplifiedPath != null) {
        calculatedSimplifiedPath = simplifiedPath;
      } else {
        // Extract project name from path (e.g., "world.ldtk" -> "world")
        final projectName = projectPath.split('/').last.replaceAll('.ldtk', '');
        calculatedSimplifiedPath =
            '$calculatedBasePath/$projectName/simplified';
      }
    }

    // Parse levels and definitions
    final ldtkJson = LdtkJson.fromJson(json);

    return LdtkWorld._(
      projectPath: projectPath,
      isSimplified: isSimplified,
      hasExternalLevels: hasExternalLevels,
      assetBasePath: calculatedBasePath,
      simplifiedPath: calculatedSimplifiedPath,
      levels: ldtkJson.levels,
      defs: ldtkJson.defs,
    );
  }

  /// Loads a level by its identifier.
  ///
  /// The [levelIdentifier] is the name of the level in LDtk.
  ///
  /// Optional parameters:
  /// - [intGridLayers]: List of IntGrid layer names to load (e.g., ['Collisions']).
  /// - [cellSize]: Override the calculated cell size for IntGrid layers.
  /// - [useComposite]: For simplified export, whether to use composite image.
  ///
  /// Example:
  /// ```dart
  /// final level = await world.loadLevel('Level_0', intGridLayers: ['Collisions']);
  /// ```
  Future<LdtkLevel> loadLevel(
    String levelIdentifier, {
    List<String> intGridLayers = const [],
    int? cellSize,
    bool useComposite = false,
  }) async {
    if (isSimplified) {
      return _loadSimplifiedLevel(
        levelIdentifier,
        intGridLayers: intGridLayers,
        cellSize: cellSize,
      );
    } else {
      return _loadJsonLevel(levelIdentifier);
    }
  }

  /// Loads a level using the JSON parser.
  Future<LdtkLevel> _loadJsonLevel(String levelIdentifier) async {
    final parser = LdtkJsonParser();
    return await parser.loadLevel(projectPath, levelIdentifier);
  }

  /// Loads a level using the Super Simple parser.
  Future<LdtkLevel> _loadSimplifiedLevel(
    String levelIdentifier, {
    List<String> intGridLayers = const [],
    int? cellSize,
  }) async {
    final parser = LdtkSuperSimpleParser();

    // Build the level path
    final levelPath = '$simplifiedPath/$levelIdentifier';

    // Build the .ldtkl path if external levels are used
    String? ldtklPath;
    if (hasExternalLevels) {
      // Extract project directory from projectPath
      // Example: 'assets/world-simplified.ldtk' -> 'assets/world-simplified'
      final projectDir = projectPath.replaceAll('.ldtk', '');
      ldtklPath = '$projectDir/$levelIdentifier.ldtkl';
    }

    // Parse the level
    var level = await parser.parseLevel(
      levelPath,
      ldtklPath: ldtklPath,
      assetBasePath: assetBasePath,
    );

    // Load IntGrid layers if specified
    if (intGridLayers.isNotEmpty) {
      level = await parser.loadIntGridLayers(
        levelPath,
        level,
        intGridLayers,
        cellSize: cellSize,
      );
    }

    return level;
  }

  /// Gets the .ldtkl path for a level (if external levels are used).
  String? getLdtklPath(String levelIdentifier) {
    if (!hasExternalLevels) return null;
    return '$assetBasePath/$levelIdentifier.ldtkl';
  }

  /// Gets the simplified level folder path for a level.
  String? getSimplifiedLevelPath(String levelIdentifier) {
    if (!isSimplified) return null;
    return '$simplifiedPath/$levelIdentifier';
  }

  /// Gets background image path for a level.
  String? getBackgroundPath(String levelIdentifier) {
    final level = levels.firstWhere(
      (l) => l.identifier == levelIdentifier,
      orElse: () => throw Exception(
          'Level "$levelIdentifier" not found in project "$projectPath"'),
    );

    if (level.bgRelPath == null) return null;
    return '$assetBasePath/${level.bgRelPath}';
  }
}
