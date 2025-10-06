# Changelog

## [0.3.0](https://github.com/thomascarvalho/flame_ldtk/compare/v0.2.2...v0.3.0) (2025-10-06)


### ⚠ BREAKING CHANGES

* LdtkLevelComponent constructor now requires a LdtkWorld parameter. LdtkLevelComponent.loadLevel() now takes a level identifier instead of a full path.

### Features

* add LdtkWorld for simplified level management and entity tile support ([d194218](https://github.com/thomascarvalho/flame_ldtk/commit/d194218c5cd4ccb30ab65eaa7103e816847d6920))

## [0.2.2](https://github.com/thomascarvalho/flame_ldtk/compare/v0.2.1...v0.2.2) (2025-10-06)


### Features

* add individual layer rendering and simple background support ([98b3063](https://github.com/thomascarvalho/flame_ldtk/commit/98b30630ba87a2ec0a129c07f18a34a82c228f4a))

## [0.2.1](https://github.com/thomascarvalho/flame_ldtk/compare/v0.2.0...v0.2.1) (2025-10-05)


### Features

* add pre-commit hook for format and analyze checks ([ff9d028](https://github.com/thomascarvalho/flame_ldtk/commit/ff9d0289c64f508ed38dcb6502523edf78f005a4))


### Bug Fixes

* add release-please PAT token ([12d11ad](https://github.com/thomascarvalho/flame_ldtk/commit/12d11ad0124e1d827d7df09cdab6a260afddab20))
* better error handling + cache memory optimisation ([90f8466](https://github.com/thomascarvalho/flame_ldtk/commit/90f846627b4fc15663097473763958c1aa0efe9b))
* remove duplicate CI runs on push to main ([dd9acee](https://github.com/thomascarvalho/flame_ldtk/commit/dd9aceed62a4303cb5a587cdaf4b8766a0f3bd17))
* remove invalid package-name parameter from release-please workflow ([1537c6e](https://github.com/thomascarvalho/flame_ldtk/commit/1537c6e0e3da5b8ede85018b8540a877c7630074))

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
