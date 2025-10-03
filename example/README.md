# Flame LDtk Example

A simple platformer game demonstrating how to use the `flame_ldtk` package.

## Features

- Load LDtk levels with Super Simple Export
- Player movement and jumping
- Collision detection using IntGrid layers
- Entity spawning from LDtk editor

## Controls

- **Arrow Keys / WASD** - Move left/right
- **Space / W / Up Arrow** - Jump

## Running the Example

```bash
flutter run
```

## Project Structure

```
lib/
├── main.dart                    # App entry point
├── game/
│   └── platformer_game.dart    # Main game class
└── components/
    ├── platformer_level.dart   # Level component with entity spawning
    └── player.dart              # Player component with physics
```

## LDtk Level Setup

The example uses a level exported from LDtk with:
- **Entities layer** containing a Player entity
- **Collisions layer** (IntGrid) for solid tiles
- **Tiles layer** for visual rendering

The level is exported using LDtk's Super Simple Export format to `assets/world/simplified/Level_0/`.

## Key Concepts Demonstrated

### 1. Loading a Level

```dart
final level = PlatformerLevel();
await level.loadLevel(
  'assets/world/simplified/Level_0',
  intGridLayers: ['Collisions'],
);
```

### 2. Handling Entities

Override `onEntitiesLoaded()` to spawn custom components based on entity types:

```dart
@override
Future<void> onEntitiesLoaded(List<LdtkEntity> entities) async {
  for (final entity in entities) {
    if (entity.identifier == 'Player') {
      player = Player(entity, levelData!);
      await add(player!);
    }
  }
}
```

### 3. Collision Detection

Use IntGrid layers for collision detection:

```dart
final collisions = level.intGrids['Collisions'];
if (collisions.isSolidAtPixel(x, y)) {
  // Handle collision
}
```

### 4. Keyboard Input

Handle keyboard input at the game level and pass to player:

```dart
@override
KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keys) {
  player?.handleInput(keys);
  return KeyEventResult.handled;
}
```

## Extending the Example

You can extend this example by:

- Adding more entity types (enemies, collectables, etc.)
- Implementing level transitions
- Adding animations using sprites
- Creating a tilemap-based rendering system
- Adding sound effects and music
