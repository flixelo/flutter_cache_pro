/// Cache statistics
class CacheStats {
  /// Total number of cache hits
  final int hits;

  /// Total number of cache misses
  final int misses;

  /// Total number of entries in memory cache
  final int memoryEntries;

  /// Total number of entries in disk cache
  final int diskEntries;

  /// Current memory cache size in bytes
  final int memorySize;

  /// Current disk cache size in bytes
  final int diskSize;

  /// Number of evictions
  final int evictions;

  /// Number of expired entries removed
  final int expirations;

  const CacheStats({
    required this.hits,
    required this.misses,
    required this.memoryEntries,
    required this.diskEntries,
    required this.memorySize,
    required this.diskSize,
    required this.evictions,
    required this.expirations,
  });

  /// Calculate hit rate percentage
  double get hitRate {
    final total = hits + misses;
    if (total == 0) return 0.0;
    return (hits / total) * 100;
  }

  /// Calculate miss rate percentage
  double get missRate => 100 - hitRate;

  /// Total entries across both caches
  int get totalEntries => memoryEntries + diskEntries;

  /// Total size across both caches
  int get totalSize => memorySize + diskSize;

  /// Format size in human-readable format
  String formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  @override
  String toString() {
    return '''
CacheStats:
  Hit Rate: ${hitRate.toStringAsFixed(2)}%
  Hits: $hits
  Misses: $misses
  Memory: $memoryEntries entries (${formatSize(memorySize)})
  Disk: $diskEntries entries (${formatSize(diskSize)})
  Evictions: $evictions
  Expirations: $expirations
''';
  }

  /// Create empty stats
  factory CacheStats.empty() {
    return const CacheStats(
      hits: 0,
      misses: 0,
      memoryEntries: 0,
      diskEntries: 0,
      memorySize: 0,
      diskSize: 0,
      evictions: 0,
      expirations: 0,
    );
  }

  /// Create a copy with modified values
  CacheStats copyWith({
    int? hits,
    int? misses,
    int? memoryEntries,
    int? diskEntries,
    int? memorySize,
    int? diskSize,
    int? evictions,
    int? expirations,
  }) {
    return CacheStats(
      hits: hits ?? this.hits,
      misses: misses ?? this.misses,
      memoryEntries: memoryEntries ?? this.memoryEntries,
      diskEntries: diskEntries ?? this.diskEntries,
      memorySize: memorySize ?? this.memorySize,
      diskSize: diskSize ?? this.diskSize,
      evictions: evictions ?? this.evictions,
      expirations: expirations ?? this.expirations,
    );
  }
}
