import 'package:flutter_test/flutter_test.dart';
import 'package:flame_ldtk/src/utils/lru_cache.dart';

void main() {
  group('LruCache', () {
    test('stores and retrieves values', () {
      final cache = LruCache<String, int>(3);

      cache.put('a', 1);
      cache.put('b', 2);
      cache.put('c', 3);

      expect(cache.get('a'), 1);
      expect(cache.get('b'), 2);
      expect(cache.get('c'), 3);
    });

    test('returns null for non-existent keys', () {
      final cache = LruCache<String, int>(3);

      expect(cache.get('nonexistent'), isNull);
    });

    test('evicts least recently used item when full', () {
      final cache = LruCache<String, int>(3);

      cache.put('a', 1);
      cache.put('b', 2);
      cache.put('c', 3);

      // Cache is full, adding 'd' should evict 'a' (least recently used)
      cache.put('d', 4);

      expect(cache.get('a'), isNull); // 'a' was evicted
      expect(cache.get('b'), 2);
      expect(cache.get('c'), 3);
      expect(cache.get('d'), 4);
    });

    test('updates LRU order on get', () {
      final cache = LruCache<String, int>(3);

      cache.put('a', 1);
      cache.put('b', 2);
      cache.put('c', 3);

      // Access 'a' to make it recently used
      cache.get('a');

      // Adding 'd' should evict 'b' now (least recently used)
      cache.put('d', 4);

      expect(cache.get('a'), 1); // 'a' is still there
      expect(cache.get('b'), isNull); // 'b' was evicted
      expect(cache.get('c'), 3);
      expect(cache.get('d'), 4);
    });

    test('updates existing key value', () {
      final cache = LruCache<String, int>(3);

      cache.put('a', 1);
      cache.put('a', 10); // Update value

      expect(cache.get('a'), 10);
    });

    test('clear removes all items', () {
      final cache = LruCache<String, int>(3);

      cache.put('a', 1);
      cache.put('b', 2);
      cache.put('c', 3);

      cache.clear();

      expect(cache.get('a'), isNull);
      expect(cache.get('b'), isNull);
      expect(cache.get('c'), isNull);
    });

    test('handles size of 1', () {
      final cache = LruCache<String, int>(1);

      cache.put('a', 1);
      expect(cache.get('a'), 1);

      cache.put('b', 2);
      expect(cache.get('a'), isNull); // evicted
      expect(cache.get('b'), 2);
    });

    test('handles different value types', () {
      final cache = LruCache<int, String>(2);

      cache.put(1, 'one');
      cache.put(2, 'two');

      expect(cache.get(1), 'one');
      expect(cache.get(2), 'two');
    });
  });
}
