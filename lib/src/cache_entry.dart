/// Cache entry with metadata
class CacheEntry<T> {
  final String key;
  final T value;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final int priority;
  final int size;
  DateTime lastAccessedAt;
  int accessCount;

  CacheEntry({
    required this.key,
    required this.value,
    required this.createdAt,
    this.expiresAt,
    required this.priority,
    required this.size,
    DateTime? lastAccessedAt,
    this.accessCount = 0,
  }) : lastAccessedAt = lastAccessedAt ?? createdAt;

  /// Check if entry has expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Check if entry is still valid
  bool get isValid => !isExpired;

  /// Age of the entry in milliseconds
  int get ageMs => DateTime.now().difference(createdAt).inMilliseconds;

  /// Time since last access in milliseconds
  int get timeSinceLastAccessMs =>
      DateTime.now().difference(lastAccessedAt).inMilliseconds;

  /// Mark as accessed
  void markAccessed() {
    lastAccessedAt = DateTime.now();
    accessCount++;
  }

  /// Calculate LRU score (lower = evict first)
  /// Factors: priority, access count, recency
  double get lruScore {
    final recencyScore = 1.0 / (timeSinceLastAccessMs + 1);
    final accessScore = accessCount.toDouble();
    final priorityScore = priority.toDouble() * 10;
    
    return (recencyScore * 0.4) + (accessScore * 0.3) + (priorityScore * 0.3);
  }

  /// Convert to JSON for disk storage
  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'value': value,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'priority': priority,
      'size': size,
      'lastAccessedAt': lastAccessedAt.toIso8601String(),
      'accessCount': accessCount,
    };
  }

  /// Create from JSON
  factory CacheEntry.fromJson(Map<String, dynamic> json) {
    return CacheEntry(
      key: json['key'],
      value: json['value'],
      createdAt: DateTime.parse(json['createdAt']),
      expiresAt: json['expiresAt'] != null 
          ? DateTime.parse(json['expiresAt']) 
          : null,
      priority: json['priority'],
      size: json['size'],
      lastAccessedAt: DateTime.parse(json['lastAccessedAt']),
      accessCount: json['accessCount'],
    );
  }

  @override
  String toString() {
    return 'CacheEntry(key: $key, priority: $priority, age: ${ageMs}ms, '
        'accessCount: $accessCount, expired: $isExpired)';
  }
}
