import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:crypto/crypto.dart';
import '../cache_entry.dart';

/// Disk storage for persistent caching
class DiskStorage {
  final String cacheDir;
  final int maxSize;
  Directory? _directory;
  int _currentSize = 0;
  final Map<String, File> _fileCache = {};

  DiskStorage({
    required this.cacheDir,
    required this.maxSize,
  });

  /// Initialize disk storage
  Future<void> initialize() async {
    _directory = Directory(cacheDir);
    if (!await _directory!.exists()) {
      await _directory!.create(recursive: true);
    }
    await _calculateCurrentSize();
  }

  /// Get entry from disk
  Future<CacheEntry?> get(String key) async {
    if (_directory == null) return null;

    final file = _getFile(key);
    if (!await file.exists()) return null;

    try {
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      final entry = CacheEntry.fromJson(json);

      if (entry.isExpired) {
        await remove(key);
        return null;
      }

      entry.markAccessed();
      // Update file with new access time
      await file.writeAsString(jsonEncode(entry.toJson()));
      
      return entry;
    } catch (e) {
      // Corrupted cache file, remove it
      await file.delete();
      return null;
    }
  }

  /// Put entry on disk
  Future<void> put(CacheEntry entry) async {
    if (_directory == null) return;

    // Evict if necessary
    while (_currentSize + entry.size > maxSize && _currentSize > 0) {
      await _evictLru();
    }

    final file = _getFile(entry.key);
    final json = jsonEncode(entry.toJson());
    await file.writeAsString(json);

    final fileSize = await file.length();
    _currentSize += fileSize;
    _fileCache[entry.key] = file;
  }

  /// Remove entry from disk
  Future<void> remove(String key) async {
    final file = _getFile(key);
    if (await file.exists()) {
      final size = await file.length();
      await file.delete();
      _currentSize -= size;
      _fileCache.remove(key);
    }
  }

  /// Check if key exists on disk
  Future<bool> containsKey(String key) async {
    final file = _getFile(key);
    return await file.exists();
  }

  /// Get all keys on disk
  Future<List<String>> getKeys() async {
    if (_directory == null) return [];

    final files = await _directory!.list().toList();
    return files
        .whereType<File>()
        .map((f) => path.basenameWithoutExtension(f.path))
        .toList();
  }

  /// Clear all entries on disk
  Future<void> clear() async {
    if (_directory == null) return;

    final files = await _directory!.list().toList();
    for (final file in files) {
      if (file is File) {
        await file.delete();
      }
    }
    _currentSize = 0;
    _fileCache.clear();
  }

  /// Clear expired entries
  Future<int> clearExpired() async {
    if (_directory == null) return 0;

    int count = 0;
    final files = await _directory!.list().toList();

    for (final file in files) {
      if (file is File) {
        try {
          final content = await file.readAsString();
          final json = jsonDecode(content) as Map<String, dynamic>;
          final entry = CacheEntry.fromJson(json);

          if (entry.isExpired) {
            await file.delete();
            _currentSize -= await file.length();
            count++;
          }
        } catch (e) {
          // Corrupted file, delete it
          await file.delete();
          count++;
        }
      }
    }

    return count;
  }

  /// Evict least recently used entry
  Future<void> _evictLru() async {
    if (_directory == null) return;

    final files = await _directory!.list().toList();
    if (files.isEmpty) return;

    CacheEntry? lruEntry;
    File? lruFile;
    double lowestScore = double.infinity;

    for (final file in files) {
      if (file is File) {
        try {
          final content = await file.readAsString();
          final json = jsonDecode(content) as Map<String, dynamic>;
          final entry = CacheEntry.fromJson(json);

          final score = entry.lruScore;
          if (score < lowestScore) {
            lowestScore = score;
            lruEntry = entry;
            lruFile = file;
          }
        } catch (e) {
          // Corrupted file, delete it
          await file.delete();
        }
      }
    }

    if (lruFile != null && lruEntry != null) {
      final size = await lruFile.length();
      await lruFile.delete();
      _currentSize -= size;
      _fileCache.remove(lruEntry.key);
    }
  }

  /// Calculate current disk usage
  Future<void> _calculateCurrentSize() async {
    if (_directory == null) return;

    _currentSize = 0;
    final files = await _directory!.list().toList();

    for (final file in files) {
      if (file is File) {
        _currentSize += await file.length();
      }
    }
  }

  /// Get file for a key (using hash to avoid special characters)
  File _getFile(String key) {
    final hash = md5.convert(utf8.encode(key)).toString();
    return File(path.join(_directory!.path, '$hash.cache'));
  }

  /// Get current size
  int get currentSize => _currentSize;

  /// Get stats
  Future<Map<String, dynamic>> getStats() async {
    final keys = await getKeys();
    return {
      'entries': keys.length,
      'size': currentSize,
      'maxSize': maxSize,
      'utilizationPercent': (currentSize / maxSize * 100).toStringAsFixed(2),
    };
  }
}
