/// Professional caching solution with LRU, TTL, priority levels, memory and disk storage.
///
/// ## Features
///
/// - **Multi-level caching**: Memory + Disk storage
/// - **LRU eviction**: Automatic cleanup of least recently used items
/// - **TTL management**: Time-based expiration
/// - **Priority levels**: High, medium, low priority caching
/// - **Type-safe**: Generic type support
/// - **Flexible serialization**: Custom serializers
/// - **Size limits**: Memory and disk size management
///
/// ## Quick Start
///
/// ```dart
/// import 'package:flutter_cache_pro/flutter_cache_pro.dart';
///
/// // Initialize the cache
/// await CachePro.instance.initialize();
///
/// // Cache a string
/// await CachePro.instance.put('key', 'value');
///
/// // Get from cache
/// final value = await CachePro.instance.get<String>('key');
///
/// // Cache with TTL (1 hour)
/// await CachePro.instance.put(
///   'user_data',
///   userData,
///   ttl: Duration(hours: 1),
/// );
///
/// // High priority cache (stays longer)
/// await CachePro.instance.put(
///   'critical_data',
///   data,
///   priority: CachePriority.high,
/// );
/// ```
///
/// ## Advanced Usage
///
/// ```dart
/// // Custom serializer for complex objects
/// final cache = CachePro.instance;
/// 
/// await cache.put<User>(
///   'user_123',
///   user,
///   serializer: (user) => jsonEncode(user.toJson()),
///   deserializer: (json) => User.fromJson(jsonDecode(json)),
/// );
///
/// // Clear expired entries
/// await cache.clearExpired();
///
/// // Get cache statistics
/// final stats = await cache.getStats();
/// print('Hit rate: ${stats.hitRate}%');
/// ```
library flutter_cache_pro;

export 'src/cache_pro.dart';
export 'src/cache_entry.dart';
export 'src/cache_priority.dart';
export 'src/cache_config.dart';
export 'src/cache_stats.dart';
export 'src/storage/memory_storage.dart';
export 'src/storage/disk_storage.dart';
