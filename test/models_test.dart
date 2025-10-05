import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flame_ldtk/flame_ldtk.dart';

void main() {
  group('LdtkEntity', () {
    test('creates entity with correct values', () {
      final entity = LdtkEntity(
        identifier: 'Player',
        position: Vector2(10, 20),
        size: Vector2(16, 16),
        fields: const {'health': 100},
        color: Colors.blue,
      );

      expect(entity.identifier, 'Player');
      expect(entity.position, Vector2(10, 20));
      expect(entity.size, Vector2(16, 16));
      expect(entity.fields['health'], 100);
      expect(entity.color, Colors.blue);
    });

    test('creates entity with default fields', () {
      final entity = LdtkEntity(
        identifier: 'Enemy',
        position: Vector2.zero(),
        size: Vector2(32, 32),
      );

      expect(entity.fields, isEmpty);
      expect(entity.color, isNull);
    });
  });

  group('LdtkLevel', () {
    test('creates level with correct values', () {
      const level = LdtkLevel(
        name: 'Level_0',
        width: 256,
        height: 256,
        bgColor: Colors.black,
        entities: [],
        intGrids: {},
        customData: {},
      );

      expect(level.name, 'Level_0');
      expect(level.width, 256);
      expect(level.height, 256);
      expect(level.bgColor, Colors.black);
      expect(level.entities, isEmpty);
      expect(level.intGrids, isEmpty);
    });

    test('creates level with entities', () {
      final entity = LdtkEntity(
        identifier: 'Player',
        position: Vector2.zero(),
        size: Vector2(16, 16),
      );

      final level = LdtkLevel(
        name: 'Test',
        width: 100,
        height: 100,
        entities: [entity],
      );

      expect(level.entities, hasLength(1));
      expect(level.entities.first.identifier, 'Player');
    });
  });

  group('LdtkIntGrid', () {
    test('creates IntGrid with correct dimensions', () {
      final grid = LdtkIntGrid(
        layerName: 'Collisions',
        grid: [
          [0, 1, 0],
          [1, 1, 1],
          [0, 1, 0],
        ],
        cellSize: 8,
      );

      expect(grid.layerName, 'Collisions');
      expect(grid.cellSize, 8);
      expect(grid.width, 3);
      expect(grid.height, 3);
    });

    test('getValue returns correct cell values', () {
      final grid = LdtkIntGrid(
        layerName: 'Test',
        grid: [
          [0, 1, 0],
          [1, 0, 1],
        ],
        cellSize: 8,
      );

      expect(grid.getValue(0, 0), 0);
      expect(grid.getValue(1, 0), 1);
      expect(grid.getValue(2, 1), 1);
      expect(grid.getValue(1, 1), 0);
    });

    test('getValue returns 0 for out of bounds', () {
      final grid = LdtkIntGrid(
        layerName: 'Test',
        grid: [
          [1, 1],
          [1, 1],
        ],
        cellSize: 8,
      );

      expect(grid.getValue(-1, 0), 0);
      expect(grid.getValue(0, -1), 0);
      expect(grid.getValue(10, 10), 0);
    });

    test('isSolid returns correct values', () {
      final grid = LdtkIntGrid(
        layerName: 'Test',
        grid: [
          [0, 1],
          [1, 0],
        ],
        cellSize: 8,
      );

      expect(grid.isSolid(0, 0), false);
      expect(grid.isSolid(1, 0), true);
      expect(grid.isSolid(0, 1), true);
      expect(grid.isSolid(1, 1), false);
    });

    test('isSolidAtPixel returns correct values', () {
      final grid = LdtkIntGrid(
        layerName: 'Test',
        grid: [
          [0, 1],
          [1, 0],
        ],
        cellSize: 8,
      );

      // Cell (0, 0) is empty
      expect(grid.isSolidAtPixel(0, 0), false);
      expect(grid.isSolidAtPixel(7, 7), false);

      // Cell (1, 0) is solid
      expect(grid.isSolidAtPixel(8, 0), true);
      expect(grid.isSolidAtPixel(15, 7), true);

      // Cell (0, 1) is solid
      expect(grid.isSolidAtPixel(0, 8), true);
      expect(grid.isSolidAtPixel(7, 15), true);

      // Cell (1, 1) is empty
      expect(grid.isSolidAtPixel(8, 8), false);
    });

    test('isSolidAtPixel handles cellSize of 0', () {
      final grid = LdtkIntGrid(
        layerName: 'Test',
        grid: [
          [1]
        ],
        cellSize: 0,
      );

      expect(grid.isSolidAtPixel(0, 0), false);
    });
  });
}
