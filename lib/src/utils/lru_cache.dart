import 'dart:collection';

/// A simple LRU (Least Recently Used) cache implementation.
///
/// When the cache reaches its maximum capacity, the least recently
/// accessed item is removed to make room for new items.
class LruCache<K, V> {
  final int maxSize;
  final LinkedHashMap<K, V> _map = LinkedHashMap();

  LruCache(this.maxSize) : assert(maxSize > 0);

  /// Gets a value from the cache, or null if not present.
  ///
  /// Accessing an item marks it as recently used.
  V? get(K key) {
    final value = _map.remove(key);
    if (value != null) {
      _map[key] = value; // Re-insert to mark as recently used
    }
    return value;
  }

  /// Puts a value into the cache.
  ///
  /// If the cache is full, the least recently used item is evicted.
  void put(K key, V value) {
    _map.remove(key); // Remove if exists to update position
    _map[key] = value;

    // Evict oldest entry if cache is full
    if (_map.length > maxSize) {
      _map.remove(_map.keys.first);
    }
  }

  /// Checks if the cache contains a key.
  bool containsKey(K key) => _map.containsKey(key);

  /// Clears all items from the cache.
  void clear() => _map.clear();

  /// Gets the current size of the cache.
  int get length => _map.length;
}
