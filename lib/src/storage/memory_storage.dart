import '../cache_entry.dart';

/// Memory storage with LRU eviction
class MemoryStorage {
  final int maxSize;
  final Map<String, CacheEntry> _cache = {};
  int _currentSize = 0;

  MemoryStorage({required this.maxSize});

  /// Get entry from memory
  CacheEntry? get(String key) {
    final entry = _cache[key];
    if (entry != null && entry.isValid) {
      entry.markAccessed();
      return entry;
    }
    if (entry != null && entry.isExpired) {
      remove(key);
    }
    return null;
  }

  /// Put entry in memory
  Future<void> put(CacheEntry entry) async {
    // Remove old entry if exists
    if (_cache.containsKey(entry.key)) {
      final oldEntry = _cache[entry.key]!;
      _currentSize -= oldEntry.size;
    }

    // Evict if necessary
    while (_currentSize + entry.size > maxSize && _cache.isNotEmpty) {
      await _evictLru();
    }

    _cache[entry.key] = entry;
    _currentSize += entry.size;
  }

  /// Remove entry from memory
  void remove(String key) {
    final entry = _cache.remove(key);
    if (entry != null) {
      _currentSize -= entry.size;
    }
  }

  /// Check if key exists
  bool containsKey(String key) {
    return _cache.containsKey(key) && _cache[key]!.isValid;
  }

  /// Get all keys
  List<String> get keys => _cache.keys.toList();

  /// Get all entries
  List<CacheEntry> get entries => _cache.values.toList();

  /// Clear all entries
  void clear() {
    _cache.clear();
    _currentSize = 0;
  }

  /// Clear expired entries
  int clearExpired() {
    final expiredKeys = _cache.entries
        .where((e) => e.value.isExpired)
        .map((e) => e.key)
        .toList();

    for (final key in expiredKeys) {
      remove(key);
    }

    return expiredKeys.length;
  }

  /// Evict least recently used entry
  Future<void> _evictLru() async {
    if (_cache.isEmpty) return;

    // Find entry with lowest LRU score
    CacheEntry? lruEntry;
    double lowestScore = double.infinity;

    for (final entry in _cache.values) {
      final score = entry.lruScore;
      if (score < lowestScore) {
        lowestScore = score;
        lruEntry = entry;
      }
    }

    if (lruEntry != null) {
      remove(lruEntry.key);
    }
  }

  /// Get current size
  int get currentSize => _currentSize;

  /// Get entry count
  int get count => _cache.length;

  /// Get stats
  Map<String, dynamic> getStats() {
    return {
      'entries': count,
      'size': currentSize,
      'maxSize': maxSize,
      'utilizationPercent': (currentSize / maxSize * 100).toStringAsFixed(2),
    };
  }
}
