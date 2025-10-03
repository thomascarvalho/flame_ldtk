import 'package:flutter/material.dart';

/// Represents an IntGrid layer from LDtk.
class LdtkIntGrid {
  /// The name of the IntGrid layer.
  final String layerName;

  /// The grid data as a 2D array [y][x].
  final List<List<int>> grid;

  /// The size of each grid cell in pixels.
  final int cellSize;

  /// Mapping of IntGrid values to their colors.
  final Map<int, Color> valueColors;

  const LdtkIntGrid({
    required this.layerName,
    required this.grid,
    required this.cellSize,
    this.valueColors = const {},
  });

  /// Gets the width of the grid in cells.
  int get width => grid.isNotEmpty ? grid[0].length : 0;

  /// Gets the height of the grid in cells.
  int get height => grid.length;

  /// Gets the grid value at the specified cell coordinates.
  /// Returns 0 if out of bounds.
  int getValue(int x, int y) {
    if (y < 0 || y >= grid.length || x < 0 || x >= grid[y].length) {
      return 0;
    }
    return grid[y][x];
  }

  /// Checks if a cell position has a non-zero value (typically solid).
  bool isSolid(int x, int y) {
    return getValue(x, y) != 0;
  }

  /// Checks if a pixel position collides with a solid cell.
  bool isSolidAtPixel(double pixelX, double pixelY) {
    if (cellSize <= 0) return false;
    final cellX = (pixelX / cellSize).floor();
    final cellY = (pixelY / cellSize).floor();
    return isSolid(cellX, cellY);
  }
}
