import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../components/platformer_level.dart';
import '../components/player.dart';

/// A simple platformer game demonstrating flame_ldtk usage.
class PlatformerGame extends FlameGame with KeyboardEvents {
  Player? player;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Load the level with collision layer
    final level = PlatformerLevel();
    await level.loadLevel(
      'assets/world/simplified/Level_0',
      intGridLayers: ['Collisions'],
    );

    await add(level);

    // Store player reference for input handling
    player = level.player;

    // Center camera on the level
    camera.viewfinder.position = Vector2(
      level.levelData!.width / 2,
      level.levelData!.height / 2,
    );
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    player?.handleInput(keysPressed);
    return KeyEventResult.handled;
  }
}
