# flame_ldtk

A Flutter package for integrating [LDtk](https://ldtk.io/) levels into [Flame Engine](https://flame-engine.org/) games.

[![pub package](https://img.shields.io/pub/v/flame_ldtk.svg)](https://pub.dev/packages/flame_ldtk)

## Features

- 🎮 **Super Simple Export Support** - Optimized loading of LDtk levels using Super Simple Export format
- 🗺️ **Level Rendering** - Individual layer rendering with transparency support
- 🖼️ **Background Images** - Load background images from .ldtkl files (basic positioning modes)
- 🎯 **Entity Parsing** - Extract entities with positions, sizes, custom fields, and colors
- 🧱 **IntGrid Support** - CSV-based IntGrid for collisions and game logic
- 🎨 **Flexible Architecture** - Override hooks to customize entity rendering
- 📦 **Generic Design** - No built-in collision logic, adapt to your game type
- ⚡ **Optimized Performance** - LRU cache system and fast CSV parsing

> 📖 **Looking for JSON format support?** See [JSON_FORMAT.md](JSON_FORMAT.md) (experimental, not fully implemented)

## Installation

Add `flame_ldtk` to your `pubspec.yaml`:

```yaml
dependencies:
  flame: ^1.32.0
  flame_ldtk: ^0.2.0
```

## LDtk Setup

### Super Simple Export

1. Create your level in [LDtk](https://ldtk.io/)
2. Go to **Project Settings → Super Simple Export**
3. Enable **Super Simple Export**
4. Set your export path (e.g., `assets/world/simplified/`)
5. Save your project to generate the export files

Each exported level will contain:
- `_composite.png` - Complete level visual (optional, use individual layers instead)
- `[LayerName].png` - Individual layer images (e.g., `Tiles.png`)
- `data.json` - Level metadata and entities (lightweight, ~500B for simple levels)
- `[LayerName].csv` - IntGrid layers (for collisions, etc.)

**For background images:** Keep the `.ldtkl` file to read background configuration.

## Basic Usage

### 1. Add assets to pubspec.yaml

```yaml
flutter:
  assets:
    - assets/world/simplified/Level_0/
    - assets/world/Level_0.ldtkl        # Optional: for background images
    - assets/background.png              # Optional: your background image
```

### 2. Load a level in your game

**Basic usage:**
```dart
import 'package:flame/game.dart';
import 'package:flame_ldtk/flame_ldtk.dart';

class MyGame extends FlameGame {
  @override
  Future<void> onLoad() async {
    final level = LdtkLevelComponent();
    await level.loadLevel('assets/world/simplified/Level_0');
    await add(level);
  }
}
```

**With collisions and background image:**
```dart
import 'package:flame/game.dart';
import 'package:flame_ldtk/flame_ldtk.dart';

class MyGame extends FlameGame {
  @override
  Future<void> onLoad() async {
    final level = LdtkLevelComponent();
    await level.loadLevel(
      'assets/world/simplified/Level_0',
      intGridLayers: ['Collisions'],           // Load collision layer
      ldtklPath: 'assets/world/Level_0.ldtkl', // For background image
      assetBasePath: 'assets',                  // Where background images are located
      // useComposite: false,                   // Default: loads individual layers
    );
    await add(level);
  }
}
```

## Working with Entities

### Customize entity rendering

Override `onEntitiesLoaded()` to handle your entities:

```dart
class MyLevelComponent extends LdtkLevelComponent {
  @override
  Future<void> onEntitiesLoaded(List<LdtkEntity> entities) async {
    for (final entity in entities) {
      switch (entity.identifier) {
        case 'Player':
          final player = PlayerComponent(entity, levelData!);
          await add(player);
          break;

        case 'Enemy':
          final enemy = EnemyComponent(entity, levelData!);
          await add(enemy);
          break;

        case 'Coin':
          final coin = CoinComponent(entity);
          await add(coin);
          break;
      }
    }
  }
}
```

### Create entity components

```dart
class PlayerComponent extends PositionComponent {
  final LdtkEntity entity;
  final LdtkLevel level;

  PlayerComponent(this.entity, this.level) {
    position = entity.position;  // LDtk position
    size = entity.size;           // Entity size from LDtk
  }

  @override
  Future<void> onLoad() async {
    // Render with entity color from LDtk
    final color = entity.color ?? Colors.blue;
    final rect = RectangleComponent(
      size: size,
      paint: Paint()..color = color,
    );
    await add(rect);
  }
}
```

### Access custom fields

```dart
class ChestComponent extends PositionComponent {
  final LdtkEntity entity;

  ChestComponent(this.entity) {
    position = entity.position;
    size = entity.size;

    // Access custom fields defined in LDtk
    final loot = entity.fields['loot'] as String? ?? 'gold';
    final amount = entity.fields['amount'] as int? ?? 10;

    print('Chest contains $amount $loot');
  }
}
```

## Working with IntGrid (Collisions)

### Load IntGrid layers

```dart
class MyLevelComponent extends LdtkLevelComponent {
  @override
  Future<void> onLoad() async {
    // Load level with collision layer
    await loadLevel(
      'assets/world/simplified/Level_0',
      intGridLayers: ['Collisions'],  // Load IntGrid layers
    );
  }
}
```

### Implement collision detection

```dart
class PlayerComponent extends PositionComponent {
  final LdtkLevel level;
  Vector2 velocity = Vector2.zero();

  @override
  void update(double dt) {
    final collisions = level.intGrids['Collisions'];
    if (collisions == null) return;

    // Calculate new position
    final newX = position.x + velocity.x * dt;
    final newY = position.y + velocity.y * dt;

    // Check horizontal collision
    if (_canMoveTo(collisions, newX, position.y)) {
      position.x = newX;
    }

    // Check vertical collision
    if (_canMoveTo(collisions, position.x, newY)) {
      position.y = newY;
    }
  }

  bool _canMoveTo(LdtkIntGrid grid, double x, double y) {
    // Check four corners of player hitbox
    final corners = [
      Vector2(x, y),                      // Top-left
      Vector2(x + size.x, y),             // Top-right
      Vector2(x, y + size.y),             // Bottom-left
      Vector2(x + size.x, y + size.y),    // Bottom-right
    ];

    for (final corner in corners) {
      if (grid.isSolidAtPixel(corner.x, corner.y)) {
        return false; // Collision detected
      }
    }
    return true; // Can move
  }
}
```

### IntGrid helper methods

```dart
final grid = level.intGrids['Collisions']!;

// Check by pixel position
bool solid = grid.isSolidAtPixel(128.5, 64.0);

// Check by grid cell
bool solid = grid.isSolid(16, 8);  // Cell coordinates

// Get cell value
int value = grid.getValue(16, 8);  // Returns 0 for empty, 1+ for solid

// Grid properties
int cellSize = grid.cellSize;     // Size of each cell in pixels
int width = grid.width;            // Grid width in cells
int height = grid.height;          // Grid height in cells
```

## Complete Platformer Example

```dart
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flutter/services.dart';
import 'package:flame_ldtk/flame_ldtk.dart';

class PlatformerGame extends FlameGame with KeyboardEvents {
  PlayerComponent? player;

  @override
  Future<void> onLoad() async {
    final level = MyLevelComponent();
    await level.loadLevel(
      'assets/world/simplified/Level_0',
      intGridLayers: ['Collisions'],
    );
    await add(level);
    player = level.player;
  }

  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keys) {
    player?.onKeyEvent(event, keys);
    return KeyEventResult.handled;
  }
}

class MyLevelComponent extends LdtkLevelComponent {
  PlayerComponent? player;

  @override
  Future<void> onEntitiesLoaded(List<LdtkEntity> entities) async {
    for (final entity in entities) {
      if (entity.identifier == 'Player') {
        player = PlayerComponent(entity, levelData!);
        await add(player!);
      }
    }
  }
}

class PlayerComponent extends PositionComponent {
  final LdtkEntity entity;
  final LdtkLevel level;

  // Physics
  static const double moveSpeed = 100.0;
  static const double jumpForce = -300.0;
  static const double gravity = 800.0;

  Vector2 velocity = Vector2.zero();
  bool isOnGround = false;
  bool isMovingLeft = false;
  bool isMovingRight = false;
  bool wantsToJump = false;

  PlayerComponent(this.entity, this.level) {
    position = entity.position;
    size = entity.size;
  }

  @override
  Future<void> onLoad() async {
    final rect = RectangleComponent(
      size: size,
      paint: Paint()..color = entity.color ?? Colors.blue,
    );
    await add(rect);
  }

  @override
  void update(double dt) {
    super.update(dt);

    final collisions = level.intGrids['Collisions'];
    if (collisions == null) return;

    // Horizontal movement
    velocity.x = (isMovingRight ? moveSpeed : 0) +
                 (isMovingLeft ? -moveSpeed : 0);

    // Jump
    if (wantsToJump && isOnGround) {
      velocity.y = jumpForce;
      isOnGround = false;
    }

    // Gravity
    velocity.y += gravity * dt;

    // Apply movement with collision detection
    final newX = position.x + velocity.x * dt;
    if (_canMoveTo(collisions, newX, position.y)) {
      position.x = newX;
    }

    final newY = position.y + velocity.y * dt;
    if (_canMoveTo(collisions, position.x, newY)) {
      position.y = newY;
      isOnGround = false;
    } else {
      if (velocity.y > 0) isOnGround = true;
      velocity.y = 0;
    }
  }

  bool _canMoveTo(LdtkIntGrid grid, double x, double y) {
    return !grid.isSolidAtPixel(x, y) &&
           !grid.isSolidAtPixel(x + size.x, y) &&
           !grid.isSolidAtPixel(x, y + size.y) &&
           !grid.isSolidAtPixel(x + size.x, y + size.y);
  }

  void onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keys) {
    isMovingLeft = keys.contains(LogicalKeyboardKey.arrowLeft);
    isMovingRight = keys.contains(LogicalKeyboardKey.arrowRight);
    wantsToJump = keys.contains(LogicalKeyboardKey.space);
  }
}
```

## API Reference

### LdtkLevelComponent

Main component for loading and displaying LDtk levels.

```dart
// Load a level
await levelComponent.loadLevel(
  'assets/world/simplified/Level_0',
  intGridLayers: ['Collisions', 'Water'],  // Optional
);

// Access level data
LdtkLevel? data = levelComponent.levelData;

// Override to customize entity creation
@override
Future<void> onEntitiesLoaded(List<LdtkEntity> entities) async {
  // Your custom entity creation logic
}
```

#### Background Images

Super Simple Export doesn't include background image metadata in its exported files. To use background images, you need to read the background configuration from the original `.ldtkl` file:

```dart
await levelComponent.loadLevel(
  'assets/world/simplified/Level_0',
  intGridLayers: ['Collisions'],
  ldtklPath: 'assets/world/Level_0.ldtkl',    // Path to .ldtkl file for background metadata
  assetBasePath: 'assets',                     // Base path for resolving background images
  useComposite: false,                         // Use individual layers for transparency
);
```

**Parameters:**
- `ldtklPath` - Path to the `.ldtkl` file containing background image configuration
- `assetBasePath` - Base path for resolving background image paths (useful when LDtk's `bgRelPath` is relative to a specific folder)
- `useComposite` - Set to `false` to load individual layer images instead of the composite (allows transparency for backgrounds to show through)

**Supported background positioning modes:**
- `Cover` - Background covers the entire level (default)
- `Contain` - Background is scaled to fit within level bounds while maintaining aspect ratio
- `Unscaled` - Background uses its original size

**Note:** Advanced LDtk background options (custom scale, crop rectangles) are not currently supported.

**Example in pubspec.yaml:**
```yaml
flutter:
  assets:
    - assets/world/simplified/Level_0/    # Super Simple Export files
    - assets/world/Level_0.ldtkl          # For background metadata
    - assets/background.png               # Your background image
```

### LdtkLevel

Contains all level data.

```dart
String name;                              // Level identifier
int width, height;                         // Level dimensions in pixels
Color? bgColor;                            // Background color
List<LdtkEntity> entities;                 // All entities
Map<String, LdtkIntGrid> intGrids;        // IntGrid layers by name
Map<String, dynamic> customData;          // Custom fields
```

### LdtkEntity

Represents an entity from LDtk.

```dart
String identifier;                         // Entity type (e.g., "Player")
Vector2 position;                          // Top-left position in pixels
Vector2 size;                              // Size in pixels
Map<String, dynamic> fields;              // Custom fields
Color? color;                              // Color from LDtk
```

### LdtkIntGrid

Grid-based collision/logic layer.

```dart
int cellSize;                              // Cell size in pixels
int width, height;                         // Grid dimensions in cells
bool isSolid(int x, int y);               // Check cell by grid coords
bool isSolidAtPixel(double x, double y);  // Check by pixel coords
int getValue(int x, int y);               // Get cell value (0 = empty)
```

## Tips & Best Practices

### 1. Use separate components for different entity types

```dart
class PlayerComponent extends LdtkEntityComponent { ... }
class EnemyComponent extends LdtkEntityComponent { ... }
class ItemComponent extends LdtkEntityComponent { ... }
```

### 2. Store level reference for collision access

```dart
class GameEntity extends PositionComponent {
  final LdtkLevel level;

  GameEntity(LdtkEntity entity, this.level) {
    position = entity.position;
    size = entity.size;
  }
}
```

### 3. Use custom fields for entity configuration

In LDtk, add custom fields to entities:
- `speed: Int` for movement speed
- `health: Int` for HP
- `loot: String` for item type

Access them in your components:
```dart
final speed = entity.fields['speed'] as int? ?? 100;
final health = entity.fields['health'] as int? ?? 3;
```

### 4. Handle different collision types

```dart
final collisions = level.intGrids['Collisions'];
final water = level.intGrids['Water'];
final spikes = level.intGrids['Hazards'];

if (collisions?.isSolidAtPixel(x, y) ?? false) {
  // Hit solid wall
}
if (water?.isSolidAtPixel(x, y) ?? false) {
  // In water, apply different physics
}
```

## Roadmap

> **Note:** I created this project for a game I'm currently developing. The roadmap may evolve based on my needs. The **Super Simple Export** mode is the most tested and stable format.

### ✅ Completed
- [x] Super Simple Export support
- [x] Custom fields extraction
- [x] LRU cache system with memory limits
- [x] Improved error handling with detailed messages
- [x] Individual Layer Rendering - Load and render tile layers separately (via `useComposite: false` by default)
- [x] Background Images (partial) - Basic positioning modes (Cover, Contain, Unscaled) supported. Advanced options (custom scale, crop rectangles) not yet implemented.
- [x] JSON Export support (experimental) - See [JSON_FORMAT.md](JSON_FORMAT.md)

### Planned features
- [ ] AutoLayers Support - Render auto-generated tile layers
- [ ] Multi-Level World System - World component with level switching and transitions
- [ ] Parallax Backgrounds - Support for parallax effects with background images
- [ ] Advanced Background Options - Custom scale and crop rectangle support
- [ ] Tile Animations - Animated tileset support with metadata parsing

### Other ideas
- [ ] Entity Registry/Factory - Automatic entity-to-component mapping system
- [ ] Collision Generation from IntGrid - Automatic hitbox generation (polygons/rectangles)
- [ ] Hot Reload Support - Watch LDtk files and reload in development
- [ ] Debug Renderer - Visualize grids, entity bounds, collisions, and IntGrid values
- [ ] Level Transitions - Fade, slide, and custom transition effects
- [ ] Platformer Behavior Mixin - Reusable gravity and collision behaviors

### 🔧 Technical improvements ideas
- [ ] Typed Field Values - Strong typing for Point, Color, Enum, EntityRef, Array fields
- [ ] Enum Support - Parse and use LDtk enum definitions
- [ ] Render Optimization - Tile batching, atlases, and off-screen culling
- [ ] Level Streaming - Progressive loading for large levels
- [ ] PNG-based IntGrid parsing - Alternative to CSV format

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT License - see LICENSE file for details.

## Credits

- [LDtk](https://ldtk.io/) - Level Designer Toolkit by Sébastien Benard
- [Flame](https://flame-engine.org/) - Flutter game engine
- [Kenney](https://kenney.nl/) - Assets on `example/` project

