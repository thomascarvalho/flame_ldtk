import 'package:flame/components.dart';
import 'package:flame_ldtk/flame_ldtk.dart';
import 'package:flutter/material.dart';
import 'player.dart';

/// Custom level component for JSON format that handles entity instantiation.
class JsonLevel extends LdtkJsonLevelComponent {
  Player? player;

  @override
  Future<void> loadLevel(String projectPath, String levelIdentifier) async {
    // First, call super to load level data and trigger onEntitiesLoaded
    // BUT we'll add background/tiles in onEntitiesLoaded BEFORE adding player
    await super.loadLevel(projectPath, levelIdentifier);

    // Set component size
    size = Vector2(
      levelData!.width.toDouble(),
      levelData!.height.toDouble(),
    );

    // Load and render tile layers (will be added after entities, so we use priority)
    final parser = LdtkJsonParser();
    final tileLayers = await parser.loadTileLayers(projectPath, levelIdentifier);
    for (final tileLayer in tileLayers) {
      final tileLayerComponent = LdtkTileLayerComponent(tileLayer);
      tileLayerComponent.priority = -1; // Below entities
      await add(tileLayerComponent);
    }
  }

  @override
  Future<void> onEntitiesLoaded(List<LdtkEntity> entities) async {
    // Add background FIRST (lowest priority)
    if (levelData!.bgColor != null) {
      final bg = RectangleComponent(
        size: Vector2(levelData!.width.toDouble(), levelData!.height.toDouble()),
        paint: Paint()..color = levelData!.bgColor!,
      );
      bg.priority = -2; // Below everything
      await add(bg);
    }

    // Then add entities (default priority = 0, so above background and tiles)
    for (final entity in entities) {
      switch (entity.identifier) {
        case 'Player':
          player = Player(entity, levelData!);
          await add(player!);
          break;

        // Add more entity types here as needed
        // case 'Enemy':
        //   final enemy = Enemy(entity, levelData!);
        //   await add(enemy);
        //   break;
      }
    }
  }
}
