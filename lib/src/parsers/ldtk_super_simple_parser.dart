import 'dart:convert';
import 'dart:ui' as ui;
import 'package:csv/csv.dart';
import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import '../models/ldtk_level.dart';
import '../models/ldtk_entity.dart';
import '../models/ldtk_intgrid.dart';
import '../utils/lru_cache.dart';
import 'ldtk_parser_utils.dart';

/// Parser for LDtk Super Simple Export format.
class LdtkSuperSimpleParser {
  // Cache for loaded assets with LRU eviction
  static final LruCache<String, LdtkLevel> _levelCache = LruCache(20);
  static final LruCache<String, String> _stringCache = LruCache(50);

  /// Clears all caches. Useful for hot-reload or memory management.
  static void clearCache() {
    _levelCache.clear();
    _stringCache.clear();
    LdtkParserUtils.clearImageCache();
  }

  /// Parses a complete level from the given directory path.
  ///
  /// The [levelPath] should point to the level folder containing
  /// _composite.png, data.json, and other layer files.
  ///
  /// Optional [ldtklPath] and [assetBasePath] can be provided to load entity tiles from .ldtkl file.
  Future<LdtkLevel> parseLevel(
    String levelPath, {
    String? ldtklPath,
    String? assetBasePath,
  }) async {
    final dataJsonPath = '$levelPath/data.json';
    return await parseDataJson(
      dataJsonPath,
      ldtklPath: ldtklPath,
      assetBasePath: assetBasePath,
    );
  }

  /// Loads an image from the specified asset path.
  Future<ui.Image> loadImage(String path) async {
    return LdtkParserUtils.loadImage(path);
  }

  /// Parses entities and metadata from data.json.
  ///
  /// Throws [Exception] if the file cannot be loaded or parsed.
  ///
  /// Optional [ldtklPath] and [assetBasePath] can be provided to load entity tiles from .ldtkl file.
  Future<LdtkLevel> parseDataJson(
    String path, {
    String? ldtklPath,
    String? assetBasePath,
  }) async {
    final cacheKey = ldtklPath != null ? '$path|$ldtklPath' : path;
    final cached = _levelCache.get(cacheKey);
    if (cached != null) {
      return cached;
    }

    try {
      final jsonString = await rootBundle.loadString(path);
      final json = jsonDecode(jsonString) as Map<String, dynamic>;

      // Parse metadata
      final name = json['identifier'] as String;
      final width = json['width'] as int;
      final height = json['height'] as int;
      final bgColorStr = json['bgColor'] as String?;
      final customFields = json['customFields'] as Map<String, dynamic>? ?? {};
      final layers = json['layers'] as List<dynamic>? ?? [];

      // Combine customFields with layers
      final customData = <String, dynamic>{
        ...customFields,
        'layers': layers,
      };

      // Parse background color from hex string
      final bgColor = LdtkParserUtils.parseHexColor(bgColorStr);

      // Load entity tile info from .ldtkl if provided
      Map<String, Map<String, dynamic>>? entityTileInfo;
      Map<int, ui.Image>? loadedTilesets;

      if (ldtklPath != null) {
        final result =
            await _loadEntityTilesFromLdtkl(ldtklPath, assetBasePath);
        entityTileInfo =
            result['entityTileInfo'] as Map<String, Map<String, dynamic>>?;
        loadedTilesets = result['tilesets'] as Map<int, ui.Image>?;
      }

      // Parse entities
      final List<LdtkEntity> entities = [];
      final entitiesData = json['entities'] as Map<String, dynamic>? ?? {};

      for (final entry in entitiesData.entries) {
        // final entityType = entry.key;
        final entityList = entry.value as List;

        for (final entityData in entityList) {
          final iid = entityData['iid'] as String?;
          final tileData = entityTileInfo?[iid];

          final entity = _parseEntity(
            entityData as Map<String, dynamic>,
            tileData: tileData,
            loadedTilesets: loadedTilesets ?? {},
          );
          entities.add(entity);
        }
      }

      final level = LdtkLevel(
        name: name,
        width: width,
        height: height,
        bgColor: bgColor,
        entities: entities,
        customData: customData,
      );

      _levelCache.put(cacheKey, level);
      return level;
    } catch (e) {
      throw Exception('Failed to parse data.json at "$path": $e');
    }
  }

  /// Helper method to parse a single entity from JSON.
  LdtkEntity _parseEntity(
    Map<String, dynamic> json, {
    Map<String, dynamic>? tileData,
    Map<int, ui.Image> loadedTilesets = const {},
  }) {
    final identifier = json['id'] as String;
    final x = (json['x'] as num).toDouble();
    final y = (json['y'] as num).toDouble();
    final width = (json['width'] as num).toDouble();
    final height = (json['height'] as num).toDouble();
    final customFields = json['customFields'] as Map<String, dynamic>? ?? {};

    Sprite? sprite;

    // Create sprite from tile data if available
    if (tileData != null) {
      final tilesetUid = tileData['tilesetUid'] as int?;
      final tileX = tileData['x'] as int?;
      final tileY = tileData['y'] as int?;
      final tileW = tileData['w'] as int?;
      final tileH = tileData['h'] as int?;

      if (tilesetUid != null &&
          tileX != null &&
          tileY != null &&
          tileW != null &&
          tileH != null) {
        final tilesetImage = loadedTilesets[tilesetUid];

        if (tilesetImage != null) {
          sprite = Sprite(
            tilesetImage,
            srcPosition: Vector2(tileX.toDouble(), tileY.toDouble()),
            srcSize: Vector2(tileW.toDouble(), tileH.toDouble()),
          );
        }
      }
    }

    return LdtkEntity(
      identifier: identifier,
      position: Vector2(x, y),
      size: Vector2(width, height),
      fields: customFields,
      color: LdtkParserUtils.parseIntColor(json['color'] as int?),
      sprite: sprite,
    );
  }

  /// Loads entity tile information from .ldtkl file.
  Future<Map<String, dynamic>> _loadEntityTilesFromLdtkl(
    String ldtklPath,
    String? assetBasePath,
  ) async {
    try {
      final ldtklString = await rootBundle.loadString(ldtklPath);
      final ldtklJson = jsonDecode(ldtklString) as Map<String, dynamic>;

      // Map to store entity IID -> tile info
      final Map<String, Map<String, dynamic>> entityTileInfo = {};

      // Load tilesets info from parent .ldtk file
      final Map<int, String> tilesetPaths = {};
      final basePath = assetBasePath ?? LdtkParserUtils.getBasePath(ldtklPath);

      // We need to load the parent .ldtk file to get tileset definitions
      // Convert path like 'assets/world-simplified/Level_0.ldtkl' to 'assets/world-simplified.ldtk'
      final ldtkPath = ldtklPath.replaceAll(RegExp(r'/[^/]+\.ldtkl$'), '.ldtk');
      try {
        final ldtkString = await rootBundle.loadString(ldtkPath);
        final ldtkJson = jsonDecode(ldtkString) as Map<String, dynamic>;
        final defs = ldtkJson['defs'] as Map<String, dynamic>?;
        final tilesets = defs?['tilesets'] as List?;

        if (tilesets != null) {
          for (final tileset in tilesets) {
            final uid = tileset['uid'] as int?;
            final relPath = tileset['relPath'] as String?;
            if (uid != null && relPath != null) {
              tilesetPaths[uid] = '$basePath/$relPath';
            }
          }
        }
      } catch (e) {
        // Parent .ldtk file not found, continue without tilesets
      }

      // Load all required tilesets
      final Map<int, ui.Image> loadedTilesets = {};

      // Extract entity tile info from layers
      final layerInstances = ldtklJson['layerInstances'] as List?;
      if (layerInstances != null) {
        for (final layer in layerInstances) {
          if (layer['__type'] == 'Entities') {
            final entityInstances = layer['entityInstances'] as List?;
            if (entityInstances != null) {
              for (final entity in entityInstances) {
                final iid = entity['iid'] as String?;
                final tile = entity['__tile'] as Map<String, dynamic>?;

                if (iid != null && tile != null) {
                  entityTileInfo[iid] = tile;

                  // Load tileset if not already loaded
                  final tilesetUid = tile['tilesetUid'] as int?;
                  if (tilesetUid != null &&
                      !loadedTilesets.containsKey(tilesetUid) &&
                      tilesetPaths.containsKey(tilesetUid)) {
                    loadedTilesets[tilesetUid] =
                        await LdtkParserUtils.loadImage(
                            tilesetPaths[tilesetUid]!);
                  }
                }
              }
            }
          }
        }
      }

      return {
        'entityTileInfo': entityTileInfo,
        'tilesets': loadedTilesets,
      };
    } catch (e) {
      // If loading fails, return empty maps
      return {
        'entityTileInfo': <String, Map<String, dynamic>>{},
        'tilesets': <int, ui.Image>{},
      };
    }
  }

  /// Parses an IntGrid layer from CSV format.
  Future<LdtkIntGrid> parseIntGridCsv(
      String path, String layerName, int cellSize) async {
    // Cache CSV string loading
    var csvString = _stringCache.get(path);
    if (csvString == null) {
      csvString = await rootBundle.loadString(path);
      _stringCache.put(path, csvString);
    }

    // Parse CSV with explicit line separator handling
    final csvData = const CsvToListConverter(
      eol: '\n',
      shouldParseNumbers: true,
    ).convert(csvString);

    // Convert CSV data to 2D grid of integers, filtering empty rows
    final grid = <List<int>>[];
    int maxColumns = 0;

    for (final row in csvData) {
      if (row.isEmpty) continue;

      final intRow = [
        for (final cell in row)
          cell is int ? cell : int.tryParse(cell.toString()) ?? 0
      ];

      if (intRow.length > maxColumns) {
        maxColumns = intRow.length;
      }

      grid.add(intRow);
    }

    // Normalize all rows to have the same length (pad with zeros if needed)
    for (int i = 0; i < grid.length; i++) {
      while (grid[i].length < maxColumns) {
        grid[i].add(0);
      }
    }

    // Check if the last column is all zeros (trailing comma from LDtk export)
    if (maxColumns > 0 && grid.isNotEmpty) {
      bool lastColumnAllZeros = true;
      for (final row in grid) {
        if (row.last != 0) {
          lastColumnAllZeros = false;
          break;
        }
      }

      // Remove trailing empty column if all values are zero
      if (lastColumnAllZeros) {
        for (int i = 0; i < grid.length; i++) {
          grid[i] = grid[i].sublist(0, grid[i].length - 1);
        }
      }
    }

    return LdtkIntGrid(
      layerName: layerName,
      grid: grid,
      cellSize: cellSize,
    );
  }

  /// Parses an IntGrid layer from PNG format (1 pixel = 1 cell).
  Future<LdtkIntGrid> parseIntGridPng(String path, String layerName) async {
    // TODO: Implement PNG parsing
    throw UnimplementedError('parseIntGridPng not yet implemented');
  }

  /// Loads IntGrid layers and returns an updated LdtkLevel with the loaded grids.
  Future<LdtkLevel> loadIntGridLayers(
    String levelPath,
    LdtkLevel level,
    List<String> layerNames, {
    int? cellSize,
  }) async {
    final Map<String, LdtkIntGrid> intGrids = {...level.intGrids};

    for (final layerName in layerNames) {
      final csvPath = '$levelPath/$layerName.csv';

      // Calculate cellSize first if not provided
      // We parse once with a placeholder value, then check grid width
      final tempIntGrid = await parseIntGridCsv(csvPath, layerName, 1);
      final gridWidth = tempIntGrid.width;
      final finalCellSize =
          cellSize ?? (gridWidth > 0 ? level.width ~/ gridWidth : 8);

      // Only create new IntGrid if cellSize differs
      final correctedIntGrid = finalCellSize == 1
          ? tempIntGrid
          : LdtkIntGrid(
              layerName: layerName,
              grid: tempIntGrid.grid,
              cellSize: finalCellSize,
            );

      intGrids[layerName] = correctedIntGrid;
    }

    return LdtkLevel(
      name: level.name,
      width: level.width,
      height: level.height,
      bgColor: level.bgColor,
      entities: level.entities,
      intGrids: intGrids,
      customData: level.customData,
    );
  }

  /// Loads an IntGrid based on tileset enum tags from a .ldtkl file.
  ///
  /// This creates a virtual IntGrid where cells are marked as 1 if the tile
  /// at that position has the specified [enumTagName].
  ///
  /// Example: `loadTileEnumGrid('assets/maps/level.ldtkl', 'Deadly', 'Tiles')`
  /// will create an IntGrid marking all tiles with the "Deadly" tag.
  Future<LdtkIntGrid?> loadTileEnumGrid(
    String ldtklPath,
    String enumTagName,
    String tileLayerName, {
    String? assetBasePath,
  }) async {
    try {
      final ldtklString = await rootBundle.loadString(ldtklPath);
      final ldtklJson = jsonDecode(ldtklString) as Map<String, dynamic>;

      // Load tileset definitions from parent .ldtk file
      final ldtkPath = ldtklPath.replaceAll(RegExp(r'/[^/]+\.ldtkl$'), '.ldtk');
      Map<int, List<int>> tilesetEnumTags = {};

      try {
        final ldtkString = await rootBundle.loadString(ldtkPath);
        final ldtkJson = jsonDecode(ldtkString) as Map<String, dynamic>;
        final defs = ldtkJson['defs'] as Map<String, dynamic>?;
        final tilesets = defs?['tilesets'] as List?;

        if (tilesets != null) {
          for (final tileset in tilesets) {
            final uid = tileset['uid'] as int?;
            final enumTags = tileset['enumTags'] as List?;

            if (uid != null && enumTags != null) {
              for (final tag in enumTags) {
                final tagName = tag['enumValueId'] as String?;
                final tileIds = tag['tileIds'] as List?;

                if (tagName == enumTagName && tileIds != null) {
                  tilesetEnumTags[uid] = tileIds.map((e) => e as int).toList();
                }
              }
            }
          }
        }
      } catch (e) {
        // Parent .ldtk file not found
        return null;
      }

      // Find the tile layer in the level
      final layerInstances = ldtklJson['layerInstances'] as List?;
      if (layerInstances == null) return null;

      for (final layer in layerInstances) {
        if (layer['__identifier'] == tileLayerName) {
          final gridTiles = layer['gridTiles'] as List?;
          final cWid = layer['__cWid'] as int?;
          final cHei = layer['__cHei'] as int?;
          final gridSize = layer['__gridSize'] as int?;
          final tilesetDefUid = layer['__tilesetDefUid'] as int?;

          if (gridTiles == null ||
              cWid == null ||
              cHei == null ||
              gridSize == null ||
              tilesetDefUid == null) {
            return null;
          }

          // Get the list of tile IDs with this enum tag
          final taggedTileIds = tilesetEnumTags[tilesetDefUid] ?? [];
          if (taggedTileIds.isEmpty) {
            // No tiles with this tag, return empty grid
            return LdtkIntGrid(
              layerName: '${tileLayerName}_$enumTagName',
              grid: List.generate(cHei, (_) => List.filled(cWid, 0)),
              cellSize: gridSize,
            );
          }

          // Create a grid marking tiles with the enum tag
          final grid = List.generate(cHei, (_) => List.filled(cWid, 0));

          for (final tile in gridTiles) {
            final tileId = tile['t'] as int?;
            final px = tile['px'] as List?;

            if (tileId != null &&
                px != null &&
                px.length >= 2 &&
                taggedTileIds.contains(tileId)) {
              final x = (px[0] as int) ~/ gridSize;
              final y = (px[1] as int) ~/ gridSize;

              if (x >= 0 && x < cWid && y >= 0 && y < cHei) {
                grid[y][x] = 1;
              }
            }
          }

          return LdtkIntGrid(
            layerName: '${tileLayerName}_$enumTagName',
            grid: grid,
            cellSize: gridSize,
          );
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Loads tile enum grids and returns an updated LdtkLevel with the loaded grids.
  ///
  /// [enumGrids] is a map of grid name -> (tileLayerName, enumTagName).
  ///
  /// Example:
  /// ```dart
  /// final level = await parser.loadTileEnumGrids(
  ///   'assets/maps/level0.ldtkl',
  ///   level,
  ///   {
  ///     'Deadly': ('Tiles', 'Deadly'),
  ///     'Slippery': ('Tiles', 'Slippery'),
  ///   },
  /// );
  /// ```
  Future<LdtkLevel> loadTileEnumGrids(
    String ldtklPath,
    LdtkLevel level,
    Map<String, (String, String)> enumGrids, {
    String? assetBasePath,
  }) async {
    final Map<String, LdtkIntGrid> intGrids = {...level.intGrids};

    for (final entry in enumGrids.entries) {
      final gridName = entry.key;
      final (tileLayerName, enumTagName) = entry.value;

      final enumGrid = await loadTileEnumGrid(
        ldtklPath,
        enumTagName,
        tileLayerName,
        assetBasePath: assetBasePath,
      );

      if (enumGrid != null) {
        intGrids[gridName] = enumGrid;
      }
    }

    return LdtkLevel(
      name: level.name,
      width: level.width,
      height: level.height,
      bgColor: level.bgColor,
      entities: level.entities,
      intGrids: intGrids,
      customData: level.customData,
    );
  }
}
