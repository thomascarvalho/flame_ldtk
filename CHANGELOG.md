# Changelog

## [0.2.0](https://github.com/thomascarvalho/flame_ldtk/compare/v0.1.1...v0.2.0) (2025-10-05)


### Features

* **LdtkJsonLevelComponent** - Unified API for both export formats ([dac6896](https://github.com/thomascarvalho/flame_ldtk/commit/dac6896))
  - `LdtkLevelComponent` for Super Simple Export (existing)
  - `LdtkJsonLevelComponent` for standard JSON format (new!)
  - Both components share the same API - just swap them based on your format
* **JSON Parser Enhancement**: Full support for custom fields extraction in both levels and entities
  - Levels now properly extract `customData` from `fieldInstances`
  - Entities now extract `fields` from `fieldInstances` and `color` from `__smartColor`
* **Parser Harmonization**: Both JSON and Super Simple parsers now have consistent behavior


### Performance Improvements

* Both parsers now use optimized shared functions for common operations
* Code Refactoring: Introduced `LdtkParserUtils` utility class
  - Shared utilities between both parsers (color parsing, image loading, field parsing)
  - Centralized image cache for better memory management
  - Reduced code duplication
  - Cleaner, more maintainable codebase

## [0.1.1](https://github.com/thomascarvalho/flame_ldtk/compare/v0.1.0...v0.1.1) (2024-12-01)


### Performance Improvements

* optimize code and add cache for assets ([b58aa07](https://github.com/thomascarvalho/flame_ldtk/commit/b58aa07))

## 0.1.0 (2024-11-15)


### Features

* Initial release
* **LDtk Integration**: Support for LDtk Super Simple Export format
* **Level Loading**: Load and render complete levels with composite images
* **Entity Parsing**: Extract entities with positions, sizes, custom fields, and colors
* **IntGrid Support**: CSV-based IntGrid layers for collision detection and game logic
* **Flexible Architecture**: Override hooks to customize entity rendering
* **Generic Design**: No built-in collision logic, adaptable to any game type
* **Example App**: Complete platformer example with physics and collision detection
