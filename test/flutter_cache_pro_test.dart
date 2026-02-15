import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_cache_pro/flutter_cache_pro.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CachePro', () {
    late CachePro cache;

    setUp(() async {
      cache = CachePro.instance;
      await cache.initialize(
        CacheConfig(
          maxMemorySize: 1024 * 1024, // 1MB for testing
          maxDiskSize: 5 * 1024 * 1024, // 5MB for testing
          enableDiskCache: false, // Disable disk cache for tests
          enableStats: true,
        ),
      );
      await cache.clear();
    });

    tearDown(() async {
      await cache.clear();
    });

    test('Basic put and get', () async {
      await cache.put('key', 'value');
      final result = await cache.get<String>('key');
      expect(result, equals('value'));
    });

    test('Get non-existent key returns null', () async {
      final result = await cache.get<String>('nonexistent');
      expect(result, isNull);
    });

    test('Remove entry', () async {
      await cache.put('key', 'value');
      await cache.remove('key');
      final result = await cache.get<String>('key');
      expect(result, isNull);
    });

    test('ContainsKey', () async {
      await cache.put('key', 'value');
      expect(await cache.containsKey('key'), isTrue);
      expect(await cache.containsKey('nonexistent'), isFalse);
    });

    test('Clear cache', () async {
      await cache.put('key1', 'value1');
      await cache.put('key2', 'value2');
      await cache.clear();
      expect(await cache.containsKey('key1'), isFalse);
      expect(await cache.containsKey('key2'), isFalse);
    });

    test('TTL expiration', () async {
      await cache.put(
        'temp',
        'value',
        ttl: Duration(milliseconds: 100),
      );
      
      // Should exist immediately
      var result = await cache.get<String>('temp');
      expect(result, equals('value'));
      
      // Wait for expiration
      await Future.delayed(Duration(milliseconds: 150));
      
      // Should be expired
      result = await cache.get<String>('temp');
      expect(result, isNull);
    });

    test('Priority levels', () async {
      await cache.put('high', 'value', priority: CachePriority.high);
      await cache.put('medium', 'value', priority: CachePriority.medium);
      await cache.put('low', 'value', priority: CachePriority.low);
      
      expect(await cache.containsKey('high'), isTrue);
      expect(await cache.containsKey('medium'), isTrue);
      expect(await cache.containsKey('low'), isTrue);
    });

    test('GetOrPut - compute on miss', () async {
      var computeCalls = 0;
      
      final result1 = await cache.getOrPut<String>(
        'key',
        () async {
          computeCalls++;
          return 'computed';
        },
      );
      
      expect(result1, equals('computed'));
      expect(computeCalls, equals(1));
      
      // Second call should use cache
      final result2 = await cache.getOrPut<String>(
        'key',
        () async {
          computeCalls++;
          return 'computed';
        },
      );
      
      expect(result2, equals('computed'));
      expect(computeCalls, equals(1)); // Should not compute again
    });

    test('Statistics tracking', () async {
      // Clear to reset stats
      await cache.clear();
      
      // Put some values
      await cache.put('key1', 'value1');
      await cache.put('key2', 'value2');
      
      // Generate hits
      await cache.get<String>('key1');
      await cache.get<String>('key2');
      
      // Generate misses
      await cache.get<String>('nonexistent1');
      await cache.get<String>('nonexistent2');
      
      final stats = await cache.getStats();
      
      expect(stats.hits, greaterThanOrEqualTo(2));
      expect(stats.misses, greaterThanOrEqualTo(2));
      expect(stats.memoryEntries, greaterThanOrEqualTo(2));
    });

    test('Clear expired entries', () async {
      // Add some entries with short TTL
      await cache.put('temp1', 'value', ttl: Duration(milliseconds: 50));
      await cache.put('temp2', 'value', ttl: Duration(milliseconds: 50));
      await cache.put('permanent', 'value'); // No TTL
      
      // Wait for expiration
      await Future.delayed(Duration(milliseconds: 100));
      
      // Clear expired
      final cleared = await cache.clearExpired();
      
      expect(cleared, greaterThanOrEqualTo(2));
      expect(await cache.containsKey('permanent'), isTrue);
    });

    test('Multiple data types', () async {
      await cache.put('string', 'text');
      await cache.put('int', 42);
      await cache.put('double', 3.14);
      await cache.put('bool', true);
      await cache.put('list', [1, 2, 3]);
      await cache.put('map', {'key': 'value'});
      
      expect(await cache.get<String>('string'), equals('text'));
      expect(await cache.get<int>('int'), equals(42));
      expect(await cache.get<double>('double'), equals(3.14));
      expect(await cache.get<bool>('bool'), equals(true));
      expect(await cache.get<List>('list'), equals([1, 2, 3]));
      expect(await cache.get<Map>('map'), equals({'key': 'value'}));
    });

    test('Cache overwrite', () async {
      await cache.put('key', 'value1');
      await cache.put('key', 'value2');
      
      final result = await cache.get<String>('key');
      expect(result, equals('value2'));
    });
  });

  group('CachePriority', () {
    test('Priority comparison', () {
      expect(CachePriority.high > CachePriority.medium, isTrue);
      expect(CachePriority.medium > CachePriority.low, isTrue);
      expect(CachePriority.low < CachePriority.high, isTrue);
    });
  });

  group('CacheEntry', () {
    test('Entry expiration', () {
      final entry = CacheEntry(
        key: 'test',
        value: 'value',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(Duration(seconds: 1)),
        priority: 1,
        size: 10,
      );
      
      expect(entry.isValid, isTrue);
      expect(entry.isExpired, isFalse);
    });

    test('Entry without expiration', () {
      final entry = CacheEntry(
        key: 'test',
        value: 'value',
        createdAt: DateTime.now(),
        priority: 1,
        size: 10,
      );
      
      expect(entry.isValid, isTrue);
      expect(entry.isExpired, isFalse);
    });

    test('Access tracking', () {
      final entry = CacheEntry(
        key: 'test',
        value: 'value',
        createdAt: DateTime.now(),
        priority: 1,
        size: 10,
      );
      
      expect(entry.accessCount, equals(0));
      
      entry.markAccessed();
      expect(entry.accessCount, equals(1));
      
      entry.markAccessed();
      expect(entry.accessCount, equals(2));
    });
  });
}
