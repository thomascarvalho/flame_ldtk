import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../components/json_level.dart';
import '../components/player.dart';

/// A game that demonstrates loading LDtk JSON format.
class JsonGame extends FlameGame with KeyboardEvents {
  Player? player;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Load the level from JSON format
    final level = JsonLevel();
    await level.loadLevel(
      'assets/world.ldtk',
      'Level_0',
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
