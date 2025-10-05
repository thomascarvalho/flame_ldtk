import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter/material.dart' show Color;

/// Utility functions shared between LDtk parsers.
class LdtkParserUtils {
  // Cache for loaded images
  static final Map<String, ui.Image> _imageCache = {};

  /// Clears the image cache.
  static void clearImageCache() {
    _imageCache.clear();
  }

  /// Parses a hex color string (e.g., "#FF0000") to a Flutter Color.
  ///
  /// Returns null if the string is null or invalid.
  static Color? parseHexColor(String? hexColor) {
    if (hexColor == null || !hexColor.startsWith('#')) {
      return null;
    }
    final hex = hexColor.substring(1);
    return Color(int.parse('FF$hex', radix: 16));
  }

  /// Parses an integer color value to a Flutter Color.
  ///
  /// Returns null if the value is null.
  static Color? parseIntColor(int? colorInt) {
    if (colorInt == null) {
      return null;
    }
    return Color(0xFF000000 | colorInt);
  }

  /// Loads an image from the given asset path with caching.
  static Future<ui.Image> loadImage(String path) async {
    if (_imageCache.containsKey(path)) {
      return _imageCache[path]!;
    }

    final data = await rootBundle.load(path);
    final bytes = data.buffer.asUint8List();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    _imageCache[path] = image;
    return image;
  }

  /// Extracts the base path from a file path.
  ///
  /// Example: "assets/levels/level1.ldtk" -> "assets/levels"
  static String getBasePath(String filePath) {
    final lastSlash = filePath.lastIndexOf('/');
    return lastSlash != -1 ? filePath.substring(0, lastSlash) : '';
  }

  /// Parses LDtk field instances array to a Map<String, dynamic>.
  ///
  /// Used for converting JSON format field instances to a map.
  static Map<String, dynamic> parseFieldInstances(
      List<dynamic> fieldInstances) {
    final fields = <String, dynamic>{};
    for (final field in fieldInstances) {
      if (field is Map<String, dynamic>) {
        final identifier = field['__identifier'] as String?;
        final value = field['__value'];
        if (identifier != null) {
          fields[identifier] = value;
        }
      }
    }
    return fields;
  }
}
