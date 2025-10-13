/// Models for LDtk JSON format (non-simplified export).
///
/// These models represent the structure of LDtk project files (.ldtk and .ldtkl).
library;

/// Root LDtk project structure.
class LdtkJson {
  final String jsonVersion;
  final bool externalLevels;
  final bool simplifiedExport;
  final LdtkDefinitions defs;
  final List<LdtkJsonLevel> levels;

  const LdtkJson({
    required this.jsonVersion,
    required this.externalLevels,
    required this.simplifiedExport,
    required this.defs,
    required this.levels,
  });

  factory LdtkJson.fromJson(Map<String, dynamic> json) {
    try {
      return LdtkJson(
        jsonVersion: json['jsonVersion'] as String? ?? 'unknown',
        externalLevels: json['externalLevels'] as bool? ?? false,
        simplifiedExport: json['simplifiedExport'] as bool? ?? false,
        defs: LdtkDefinitions.fromJson(
            json['defs'] as Map<String, dynamic>? ?? {}),
        levels: (json['levels'] as List? ?? [])
            .map((e) => LdtkJsonLevel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } catch (e) {
      throw Exception('Failed to parse LdtkJson: $e');
    }
  }
}

/// LDtk definitions (layers, entities, tilesets, etc.).
class LdtkDefinitions {
  final List<LdtkLayerDef> layers;
  final List<LdtkEntityDef> entities;
  final List<LdtkTilesetDef> tilesets;

  const LdtkDefinitions({
    required this.layers,
    required this.entities,
    required this.tilesets,
  });

  factory LdtkDefinitions.fromJson(Map<String, dynamic> json) {
    try {
      return LdtkDefinitions(
        layers: (json['layers'] as List? ?? [])
            .map((e) => LdtkLayerDef.fromJson(e as Map<String, dynamic>))
            .toList(),
        entities: (json['entities'] as List? ?? [])
            .map((e) => LdtkEntityDef.fromJson(e as Map<String, dynamic>))
            .toList(),
        tilesets: (json['tilesets'] as List? ?? [])
            .map((e) => LdtkTilesetDef.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } catch (e) {
      throw Exception('Failed to parse LdtkDefinitions: $e');
    }
  }
}

/// Layer definition.
class LdtkLayerDef {
  final String identifier;
  final String type;
  final int uid;
  final int gridSize;

  const LdtkLayerDef({
    required this.identifier,
    required this.type,
    required this.uid,
    required this.gridSize,
  });

  factory LdtkLayerDef.fromJson(Map<String, dynamic> json) {
    return LdtkLayerDef(
      identifier: json['identifier'] as String,
      type: json['type'] as String,
      uid: json['uid'] as int,
      gridSize: json['gridSize'] as int,
    );
  }
}

/// Entity definition.
class LdtkEntityDef {
  final String identifier;
  final int uid;
  final int width;
  final int height;

  const LdtkEntityDef({
    required this.identifier,
    required this.uid,
    required this.width,
    required this.height,
  });

  factory LdtkEntityDef.fromJson(Map<String, dynamic> json) {
    return LdtkEntityDef(
      identifier: json['identifier'] as String,
      uid: json['uid'] as int,
      width: json['width'] as int,
      height: json['height'] as int,
    );
  }
}

/// Tileset enum tag definition.
class LdtkEnumTag {
  final String enumValueId;
  final List<int> tileIds;

  const LdtkEnumTag({
    required this.enumValueId,
    required this.tileIds,
  });

  factory LdtkEnumTag.fromJson(Map<String, dynamic> json) {
    return LdtkEnumTag(
      enumValueId: json['enumValueId'] as String,
      tileIds: (json['tileIds'] as List? ?? []).map((e) => e as int).toList(),
    );
  }
}

/// Tileset definition.
class LdtkTilesetDef {
  final String identifier;
  final int uid;
  final int tileGridSize;
  final String? relPath;
  final int pxWid;
  final int pxHei;
  final List<LdtkEnumTag> enumTags;

  const LdtkTilesetDef({
    required this.identifier,
    required this.uid,
    required this.tileGridSize,
    this.relPath,
    required this.pxWid,
    required this.pxHei,
    this.enumTags = const [],
  });

  factory LdtkTilesetDef.fromJson(Map<String, dynamic> json) {
    return LdtkTilesetDef(
      identifier: json['identifier'] as String,
      uid: json['uid'] as int,
      tileGridSize: json['tileGridSize'] as int,
      relPath: json['relPath'] as String?,
      pxWid: json['pxWid'] as int,
      pxHei: json['pxHei'] as int,
      enumTags: (json['enumTags'] as List? ?? [])
          .map((e) => LdtkEnumTag.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Returns all tile IDs that have a specific enum tag.
  List<int> getTileIdsWithTag(String tagName) {
    for (final tag in enumTags) {
      if (tag.enumValueId == tagName) {
        return tag.tileIds;
      }
    }
    return [];
  }

  /// Checks if a tile ID has a specific enum tag.
  bool tileHasTag(int tileId, String tagName) {
    final tileIds = getTileIdsWithTag(tagName);
    return tileIds.contains(tileId);
  }
}

/// Level in LDtk JSON format.
class LdtkJsonLevel {
  final String identifier;
  final int pxWid;
  final int pxHei;
  final String? bgColor;
  final String? externalRelPath;
  final List<LdtkLayerInstance>? layerInstances;
  final List<dynamic> fieldInstances;

  // Background image properties
  final String? bgRelPath;
  final String? bgPos;
  final double? bgPivotX;
  final double? bgPivotY;

  const LdtkJsonLevel({
    required this.identifier,
    required this.pxWid,
    required this.pxHei,
    this.bgColor,
    this.externalRelPath,
    this.layerInstances,
    required this.fieldInstances,
    this.bgRelPath,
    this.bgPos,
    this.bgPivotX,
    this.bgPivotY,
  });

  factory LdtkJsonLevel.fromJson(Map<String, dynamic> json) {
    try {
      return LdtkJsonLevel(
        identifier: json['identifier'] as String? ?? 'unknown',
        pxWid: json['pxWid'] as int? ?? 0,
        pxHei: json['pxHei'] as int? ?? 0,
        bgColor: json['__bgColor'] as String? ?? json['bgColor'] as String?,
        externalRelPath: json['externalRelPath'] as String?,
        layerInstances: json['layerInstances'] == null
            ? null
            : (json['layerInstances'] as List)
                .map((e) =>
                    LdtkLayerInstance.fromJson(e as Map<String, dynamic>))
                .toList(),
        fieldInstances: json['fieldInstances'] as List? ?? [],
        bgRelPath: json['bgRelPath'] as String?,
        bgPos: json['bgPos'] as String?,
        bgPivotX: (json['bgPivotX'] as num?)?.toDouble(),
        bgPivotY: (json['bgPivotY'] as num?)?.toDouble(),
      );
    } catch (e) {
      throw Exception('Failed to parse LdtkJsonLevel: $e');
    }
  }
}

/// Layer instance in a level.
class LdtkLayerInstance {
  final String identifier;
  final String type;
  final int gridSize;
  final List<LdtkEntityInstance> entityInstances;
  final List<LdtkTileInstance> gridTiles;
  final List<int> intGridCsv;
  final int cWid;
  final int cHei;
  final int? tilesetDefUid;
  final String? tilesetRelPath;

  const LdtkLayerInstance({
    required this.identifier,
    required this.type,
    required this.gridSize,
    required this.entityInstances,
    required this.gridTiles,
    required this.intGridCsv,
    required this.cWid,
    required this.cHei,
    this.tilesetDefUid,
    this.tilesetRelPath,
  });

  factory LdtkLayerInstance.fromJson(Map<String, dynamic> json) {
    return LdtkLayerInstance(
      identifier: json['__identifier'] as String,
      type: json['__type'] as String,
      gridSize: json['__gridSize'] as int,
      cWid: json['__cWid'] as int,
      cHei: json['__cHei'] as int,
      tilesetDefUid: json['__tilesetDefUid'] as int?,
      tilesetRelPath: json['__tilesetRelPath'] as String?,
      entityInstances: (json['entityInstances'] as List? ?? [])
          .map((e) => LdtkEntityInstance.fromJson(e as Map<String, dynamic>))
          .toList(),
      gridTiles: (json['gridTiles'] as List? ?? [])
          .map((e) => LdtkTileInstance.fromJson(e as Map<String, dynamic>))
          .toList(),
      intGridCsv:
          (json['intGridCsv'] as List? ?? []).map((e) => e as int).toList(),
    );
  }
}

/// Entity instance in a layer.
class LdtkEntityInstance {
  final String identifier;
  final List<int> px;
  final int width;
  final int height;
  final List<dynamic> fieldInstances;
  final String? smartColor;
  final LdtkEntityTile? tile;
  final List<double> pivot;

  const LdtkEntityInstance({
    required this.identifier,
    required this.px,
    required this.width,
    required this.height,
    required this.fieldInstances,
    this.smartColor,
    this.tile,
    this.pivot = const [0, 0],
  });

  factory LdtkEntityInstance.fromJson(Map<String, dynamic> json) {
    return LdtkEntityInstance(
      identifier: json['__identifier'] as String,
      px: (json['px'] as List).map((e) => e as int).toList(),
      width: json['width'] as int,
      height: json['height'] as int,
      fieldInstances: json['fieldInstances'] as List? ?? [],
      smartColor: json['__smartColor'] as String?,
      tile: json['__tile'] != null
          ? LdtkEntityTile.fromJson(json['__tile'] as Map<String, dynamic>)
          : null,
      pivot: json['__pivot'] != null
          ? (json['__pivot'] as List).map((e) => (e as num).toDouble()).toList()
          : [0, 0],
    );
  }
}

/// Tile instance in a tile layer.
class LdtkTileInstance {
  final List<int> px;
  final List<int> src;
  final int f;
  final int t;

  const LdtkTileInstance({
    required this.px,
    required this.src,
    required this.f,
    required this.t,
  });

  factory LdtkTileInstance.fromJson(Map<String, dynamic> json) {
    return LdtkTileInstance(
      px: (json['px'] as List).map((e) => e as int).toList(),
      src: (json['src'] as List).map((e) => e as int).toList(),
      f: json['f'] as int,
      t: json['t'] as int,
    );
  }
}

/// Entity tile information.
class LdtkEntityTile {
  final int tilesetUid;
  final int x;
  final int y;
  final int w;
  final int h;

  const LdtkEntityTile({
    required this.tilesetUid,
    required this.x,
    required this.y,
    required this.w,
    required this.h,
  });

  factory LdtkEntityTile.fromJson(Map<String, dynamic> json) {
    return LdtkEntityTile(
      tilesetUid: json['tilesetUid'] as int,
      x: json['x'] as int,
      y: json['y'] as int,
      w: json['w'] as int,
      h: json['h'] as int,
    );
  }
}
