import 'package:flutter_test/flutter_test.dart';
import 'package:flame_ldtk/src/parsers/ldtk_parser_utils.dart';

void main() {
  group('LdtkParserUtils', () {
    group('parseHexColor', () {
      test('parses hex color with hash correctly', () {
        final red = LdtkParserUtils.parseHexColor('#FF0000');
        expect(red?.toARGB32(), 0xFFFF0000);

        final green = LdtkParserUtils.parseHexColor('#00FF00');
        expect(green?.toARGB32(), 0xFF00FF00);

        final blue = LdtkParserUtils.parseHexColor('#0000FF');
        expect(blue?.toARGB32(), 0xFF0000FF);
      });

      test('handles null input', () {
        final color = LdtkParserUtils.parseHexColor(null);
        expect(color, isNull);
      });

      test('handles invalid hex color', () {
        final invalid1 = LdtkParserUtils.parseHexColor('invalid');
        expect(invalid1, isNull);

        final invalid2 = LdtkParserUtils.parseHexColor('FF0000');
        expect(invalid2, isNull);
      });

      test('parses black and white correctly', () {
        final black = LdtkParserUtils.parseHexColor('#000000');
        expect(black?.toARGB32(), 0xFF000000);

        final white = LdtkParserUtils.parseHexColor('#FFFFFF');
        expect(white?.toARGB32(), 0xFFFFFFFF);
      });
    });

    group('parseIntColor', () {
      test('converts integer to Color correctly', () {
        // Red: 16711680 = 0xFF0000
        final red = LdtkParserUtils.parseIntColor(16711680);
        expect(red?.toARGB32(), 0xFFFF0000);

        // Green: 65280 = 0x00FF00
        final green = LdtkParserUtils.parseIntColor(65280);
        expect(green?.toARGB32(), 0xFF00FF00);

        // Blue: 255 = 0x0000FF
        final blue = LdtkParserUtils.parseIntColor(255);
        expect(blue?.toARGB32(), 0xFF0000FF);
      });

      test('handles null input', () {
        final color = LdtkParserUtils.parseIntColor(null);
        expect(color, isNull);
      });

      test('handles black and white', () {
        final black = LdtkParserUtils.parseIntColor(0);
        expect(black?.toARGB32(), 0xFF000000);

        final white = LdtkParserUtils.parseIntColor(16777215);
        expect(white?.toARGB32(), 0xFFFFFFFF);
      });
    });

    group('getBasePath', () {
      test('extracts base path correctly', () {
        expect(
          LdtkParserUtils.getBasePath('assets/levels/level1.ldtk'),
          'assets/levels',
        );

        expect(
          LdtkParserUtils.getBasePath('assets/world/Level_0.ldtkl'),
          'assets/world',
        );

        expect(
          LdtkParserUtils.getBasePath('path/to/deep/file.json'),
          'path/to/deep',
        );
      });

      test('handles paths without directory', () {
        expect(
          LdtkParserUtils.getBasePath('file.json'),
          '',
        );
      });

      test('handles root paths', () {
        expect(
          LdtkParserUtils.getBasePath('/file.json'),
          '',
        );
      });

      test('handles multiple slashes', () {
        expect(
          LdtkParserUtils.getBasePath('assets//levels//file.json'),
          'assets//levels/',
        );
      });
    });

    group('parseFieldInstances', () {
      test('parses field instances to map correctly', () {
        final fieldInstances = [
          {
            '__identifier': 'health',
            '__value': 100,
          },
          {
            '__identifier': 'speed',
            '__value': 150.5,
          },
          {
            '__identifier': 'name',
            '__value': 'Player',
          },
        ];

        final result = LdtkParserUtils.parseFieldInstances(fieldInstances);

        expect(result['health'], 100);
        expect(result['speed'], 150.5);
        expect(result['name'], 'Player');
      });

      test('handles empty field instances', () {
        final result = LdtkParserUtils.parseFieldInstances([]);
        expect(result, isEmpty);
      });

      test('ignores invalid field instances', () {
        final fieldInstances = [
          {
            '__identifier': 'valid',
            '__value': 123,
          },
          'invalid',
          {
            '__value': 456, // Missing identifier
          },
          {
            '__identifier': 'another',
            '__value': 'test',
          },
        ];

        final result = LdtkParserUtils.parseFieldInstances(fieldInstances);

        expect(result.length, 2);
        expect(result['valid'], 123);
        expect(result['another'], 'test');
      });

      test('handles various value types', () {
        final fieldInstances = [
          {'__identifier': 'int', '__value': 42},
          {'__identifier': 'double', '__value': 3.14},
          {'__identifier': 'string', '__value': 'hello'},
          {'__identifier': 'bool', '__value': true},
          {'__identifier': 'null', '__value': null},
          {
            '__identifier': 'list',
            '__value': [1, 2, 3]
          },
          {
            '__identifier': 'map',
            '__value': {'key': 'value'}
          },
        ];

        final result = LdtkParserUtils.parseFieldInstances(fieldInstances);

        expect(result['int'], 42);
        expect(result['double'], 3.14);
        expect(result['string'], 'hello');
        expect(result['bool'], true);
        expect(result['null'], null);
        expect(result['list'], [1, 2, 3]);
        expect(result['map'], {'key': 'value'});
      });
    });

    group('clearImageCache', () {
      test('clears the image cache', () {
        // This test just ensures the method can be called without errors
        expect(() => LdtkParserUtils.clearImageCache(), returnsNormally);
      });
    });
  });
}
