import 'dart:convert';
import 'dart:ui' as ui;
import 'package:csv/csv.dart';
import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import '../models/ldtk_level.dart';
import '../models/ldtk_entity.dart';
import '../models/ldtk_intgrid.dart';

/// Parser for LDtk Super Simple Export format.
class LdtkSuperSimpleParser {
  // Cache for loaded assets
  static final Map<String, ui.Image> _imageCache = {};
  static final Map<String, LdtkLevel> _levelCache = {};
  static final Map<String, String> _stringCache = {};

  /// Clears all caches. Useful for hot-reload or memory management.
  static void clearCache() {
    _imageCache.clear();
    _levelCache.clear();
    _stringCache.clear();
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
    if (_imageCache.containsKey(path)) {
      return _imageCache[path]!;
    }

    final data = await rootBundle.load(path);
    final bytes = data.buffer.asUint8List();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    _imageCache[path] = image;
    return image;
  }

  /// Parses entities and metadata from data.json.
  Future<LdtkLevel> parseDataJson(String path) async {
    if (_levelCache.containsKey(path)) {
      return _levelCache[path]!;
    }

    final jsonString = await rootBundle.loadString(path);
    final json = jsonDecode(jsonString) as Map<String, dynamic>;

    // Parse metadata
    final name = json['identifier'] as String;
    final width = json['width'] as int;
    final height = json['height'] as int;
    final bgColorStr = json['bgColor'] as String?;
    final customFields = json['customFields'] as Map<String, dynamic>? ?? {};

    // Parse background color from hex string
    Color? bgColor;
    if (bgColorStr != null && bgColorStr.startsWith('#')) {
      final hex = bgColorStr.substring(1);
      bgColor = Color(int.parse('FF$hex', radix: 16));
    }

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

    _levelCache[path] = level;
    return level;
  }

  /// Helper method to parse a single entity from JSON.
  LdtkEntity _parseEntity(Map<String, dynamic> json) {
    final identifier = json['id'] as String;
    final x = (json['x'] as num).toDouble();
    final y = (json['y'] as num).toDouble();
    final width = (json['width'] as num).toDouble();
    final height = (json['height'] as num).toDouble();
    final customFields = json['customFields'] as Map<String, dynamic>? ?? {};

    // Parse color from integer
    Color? color;
    final colorInt = json['color'] as int?;
    if (colorInt != null) {
      color = Color(0xFF000000 | colorInt);
    }

    return LdtkEntity(
      identifier: identifier,
      position: Vector2(x, y),
      size: Vector2(width, height),
      fields: customFields,
      color: color,
    );
  }

  /// Parses an IntGrid layer from CSV format.
  Future<LdtkIntGrid> parseIntGridCsv(
      String path, String layerName, int cellSize) async {
    // Cache CSV string loading
    if (!_stringCache.containsKey(path)) {
      _stringCache[path] = await rootBundle.loadString(path);
    }
    final csvString = _stringCache[path]!;

    // Parse CSV with explicit line separator handling
    final csvData = const CsvToListConverter(
      eol: '\n',
      shouldParseNumbers: true,
    ).convert(csvString);

    // Convert CSV data to 2D grid of integers, filtering empty rows in one pass
    List<List<int>> grid = [];
    for (final row in csvData) {
      if (row.isEmpty) continue;
      grid.add([
        for (final cell in row)
          cell is int ? cell : int.tryParse(cell.toString()) ?? 0
      ]);
    }

    // Remove trailing empty column if all rows have it (from trailing comma in LDtk CSV export)
    if (grid.isNotEmpty &&
        grid.every((row) => row.isNotEmpty && row.last == 0)) {
      grid = grid.map((row) => row.sublist(0, row.length - 1)).toList();
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

      // Parse with temporary cellSize, will be recalculated after cleaning
      final intGrid = await parseIntGridCsv(csvPath, layerName, 1);

      // Use provided cellSize or calculate from grid dimensions
      final gridWidth = intGrid.width;
      final finalCellSize =
          cellSize ?? (gridWidth > 0 ? level.width ~/ gridWidth : 8);

      // Create new IntGrid with correct cellSize
      final correctedIntGrid = LdtkIntGrid(
        layerName: layerName,
        grid: intGrid.grid,
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
