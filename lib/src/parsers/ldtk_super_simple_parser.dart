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
  Future<LdtkLevel> parseLevel(String levelPath) async {
    final dataJsonPath = '$levelPath/data.json';
    return await parseDataJson(dataJsonPath);
  }

  /// Loads the composite image for a level.
  Future<ui.Image> loadComposite(String path) async {
    return LdtkParserUtils.loadImage(path);
  }

  /// Parses entities and metadata from data.json.
  ///
  /// Throws [Exception] if the file cannot be loaded or parsed.
  Future<LdtkLevel> parseDataJson(String path) async {
    final cached = _levelCache.get(path);
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

      // Parse background color from hex string
      final bgColor = LdtkParserUtils.parseHexColor(bgColorStr);

      // Parse entities
      final List<LdtkEntity> entities = [];
      final entitiesData = json['entities'] as Map<String, dynamic>? ?? {};

      for (final entry in entitiesData.entries) {
        // final entityType = entry.key;
        final entityList = entry.value as List;

        for (final entityData in entityList) {
          final entity = _parseEntity(entityData as Map<String, dynamic>);
          entities.add(entity);
        }
      }

      final level = LdtkLevel(
        name: name,
        width: width,
        height: height,
        bgColor: bgColor,
        entities: entities,
        customData: customFields,
      );

      _levelCache.put(path, level);
      return level;
    } catch (e) {
      throw Exception('Failed to parse data.json at "$path": $e');
    }
  }

  /// Helper method to parse a single entity from JSON.
  LdtkEntity _parseEntity(Map<String, dynamic> json) {
    final identifier = json['id'] as String;
    final x = (json['x'] as num).toDouble();
    final y = (json['y'] as num).toDouble();
    final width = (json['width'] as num).toDouble();
    final height = (json['height'] as num).toDouble();
    final customFields = json['customFields'] as Map<String, dynamic>? ?? {};

    return LdtkEntity(
      identifier: identifier,
      position: Vector2(x, y),
      size: Vector2(width, height),
      fields: customFields,
      color: LdtkParserUtils.parseIntColor(json['color'] as int?),
    );
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
    bool hasTrailingZeros = true;

    for (final row in csvData) {
      if (row.isEmpty) continue;

      final intRow = [
        for (final cell in row)
          cell is int ? cell : int.tryParse(cell.toString()) ?? 0
      ];

      // Check if this row breaks the trailing zero pattern
      if (hasTrailingZeros && intRow.isNotEmpty && intRow.last != 0) {
        hasTrailingZeros = false;
      }

      grid.add(intRow);
    }

    // Remove trailing empty column if all rows have it (from trailing comma in LDtk CSV export)
    if (hasTrailingZeros && grid.isNotEmpty) {
      for (int i = 0; i < grid.length; i++) {
        if (grid[i].isNotEmpty) {
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
}
