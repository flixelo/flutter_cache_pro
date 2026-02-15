/// Cache priority levels for managing eviction order
enum CachePriority {
  /// Low priority - evicted first when cache is full
  low(1),
  
  /// Medium priority - default level
  medium(2),
  
  /// High priority - kept longer, evicted last
  high(3);

  const CachePriority(this.value);
  
  final int value;
  
  /// Compare priorities
  bool operator >(CachePriority other) => value > other.value;
  bool operator <(CachePriority other) => value < other.value;
  bool operator >=(CachePriority other) => value >= other.value;
  bool operator <=(CachePriority other) => value <= other.value;
}
