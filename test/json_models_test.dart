import 'package:flutter_test/flutter_test.dart';
import 'package:flame_ldtk/src/models/ldtk_json_models.dart';

void main() {
  group('LdtkJson', () {
    test('fromJson creates instance with valid data', () {
      final json = {
        'jsonVersion': '1.5.3',
        'externalLevels': true,
        'simplifiedExport': false,
        'defs': {
          'layers': [],
          'entities': [],
          'tilesets': [],
        },
        'levels': [],
      };

      final ldtkJson = LdtkJson.fromJson(json);

      expect(ldtkJson.jsonVersion, '1.5.3');
      expect(ldtkJson.externalLevels, true);
      expect(ldtkJson.simplifiedExport, false);
      expect(ldtkJson.defs.layers, isEmpty);
      expect(ldtkJson.levels, isEmpty);
    });

    test('fromJson handles missing optional fields', () {
      final json = <String, dynamic>{
        'defs': <String, dynamic>{},
        'levels': [],
      };

      final ldtkJson = LdtkJson.fromJson(json);

      expect(ldtkJson.jsonVersion, 'unknown');
      expect(ldtkJson.externalLevels, false);
      expect(ldtkJson.simplifiedExport, false);
    });
  });

  group('LdtkDefinitions', () {
    test('fromJson creates instance with all definitions', () {
      final json = {
        'layers': [
          {
            'identifier': 'Ground',
            'type': 'Tiles',
            'uid': 1,
            'gridSize': 16,
          }
        ],
        'entities': [
          {
            'identifier': 'Player',
            'uid': 10,
            'width': 16,
            'height': 16,
          }
        ],
        'tilesets': [
          {
            'identifier': 'Tileset',
            'uid': 100,
            'tileGridSize': 16,
            'pxWid': 256,
            'pxHei': 256,
          }
        ],
      };

      final defs = LdtkDefinitions.fromJson(json);

      expect(defs.layers, hasLength(1));
      expect(defs.entities, hasLength(1));
      expect(defs.tilesets, hasLength(1));
    });

    test('fromJson handles empty definitions', () {
      final json = <String, dynamic>{};

      final defs = LdtkDefinitions.fromJson(json);

      expect(defs.layers, isEmpty);
      expect(defs.entities, isEmpty);
      expect(defs.tilesets, isEmpty);
    });

    test('fromJson throws on invalid layer data', () {
      final json = {
        'layers': [
          {'invalid': 'data'}
        ],
      };

      expect(
        () => LdtkDefinitions.fromJson(json),
        throwsException,
      );
    });
  });

  group('LdtkLayerDef', () {
    test('fromJson creates instance correctly', () {
      final json = {
        'identifier': 'Collisions',
        'type': 'IntGrid',
        'uid': 5,
        'gridSize': 8,
      };

      final layerDef = LdtkLayerDef.fromJson(json);

      expect(layerDef.identifier, 'Collisions');
      expect(layerDef.type, 'IntGrid');
      expect(layerDef.uid, 5);
      expect(layerDef.gridSize, 8);
    });
  });

  group('LdtkEntityDef', () {
    test('fromJson creates instance correctly', () {
      final json = {
        'identifier': 'Enemy',
        'uid': 20,
        'width': 32,
        'height': 32,
      };

      final entityDef = LdtkEntityDef.fromJson(json);

      expect(entityDef.identifier, 'Enemy');
      expect(entityDef.uid, 20);
      expect(entityDef.width, 32);
      expect(entityDef.height, 32);
    });
  });

  group('LdtkTilesetDef', () {
    test('fromJson creates instance with relPath', () {
      final json = {
        'identifier': 'Atlas',
        'uid': 50,
        'tileGridSize': 16,
        'relPath': 'assets/atlas.png',
        'pxWid': 512,
        'pxHei': 512,
      };

      final tilesetDef = LdtkTilesetDef.fromJson(json);

      expect(tilesetDef.identifier, 'Atlas');
      expect(tilesetDef.uid, 50);
      expect(tilesetDef.tileGridSize, 16);
      expect(tilesetDef.relPath, 'assets/atlas.png');
      expect(tilesetDef.pxWid, 512);
      expect(tilesetDef.pxHei, 512);
    });

    test('fromJson handles null relPath', () {
      final json = {
        'identifier': 'Atlas',
        'uid': 50,
        'tileGridSize': 16,
        'pxWid': 256,
        'pxHei': 256,
      };

      final tilesetDef = LdtkTilesetDef.fromJson(json);

      expect(tilesetDef.relPath, isNull);
    });
  });

  group('LdtkJsonLevel', () {
    test('fromJson creates instance with all properties', () {
      final json = {
        'identifier': 'Level_0',
        'pxWid': 320,
        'pxHei': 240,
        '__bgColor': '#6A7495',
        'fieldInstances': [],
        'bgRelPath': 'bg.png',
        'bgPos': 'Cover',
        'bgPivotX': 0.5,
        'bgPivotY': 0.5,
      };

      final level = LdtkJsonLevel.fromJson(json);

      expect(level.identifier, 'Level_0');
      expect(level.pxWid, 320);
      expect(level.pxHei, 240);
      expect(level.bgColor, '#6A7495');
      expect(level.bgRelPath, 'bg.png');
      expect(level.bgPos, 'Cover');
      expect(level.bgPivotX, 0.5);
      expect(level.bgPivotY, 0.5);
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'fieldInstances': [],
      };

      final level = LdtkJsonLevel.fromJson(json);

      expect(level.identifier, 'unknown');
      expect(level.pxWid, 0);
      expect(level.pxHei, 0);
      expect(level.bgColor, isNull);
      expect(level.externalRelPath, isNull);
      expect(level.layerInstances, isNull);
      expect(level.bgRelPath, isNull);
      expect(level.bgPos, isNull);
    });

    test('fromJson parses layerInstances correctly', () {
      final json = {
        'identifier': 'Level_0',
        'pxWid': 160,
        'pxHei': 160,
        'fieldInstances': [],
        'layerInstances': [
          {
            '__identifier': 'Entities',
            '__type': 'Entities',
            '__gridSize': 16,
            '__cWid': 10,
            '__cHei': 10,
            'entityInstances': [],
            'gridTiles': [],
            'intGridCsv': [],
          }
        ],
      };

      final level = LdtkJsonLevel.fromJson(json);

      expect(level.layerInstances, isNotNull);
      expect(level.layerInstances, hasLength(1));
      expect(level.layerInstances!.first.identifier, 'Entities');
    });
  });

  group('LdtkLayerInstance', () {
    test('fromJson creates instance with all properties', () {
      final json = {
        '__identifier': 'Ground',
        '__type': 'Tiles',
        '__gridSize': 16,
        '__cWid': 20,
        '__cHei': 15,
        '__tilesetDefUid': 42,
        '__tilesetRelPath': 'tileset.png',
        'entityInstances': [],
        'gridTiles': [],
        'intGridCsv': [0, 1, 0, 1],
      };

      final layer = LdtkLayerInstance.fromJson(json);

      expect(layer.identifier, 'Ground');
      expect(layer.type, 'Tiles');
      expect(layer.gridSize, 16);
      expect(layer.cWid, 20);
      expect(layer.cHei, 15);
      expect(layer.tilesetDefUid, 42);
      expect(layer.tilesetRelPath, 'tileset.png');
      expect(layer.intGridCsv, [0, 1, 0, 1]);
    });

    test('fromJson handles empty arrays', () {
      final json = {
        '__identifier': 'Test',
        '__type': 'IntGrid',
        '__gridSize': 8,
        '__cWid': 10,
        '__cHei': 10,
      };

      final layer = LdtkLayerInstance.fromJson(json);

      expect(layer.entityInstances, isEmpty);
      expect(layer.gridTiles, isEmpty);
      expect(layer.intGridCsv, isEmpty);
    });

    test('fromJson parses entity instances', () {
      final json = {
        '__identifier': 'Entities',
        '__type': 'Entities',
        '__gridSize': 16,
        '__cWid': 10,
        '__cHei': 10,
        'entityInstances': [
          {
            '__identifier': 'Player',
            'px': [80, 80],
            'width': 16,
            'height': 16,
            'fieldInstances': [],
          }
        ],
        'gridTiles': [],
        'intGridCsv': [],
      };

      final layer = LdtkLayerInstance.fromJson(json);

      expect(layer.entityInstances, hasLength(1));
      expect(layer.entityInstances.first.identifier, 'Player');
    });

    test('fromJson parses grid tiles', () {
      final json = {
        '__identifier': 'Tiles',
        '__type': 'Tiles',
        '__gridSize': 16,
        '__cWid': 10,
        '__cHei': 10,
        'entityInstances': [],
        'gridTiles': [
          {
            'px': [0, 0],
            'src': [16, 16],
            'f': 0,
            't': 1,
          }
        ],
        'intGridCsv': [],
      };

      final layer = LdtkLayerInstance.fromJson(json);

      expect(layer.gridTiles, hasLength(1));
      expect(layer.gridTiles.first.px, [0, 0]);
    });
  });

  group('LdtkEntityInstance', () {
    test('fromJson creates instance correctly', () {
      final json = {
        '__identifier': 'Chest',
        'px': [100, 200],
        'width': 24,
        'height': 24,
        'fieldInstances': [
          {'__identifier': 'gold', '__value': 100}
        ],
        '__smartColor': '#FFD700',
      };

      final entity = LdtkEntityInstance.fromJson(json);

      expect(entity.identifier, 'Chest');
      expect(entity.px, [100, 200]);
      expect(entity.width, 24);
      expect(entity.height, 24);
      expect(entity.fieldInstances, hasLength(1));
      expect(entity.smartColor, '#FFD700');
    });

    test('fromJson handles empty field instances', () {
      final json = {
        '__identifier': 'Enemy',
        'px': [50, 50],
        'width': 16,
        'height': 16,
      };

      final entity = LdtkEntityInstance.fromJson(json);

      expect(entity.fieldInstances, isEmpty);
      expect(entity.smartColor, isNull);
    });
  });

  group('LdtkTileInstance', () {
    test('fromJson creates instance correctly', () {
      final json = {
        'px': [32, 48],
        'src': [64, 80],
        'f': 1,
        't': 42,
      };

      final tile = LdtkTileInstance.fromJson(json);

      expect(tile.px, [32, 48]);
      expect(tile.src, [64, 80]);
      expect(tile.f, 1);
      expect(tile.t, 42);
    });
  });
}
