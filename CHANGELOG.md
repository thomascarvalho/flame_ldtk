## 0.2.0

* **NEW: LdtkJsonLevelComponent** - Unified API for both export formats
  - `LdtkLevelComponent` for Super Simple Export (existing)
  - `LdtkJsonLevelComponent` for standard JSON format (new!)
  - Both components share the same API - just swap them based on your format
* **JSON Parser Enhancement**: Full support for custom fields extraction in both levels and entities
  - Levels now properly extract `customData` from `fieldInstances`
  - Entities now extract `fields` from `fieldInstances` and `color` from `__smartColor`
* **Parser Harmonization**: Both JSON and Super Simple parsers now have consistent behavior
  - Super Simple Parser: Already supported custom fields and colors
  - JSON Parser: Now matches Super Simple Parser functionality
* **Code Refactoring**: Introduced `LdtkParserUtils` utility class
  - Shared utilities between both parsers (color parsing, image loading, field parsing)
  - Centralized image cache for better memory management
  - Reduced code duplication
  - Cleaner, more maintainable codebase
* **Performance**: Both parsers now use optimized shared functions for common operations
* **Breaking Change**: None - all existing code continues to work

## 0.1.1

* Optimize code and add cache for assets

## 0.1.0

* Initial release
* **LDtk Integration**: Support for LDtk Super Simple Export format
* **Level Loading**: Load and render complete levels with composite images
* **Entity Parsing**: Extract entities with positions, sizes, custom fields, and colors
* **IntGrid Support**: CSV-based IntGrid layers for collision detection and game logic
* **Flexible Architecture**: Override hooks to customize entity rendering
* **Generic Design**: No built-in collision logic, adaptable to any game type
* **Example App**: Complete platformer example with physics and collision detection
