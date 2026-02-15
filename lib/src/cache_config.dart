import 'cache_priority.dart';

/// Configuration for CachePro
class CacheConfig {
  /// Maximum memory cache size in bytes (default: 50MB)
  final int maxMemorySize;

  /// Maximum disk cache size in bytes (default: 500MB)
  final int maxDiskSize;

  /// Default TTL for cache entries (default: 24 hours)
  final Duration? defaultTtl;

  /// Default priority for cache entries
  final CachePriority defaultPriority;

  /// Enable disk caching
  final bool enableDiskCache;

  /// Auto-clear expired entries interval (default: 1 hour)
  final Duration autoClearInterval;

  /// Enable cache statistics
  final bool enableStats;

  /// Cache directory name
  final String cacheDirectory;

  const CacheConfig({
    this.maxMemorySize = 50 * 1024 * 1024, // 50MB
    this.maxDiskSize = 500 * 1024 * 1024, // 500MB
    this.defaultTtl = const Duration(hours: 24),
    this.defaultPriority = CachePriority.medium,
    this.enableDiskCache = true,
    this.autoClearInterval = const Duration(hours: 1),
    this.enableStats = true,
    this.cacheDirectory = 'cache_pro',
  });

  /// Create a copy with modified values
  CacheConfig copyWith({
    int? maxMemorySize,
    int? maxDiskSize,
    Duration? defaultTtl,
    CachePriority? defaultPriority,
    bool? enableDiskCache,
    Duration? autoClearInterval,
    bool? enableStats,
    String? cacheDirectory,
  }) {
    return CacheConfig(
      maxMemorySize: maxMemorySize ?? this.maxMemorySize,
      maxDiskSize: maxDiskSize ?? this.maxDiskSize,
      defaultTtl: defaultTtl ?? this.defaultTtl,
      defaultPriority: defaultPriority ?? this.defaultPriority,
      enableDiskCache: enableDiskCache ?? this.enableDiskCache,
      autoClearInterval: autoClearInterval ?? this.autoClearInterval,
      enableStats: enableStats ?? this.enableStats,
      cacheDirectory: cacheDirectory ?? this.cacheDirectory,
    );
  }
}
