import 'dart:async';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import 'cache_entry.dart';
import 'cache_priority.dart';
import 'cache_config.dart';
import 'cache_stats.dart';
import 'storage/memory_storage.dart';
import 'storage/disk_storage.dart';

/// Professional caching solution with multi-level storage, LRU eviction, and TTL management
class CachePro {
  static CachePro? _instance;
  static CachePro get instance => _instance ??= CachePro._();

  CachePro._();

  CacheConfig _config = const CacheConfig();
  late MemoryStorage _memoryStorage;
  late DiskStorage _diskStorage;
  bool _initialized = false;
  Timer? _autoClearTimer;

  // Statistics
  int _hits = 0;
  int _misses = 0;
  int _evictions = 0;
  int _expirations = 0;

  /// Initialize cache with optional configuration
  Future<void> initialize([CacheConfig? config]) async {
    if (_initialized) return;

    _config = config ?? _config;
    
    // Initialize memory storage
    _memoryStorage = MemoryStorage(maxSize: _config.maxMemorySize);

    // Initialize disk storage
    if (_config.enableDiskCache) {
      final appDir = await getApplicationDocumentsDirectory();
      final cacheDir = path.join(appDir.path, _config.cacheDirectory);
      _diskStorage = DiskStorage(
        cacheDir: cacheDir,
        maxSize: _config.maxDiskSize,
      );
      await _diskStorage.initialize();
    }

    // Start auto-clear timer
    if (_config.enableStats) {
      _autoClearTimer = Timer.periodic(_config.autoClearInterval, (_) {
        clearExpired();
      });
    }

    _initialized = true;
  }

  /// Ensure cache is initialized
  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError('CachePro not initialized. Call initialize() first.');
    }
  }

  /// Put value in cache
  Future<void> put<T>(
    String key,
    T value, {
    Duration? ttl,
    CachePriority? priority,
    String Function(T)? serializer,
  }) async {
    _ensureInitialized();

    final effectiveTtl = ttl ?? _config.defaultTtl;
    final effectivePriority = priority ?? _config.defaultPriority;
    
    DateTime? expiresAt;
    if (effectiveTtl != null) {
      expiresAt = DateTime.now().add(effectiveTtl);
    }

    // Serialize value if needed
    final serializedValue = serializer != null ? serializer(value) : value;
    
    // Calculate size (rough estimate)
    final size = _calculateSize(serializedValue);

    final entry = CacheEntry(
      key: key,
      value: serializedValue,
      createdAt: DateTime.now(),
      expiresAt: expiresAt,
      priority: effectivePriority.value,
      size: size,
    );

    // Store in memory
    await _memoryStorage.put(entry);

    // Store on disk if enabled
    if (_config.enableDiskCache) {
      await _diskStorage.put(entry);
    }
  }

  /// Get value from cache
  Future<T?> get<T>(
    String key, {
    T Function(dynamic)? deserializer,
  }) async {
    _ensureInitialized();

    // Try memory first
    CacheEntry? entry = _memoryStorage.get(key);
    
    if (entry != null) {
      if (_config.enableStats) _hits++;
      final value = entry.value;
      return deserializer != null ? deserializer(value) : value as T?;
    }

    // Try disk if enabled
    if (_config.enableDiskCache) {
      entry = await _diskStorage.get(key);
      if (entry != null) {
        // Promote to memory cache
        await _memoryStorage.put(entry);
        if (_config.enableStats) _hits++;
        
        final value = entry.value;
        return deserializer != null ? deserializer(value) : value as T?;
      }
    }

    if (_config.enableStats) _misses++;
    return null;
  }

  /// Get value or compute if not present
  Future<T> getOrPut<T>(
    String key,
    Future<T> Function() compute, {
    Duration? ttl,
    CachePriority? priority,
    String Function(T)? serializer,
    T Function(dynamic)? deserializer,
  }) async {
    final cached = await get<T>(key, deserializer: deserializer);
    if (cached != null) return cached;

    final value = await compute();
    await put(key, value, ttl: ttl, priority: priority, serializer: serializer);
    return value;
  }

  /// Remove entry from cache
  Future<void> remove(String key) async {
    _ensureInitialized();
    _memoryStorage.remove(key);
    if (_config.enableDiskCache) {
      await _diskStorage.remove(key);
    }
  }

  /// Check if key exists in cache
  Future<bool> containsKey(String key) async {
    _ensureInitialized();
    if (_memoryStorage.containsKey(key)) return true;
    if (_config.enableDiskCache) {
      return await _diskStorage.containsKey(key);
    }
    return false;
  }

  /// Clear all cache
  Future<void> clear() async {
    _ensureInitialized();
    _memoryStorage.clear();
    if (_config.enableDiskCache) {
      await _diskStorage.clear();
    }
    _resetStats();
  }

  /// Clear expired entries
  Future<int> clearExpired() async {
    _ensureInitialized();
    
    int count = 0;
    count += _memoryStorage.clearExpired();
    
    if (_config.enableDiskCache) {
      count += await _diskStorage.clearExpired();
    }

    if (_config.enableStats) {
      _expirations += count;
    }

    return count;
  }

  /// Get cache statistics
  Future<CacheStats> getStats() async {
    _ensureInitialized();

    final memoryStats = _memoryStorage.getStats();
    final diskStats = _config.enableDiskCache 
        ? await _diskStorage.getStats() 
        : {'entries': 0, 'size': 0};

    return CacheStats(
      hits: _hits,
      misses: _misses,
      memoryEntries: memoryStats['entries'],
      diskEntries: diskStats['entries'],
      memorySize: memoryStats['size'],
      diskSize: diskStats['size'],
      evictions: _evictions,
      expirations: _expirations,
    );
  }

  /// Reset statistics
  void _resetStats() {
    _hits = 0;
    _misses = 0;
    _evictions = 0;
    _expirations = 0;
  }

  /// Calculate approximate size of value
  int _calculateSize(dynamic value) {
    if (value == null) return 0;
    if (value is String) return value.length * 2; // UTF-16
    if (value is int) return 8;
    if (value is double) return 8;
    if (value is bool) return 1;
    if (value is List) {
      return value.fold(0, (sum, item) => sum + _calculateSize(item));
    }
    if (value is Map) {
      return value.entries.fold(
        0,
        (sum, entry) => sum + _calculateSize(entry.key) + _calculateSize(entry.value),
      );
    }
    // For complex objects, try to estimate via JSON
    try {
      final json = jsonEncode(value);
      return json.length * 2;
    } catch (e) {
      return 1024; // Default 1KB for unknown types
    }
  }

  /// Dispose cache and cleanup
  Future<void> dispose() async {
    _autoClearTimer?.cancel();
    _initialized = false;
    _instance = null;
  }

  /// Get current configuration
  CacheConfig get config => _config;

  /// Check if cache is initialized
  bool get isInitialized => _initialized;
}
