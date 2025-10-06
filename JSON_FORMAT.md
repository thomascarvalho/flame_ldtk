# JSON Format Support

> ⚠️ **Important:** The JSON format support is currently **experimental and not fully implemented**. Many features may not work as expected. We recommend using the [Super Simple Export format](README.md#option-1-super-simple-export-recommended) for production projects.

## LDtk Setup

1. Create your level in [LDtk](https://ldtk.io/)
2. In **Project Settings**, enable **"Save levels to separate files"** (optional)
3. Save your project to generate `.ldtk` and `.ldtkl` files

Your project structure will be:
- `world.ldtk` - Main project file with definitions
- `world/Level_0.ldtkl` - Individual level files (if using external levels)

## Add assets to pubspec.yaml

```yaml
flutter:
  assets:
    - assets/world.ldtk
    - assets/world/
```

## Load a level

```dart
import 'package:flame/game.dart';
import 'package:flame_ldtk/flame_ldtk.dart';

class MyGame extends FlameGame {
  @override
  Future<void> onLoad() async {
    final level = LdtkJsonLevelComponent();
    await level.loadLevel('assets/world.ldtk', 'Level_0');
    await add(level);
  }
}
```

## API Reference

### LdtkJsonLevelComponent

Component for loading and displaying LDtk levels in standard JSON format.

```dart
// Load a level
await levelComponent.loadLevel(
  'assets/world.ldtk',      // Project file
  'Level_0',                 // Level identifier
);

// Access level data (same as LdtkLevelComponent)
LdtkLevel? data = levelComponent.levelData;

// Override to customize entity creation (same API as Super Simple Format)
@override
Future<void> onEntitiesLoaded(List<LdtkEntity> entities) async {
  // Your custom entity creation logic
}
```

### Background Images

Background images are automatically loaded from the JSON format with full support for:

```dart
// Background configuration is read from the .ldtk/.ldtkl files
// Supports:
// - bgRelPath: path to background image
// - bgPos: positioning mode (Cover, Contain, Unscaled, etc.)
// - bgPivotX/Y: pivot point for positioning
```

**Note:** The JSON format has better background support than Super Simple Export, but overall the JSON parser is less tested.

## Known Limitations

The following features are **not yet implemented** or **partially supported** in JSON format:

- ❌ AutoLayers rendering
- ❌ Tile animations
- ❌ Some advanced background options (custom scale, crop rectangles)
- ❌ Multi-world support
- ⚠️ IntGrid layers (support may be incomplete)
- ⚠️ Custom fields (basic support only)

## Why Use Super Simple Export Instead?

The Super Simple Export format is:
- ✅ **Fully tested and stable**
- ✅ **Optimized for performance** (minimal memory usage, fast loading)
- ✅ **Better documented** with more examples
- ✅ **Recommended for production** games

See the [main README](README.md) for Super Simple Export documentation.

## Contributing

If you need specific JSON format features, feel free to contribute! The codebase is designed to share utilities between both parsers.
