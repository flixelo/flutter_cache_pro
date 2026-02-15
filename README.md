# flutter_cache_pro

[![pub package](https://img.shields.io/pub/v/flutter_cache_pro.svg)](https://pub.dev/packages/flutter_cache_pro)

Professional caching solution for Flutter with LRU eviction, TTL management, priority levels, and multi-level storage (memory + disk).

## Features

✨ **Multi-Level Caching**
- Memory cache for fast access
- Disk cache for persistence
- Automatic promotion to memory

🔄 **Smart Eviction**
- LRU (Least Recently Used) algorithm
- Priority-based eviction
- TTL (Time To Live) management

⚡ **High Performance**
- Type-safe generic support
- Automatic size management
- Configurable limits

📊 **Statistics**
- Hit/miss rates
- Cache utilization
- Eviction tracking

🛡️ **Production Ready**
- Zero dependencies (except Flutter SDK)
- Well-tested
- Comprehensive documentation

## Installation

```yaml
dependencies:
  flutter_cache_pro: ^1.0.0
```

Then run:

```bash
flutter pub get
```

## Quick Start

```dart
import 'package:flutter_cache_pro/flutter_cache_pro.dart';

void main() async {
  // Initialize cache
  await CachePro.instance.initialize();
  
  // Cache a simple value
  await CachePro.instance.put('username', 'John Doe');
  
  // Retrieve from cache
  final name = await CachePro.instance.get<String>('username');
  print(name); // John Doe
}
```

## Usage

### Basic Caching

```dart
// Put value in cache
await CachePro.instance.put('key', 'value');

// Get value from cache
final value = await CachePro.instance.get<String>('key');

// Remove from cache
await CachePro.instance.remove('key');

// Clear all cache
await CachePro.instance.clear();
```

### TTL (Time To Live)

```dart
// Cache for 1 hour
await CachePro.instance.put(
  'session_token',
  token,
  ttl: Duration(hours: 1),
);

// Cache for 5 minutes
await CachePro.instance.put(
  'temp_data',
  data,
  ttl: Duration(minutes: 5),
);
```

### Priority Levels

```dart
// High priority - kept longer
await CachePro.instance.put(
  'user_profile',
  profile,
  priority: CachePriority.high,
);

// Medium priority (default)
await CachePro.instance.put(
  'feed_data',
  feed,
  priority: CachePriority.medium,
);

// Low priority - evicted first
await CachePro.instance.put(
  'temp_image',
  image,
  priority: CachePriority.low,
);
```

### Complex Objects

```dart
// Cache with custom serializer
await CachePro.instance.put<User>(
  'user_123',
  user,
  serializer: (user) => jsonEncode(user.toJson()),
);

// Retrieve with custom deserializer
final user = await CachePro.instance.get<User>(
  'user_123',
  deserializer: (json) => User.fromJson(jsonDecode(json)),
);
```

### Get or Compute

```dart
// Get from cache or compute if not present
final data = await CachePro.instance.getOrPut(
  'expensive_data',
  () async {
    // Expensive operation
    return await fetchFromApi();
  },
  ttl: Duration(minutes: 30),
);
```

### Configuration

```dart
await CachePro.instance.initialize(
  CacheConfig(
    maxMemorySize: 100 * 1024 * 1024, // 100MB memory
    maxDiskSize: 1024 * 1024 * 1024, // 1GB disk
    defaultTtl: Duration(hours: 24),
    defaultPriority: CachePriority.medium,
    enableDiskCache: true,
    autoClearInterval: Duration(hours: 1),
    enableStats: true,
  ),
);
```

### Statistics

```dart
// Get cache statistics
final stats = await CachePro.instance.getStats();

print('Hit Rate: ${stats.hitRate}%');
print('Memory: ${stats.memoryEntries} entries');
print('Disk: ${stats.diskEntries} entries');
print('Total Size: ${stats.formatSize(stats.totalSize)}');

// Clear expired entries manually
final cleared = await CachePro.instance.clearExpired();
print('Cleared $cleared expired entries');
```

## Advanced Usage

### Real-World Example: API Response Caching

```dart
class ApiService {
  final cache = CachePro.instance;
  
  Future<List<Product>> getProducts() async {
    return await cache.getOrPut(
      'products_list',
      () async {
        // Fetch from API
        final response = await http.get(Uri.parse('https://api.example.com/products'));
        return parseProducts(response.body);
      },
      ttl: Duration(minutes: 15),
      priority: CachePriority.high,
      serializer: (products) => jsonEncode(products.map((p) => p.toJson()).toList()),
      deserializer: (json) {
        final list = jsonDecode(json) as List;
        return list.map((item) => Product.fromJson(item)).toList();
      },
    );
  }
  
  Future<User> getUserProfile(String userId) async {
    return await cache.getOrPut(
      'user_$userId',
      () async => fetchUserFromApi(userId),
      ttl: Duration(hours: 1),
      priority: CachePriority.high,
    );
  }
}
```

### Image Caching

```dart
class ImageCacheService {
  final cache = CachePro.instance;
  
  Future<void> cacheImage(String url, Uint8List imageData) async {
    await cache.put(
      'image_$url',
      base64Encode(imageData),
      ttl: Duration(days: 7),
      priority: CachePriority.low,
    );
  }
  
  Future<Uint8List?> getImage(String url) async {
    final base64 = await cache.get<String>('image_$url');
    if (base64 != null) {
      return base64Decode(base64);
    }
    return null;
  }
}
```

## Configuration Options

| Option | Default | Description |
|--------|---------|-------------|
| `maxMemorySize` | 50MB | Maximum memory cache size |
| `maxDiskSize` | 500MB | Maximum disk cache size |
| `defaultTtl` | 24 hours | Default time-to-live |
| `defaultPriority` | medium | Default cache priority |
| `enableDiskCache` | true | Enable persistent disk cache |
| `autoClearInterval` | 1 hour | Auto-clear expired entries |
| `enableStats` | true | Enable statistics tracking |
| `cacheDirectory` | cache_pro | Cache directory name |

## Performance Tips

1. **Use appropriate TTLs**: Short-lived data gets short TTL
2. **Set priorities correctly**: Critical data gets high priority
3. **Monitor statistics**: Check hit rates regularly
4. **Clear expired entries**: Run `clearExpired()` periodically
5. **Size limits**: Configure based on your app's needs

## Best Practices

```dart
// ✅ Good: Specific TTL based on data type
await cache.put('weather', data, ttl: Duration(minutes: 30));

// ❌ Bad: No TTL for temporary data
await cache.put('weather', data); // Uses 24h default

// ✅ Good: High priority for critical data
await cache.put('user_session', session, priority: CachePriority.high);

// ✅ Good: Use getOrPut for expensive operations
final data = await cache.getOrPut('key', () => expensiveOperation());

// ❌ Bad: Manual check then put
final cached = await cache.get('key');
if (cached == null) {
  final data = await expensiveOperation();
  await cache.put('key', data);
}
```

## License

MIT License - see LICENSE file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Support

For issues and feature requests, please file an issue on [GitHub](https://github.com/flixelo/flutter_cache_pro/issues).
