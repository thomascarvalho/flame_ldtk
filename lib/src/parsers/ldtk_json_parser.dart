import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import '../models/ldtk_level.dart';
import '../models/ldtk_entity.dart';
import '../models/ldtk_intgrid.dart';
import '../models/ldtk_json_models.dart';
import '../models/ldtk_tile_layer.dart';
import '../utils/lru_cache.dart';
import 'ldtk_parser_utils.dart';

/// Parser for LDtk JSON format (non-simplified export).
class LdtkJsonParser {
  // Cache for loaded assets with LRU eviction
  static final LruCache<String, LdtkJson> _projectCache = LruCache(10);
  static final LruCache<String, LdtkJsonLevel> _levelCache = LruCache(20);
  static final LruCache<String, LdtkLevel> _parsedLevelCache = LruCache(20);

  /// Clears all caches. Useful for hot-reload or memory management.
  static void clearCache() {
    _projectCache.clear();
    _levelCache.clear();
    _parsedLevelCache.clear();
    LdtkParserUtils.clearImageCache();
  }

  /// Loads and parses a LDtk project file.
  ///
  /// Throws [Exception] if the project file cannot be loaded or parsed.
  Future<LdtkJson> loadProject(String projectPath) async {
    final cached = _projectCache.get(projectPath);
    if (cached != null) {
      return cached;
    }

    try {
      final jsonString = await rootBundle.loadString(projectPath);
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final project = LdtkJson.fromJson(json);

      _projectCache.put(projectPath, project);
      return project;
    } catch (e) {
      throw Exception('Failed to load LDtk project at "$projectPath": $e');
    }
  }

  /// Loads a level from a LDtk project.
  ///
  /// The [projectPath] should point to the .ldtk file.
  /// The [levelIdentifier] is the name of the level to load.
  ///
  /// Throws [Exception] if the level is not found in the project.
  Future<LdtkLevel> loadLevel(
      String projectPath, String levelIdentifier) async {
    final cacheKey = '$projectPath:$levelIdentifier';
    final cached = _parsedLevelCache.get(cacheKey);
    if (cached != null) {
      return cached;
    }

    final project = await loadProject(projectPath);

    // Find the level by identifier
    final jsonLevel = project.levels.firstWhere(
      (level) => level.identifier == levelIdentifier,
      orElse: () => throw Exception(
          'Level "$levelIdentifier" not found in project "$projectPath". '
          'Available levels: ${project.levels.map((l) => l.identifier).join(", ")}'),
    );

    LdtkJsonLevel levelWithLayers = jsonLevel;

    // If level has external layers, load them
    if (project.externalLevels && jsonLevel.externalRelPath != null) {
      final basePath = LdtkParserUtils.getBasePath(projectPath);
      final levelPath = '$basePath/${jsonLevel.externalRelPath}';
      levelWithLayers = await _loadExternalLevel(levelPath);
    }

    final parsedLevel =
        await _parseLevel(levelWithLayers, project.defs, projectPath);
    _parsedLevelCache.put(cacheKey, parsedLevel);
    return parsedLevel;
  }

  /// Loads an external level file (.ldtkl).
  ///
  /// Throws [Exception] if the level file cannot be loaded or parsed.
  Future<LdtkJsonLevel> _loadExternalLevel(String path) async {
    final cached = _levelCache.get(path);
    if (cached != null) {
      return cached;
    }

    try {
      final jsonString = await rootBundle.loadString(path);
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final level = LdtkJsonLevel.fromJson(json);

      _levelCache.put(path, level);
      return level;
    } catch (e) {
      throw Exception('Failed to load external level at "$path": $e');
    }
  }

  /// Converts a LdtkJsonLevel to a LdtkLevel.
  Future<LdtkLevel> _parseLevel(
    LdtkJsonLevel jsonLevel,
    LdtkDefinitions defs,
    String projectPath,
  ) async {
    // Parse background color
    final bgColor = LdtkParserUtils.parseHexColor(jsonLevel.bgColor);

    // Parse entities from all Entity layers
    final List<LdtkEntity> entities = [];
    final Map<String, LdtkIntGrid> intGrids = {};

    // Pre-load tilesets used by entities
    final Map<int, ui.Image> loadedTilesets = {};
    final basePath = LdtkParserUtils.getBasePath(projectPath);

    if (jsonLevel.layerInstances != null) {
      // First pass: collect all tileset UIDs used by entities
      for (final layer in jsonLevel.layerInstances!) {
        if (layer.type == 'Entities') {
          for (final entityInstance in layer.entityInstances) {
            if (entityInstance.tile != null) {
              final tilesetUid = entityInstance.tile!.tilesetUid;
              if (!loadedTilesets.containsKey(tilesetUid)) {
                // Find and load the tileset
                final tilesetDef = defs.tilesets.firstWhere(
                  (ts) => ts.uid == tilesetUid,
                  orElse: () => throw Exception(
                    'Tileset with uid $tilesetUid not found for entity ${entityInstance.identifier}',
                  ),
                );
                if (tilesetDef.relPath != null) {
                  final tilesetPath = '$basePath/${tilesetDef.relPath}';
                  loadedTilesets[tilesetUid] =
                      await LdtkParserUtils.loadImage(tilesetPath);
                }
              }
            }
          }
        }
      }

      // Second pass: parse entities with loaded tilesets
      for (final layer in jsonLevel.layerInstances!) {
        if (layer.type == 'Entities') {
          for (final entityInstance in layer.entityInstances) {
            entities.add(_parseEntity(entityInstance, loadedTilesets));
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
  LdtkEntity _parseEntity(
    LdtkEntityInstance entityInstance,
    Map<int, ui.Image> loadedTilesets,
  ) {
    Sprite? sprite;

    // Create sprite from entity tile if available
    if (entityInstance.tile != null) {
      final tile = entityInstance.tile!;
      final tilesetImage = loadedTilesets[tile.tilesetUid];

      if (tilesetImage != null) {
        sprite = Sprite(
          tilesetImage,
          srcPosition: Vector2(tile.x.toDouble(), tile.y.toDouble()),
          srcSize: Vector2(tile.w.toDouble(), tile.h.toDouble()),
        );
      }
    }

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
      sprite: sprite,
      anchor: Anchor(
        entityInstance.pivot[0],
        entityInstance.pivot[1],
      ),
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
  ///
  /// Throws [Exception] if the level or tileset is not found.
  Future<List<LdtkTileLayer>> loadTileLayers(
    String projectPath,
    String levelIdentifier,
  ) async {
    final project = await loadProject(projectPath);

    // Find the level
    final jsonLevel = project.levels.firstWhere(
      (level) => level.identifier == levelIdentifier,
      orElse: () => throw Exception(
          'Level "$levelIdentifier" not found in project "$projectPath". '
          'Available levels: ${project.levels.map((l) => l.identifier).join(", ")}'),
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
            'Tileset with uid ${layer.tilesetDefUid} not found in project "$projectPath". '
            'Available tilesets: ${project.defs.tilesets.map((t) => '${t.identifier} (uid: ${t.uid})').join(", ")}',
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
