import 'dart:convert';
import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import '../models/ldtk_level.dart';
import '../models/ldtk_entity.dart';
import '../models/ldtk_intgrid.dart';
import '../models/ldtk_json_models.dart';
import '../models/ldtk_tile_layer.dart';
import 'ldtk_parser_utils.dart';

/// Parser for LDtk JSON format (non-simplified export).
class LdtkJsonParser {
  // Cache for loaded assets
  static final Map<String, LdtkJson> _projectCache = {};
  static final Map<String, LdtkJsonLevel> _levelCache = {};
  static final Map<String, LdtkLevel> _parsedLevelCache = {};

  /// Clears all caches. Useful for hot-reload or memory management.
  static void clearCache() {
    _projectCache.clear();
    _levelCache.clear();
    _parsedLevelCache.clear();
    LdtkParserUtils.clearImageCache();
  }

  /// Loads and parses a LDtk project file.
  Future<LdtkJson> loadProject(String projectPath) async {
    if (_projectCache.containsKey(projectPath)) {
      return _projectCache[projectPath]!;
    }

    final jsonString = await rootBundle.loadString(projectPath);
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    final project = LdtkJson.fromJson(json);

    _projectCache[projectPath] = project;
    return project;
  }

  /// Loads a level from a LDtk project.
  ///
  /// The [projectPath] should point to the .ldtk file.
  /// The [levelIdentifier] is the name of the level to load.
  Future<LdtkLevel> loadLevel(
      String projectPath, String levelIdentifier) async {
    final cacheKey = '$projectPath:$levelIdentifier';
    if (_parsedLevelCache.containsKey(cacheKey)) {
      return _parsedLevelCache[cacheKey]!;
    }

    final project = await loadProject(projectPath);

    // Find the level by identifier
    final jsonLevel = project.levels.firstWhere(
      (level) => level.identifier == levelIdentifier,
      orElse: () => throw Exception('Level "$levelIdentifier" not found'),
    );

    LdtkJsonLevel levelWithLayers = jsonLevel;

    // If level has external layers, load them
    if (project.externalLevels && jsonLevel.externalRelPath != null) {
      final basePath = LdtkParserUtils.getBasePath(projectPath);
      final levelPath = '$basePath/${jsonLevel.externalRelPath}';
      levelWithLayers = await _loadExternalLevel(levelPath);
    }

    final parsedLevel = _parseLevel(levelWithLayers, project.defs);
    _parsedLevelCache[cacheKey] = parsedLevel;
    return parsedLevel;
  }

  /// Loads an external level file (.ldtkl).
  Future<LdtkJsonLevel> _loadExternalLevel(String path) async {
    if (_levelCache.containsKey(path)) {
      return _levelCache[path]!;
    }

    final jsonString = await rootBundle.loadString(path);
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    final level = LdtkJsonLevel.fromJson(json);

    _levelCache[path] = level;
    return level;
  }

  /// Converts a LdtkJsonLevel to a LdtkLevel.
  LdtkLevel _parseLevel(LdtkJsonLevel jsonLevel, LdtkDefinitions defs) {
    // Parse background color
    final bgColor = LdtkParserUtils.parseHexColor(jsonLevel.bgColor);

    // Parse entities from all Entity layers
    final List<LdtkEntity> entities = [];
    final Map<String, LdtkIntGrid> intGrids = {};

    if (jsonLevel.layerInstances != null) {
      for (final layer in jsonLevel.layerInstances!) {
        if (layer.type == 'Entities') {
          for (final entityInstance in layer.entityInstances) {
            entities.add(_parseEntity(entityInstance));
          }
        } else if (layer.type == 'IntGrid') {
          intGrids[layer.identifier] = _parseIntGrid(layer);
        }
      }
    }

    return LdtkLevel(
      name: jsonLevel.identifier,
      width: jsonLevel.pxWid,
      height: jsonLevel.pxHei,
      bgColor: bgColor,
      entities: entities,
      intGrids: intGrids,
      customData: LdtkParserUtils.parseFieldInstances(jsonLevel.fieldInstances),
    );
  }

  /// Converts a LdtkEntityInstance to a LdtkEntity.
  LdtkEntity _parseEntity(LdtkEntityInstance entityInstance) {
    return LdtkEntity(
      identifier: entityInstance.identifier,
      position: Vector2(
        entityInstance.px[0].toDouble(),
        entityInstance.px[1].toDouble(),
      ),
      size: Vector2(
        entityInstance.width.toDouble(),
        entityInstance.height.toDouble(),
      ),
      fields:
          LdtkParserUtils.parseFieldInstances(entityInstance.fieldInstances),
      color: LdtkParserUtils.parseHexColor(entityInstance.smartColor),
    );
  }

  /// Converts a LdtkLayerInstance (IntGrid) to a LdtkIntGrid.
  LdtkIntGrid _parseIntGrid(LdtkLayerInstance layer) {
    // Convert flat CSV array to 2D grid
    final List<List<int>> grid = [];
    final width = layer.cWid;
    final height = layer.cHei;

    for (int y = 0; y < height; y++) {
      final row = <int>[];
      for (int x = 0; x < width; x++) {
        final index = y * width + x;
        row.add(index < layer.intGridCsv.length ? layer.intGridCsv[index] : 0);
      }
      grid.add(row);
    }

    return LdtkIntGrid(
      layerName: layer.identifier,
      grid: grid,
      cellSize: layer.gridSize,
    );
  }

  /// Loads all levels from a project.
  Future<List<LdtkLevel>> loadAllLevels(String projectPath) async {
    final project = await loadProject(projectPath);
    final levels = <LdtkLevel>[];

    for (final jsonLevel in project.levels) {
      final level = await loadLevel(projectPath, jsonLevel.identifier);
      levels.add(level);
    }

    return levels;
  }

  /// Loads tile layers for a level.
  ///
  /// Returns a list of [LdtkTileLayer] with loaded tileset images.
  Future<List<LdtkTileLayer>> loadTileLayers(
    String projectPath,
    String levelIdentifier,
  ) async {
    final project = await loadProject(projectPath);

    // Find the level
    final jsonLevel = project.levels.firstWhere(
      (level) => level.identifier == levelIdentifier,
      orElse: () => throw Exception('Level "$levelIdentifier" not found'),
    );

    LdtkJsonLevel levelWithLayers = jsonLevel;

    // Load external level if needed
    if (project.externalLevels && jsonLevel.externalRelPath != null) {
      final basePath = LdtkParserUtils.getBasePath(projectPath);
      final levelPath = '$basePath/${jsonLevel.externalRelPath}';
      levelWithLayers = await _loadExternalLevel(levelPath);
    }

    if (levelWithLayers.layerInstances == null) {
      return [];
    }

    final tileLayers = <LdtkTileLayer>[];
    final basePath = LdtkParserUtils.getBasePath(projectPath);

    // Process each tile layer
    for (final layer in levelWithLayers.layerInstances!) {
      if (layer.type == 'Tiles' && layer.gridTiles.isNotEmpty) {
        // Find the tileset definition
        if (layer.tilesetDefUid == null) continue;

        final tilesetDef = project.defs.tilesets.firstWhere(
          (ts) => ts.uid == layer.tilesetDefUid,
          orElse: () => throw Exception(
            'Tileset with uid ${layer.tilesetDefUid} not found',
          ),
        );

        // Load tileset image
        if (tilesetDef.relPath == null) continue;

        final tilesetPath = '$basePath/${tilesetDef.relPath}';
        final tilesetImage = await LdtkParserUtils.loadImage(tilesetPath);

        tileLayers.add(
          LdtkTileLayer(
            layerName: layer.identifier,
            tilesetImage: tilesetImage,
            tileSize: layer.gridSize,
            tiles: layer.gridTiles,
          ),
        );
      }
    }

    return tileLayers;
  }
}
