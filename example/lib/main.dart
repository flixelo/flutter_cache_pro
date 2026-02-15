import 'package:flutter/material.dart';
import 'package:flutter_cache_pro/flutter_cache_pro.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize cache with custom config
  await CachePro.instance.initialize(
    CacheConfig(
      maxMemorySize: 50 * 1024 * 1024, // 50MB
      maxDiskSize: 200 * 1024 * 1024, // 200MB
      defaultTtl: Duration(hours: 1),
      enableStats: true,
    ),
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CachePro Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const CacheDemo(),
    );
  }
}

class CacheDemo extends StatefulWidget {
  const CacheDemo({super.key});

  @override
  State<CacheDemo> createState() => _CacheDemoState();
}

class _CacheDemoState extends State<CacheDemo> {
  final cache = CachePro.instance;
  String _output = '';
  CacheStats? _stats;

  @override
  void initState() {
    super.initState();
    _refreshStats();
  }

  Future<void> _refreshStats() async {
    final stats = await cache.getStats();
    setState(() {
      _stats = stats;
    });
  }

  Future<void> _runBasicTest() async {
    setState(() => _output = 'Running basic test...\n');
    
    // Put some values
    await cache.put('name', 'John Doe');
    await cache.put('age', 30);
    await cache.put('email', 'john@example.com');
    
    _appendOutput('✅ Stored 3 values\n');
    
    // Retrieve values
    final name = await cache.get<String>('name');
    final age = await cache.get<int>('age');
    final email = await cache.get<String>('email');
    
    _appendOutput('📥 Retrieved:\n');
    _appendOutput('  Name: $name\n');
    _appendOutput('  Age: $age\n');
    _appendOutput('  Email: $email\n');
    
    await _refreshStats();
  }

  Future<void> _runTtlTest() async {
    setState(() => _output = 'Running TTL test...\n');
    
    // Cache with 2 second TTL
    await cache.put(
      'temp_value',
      'This will expire',
      ttl: Duration(seconds: 2),
    );
    
    _appendOutput('✅ Stored with 2s TTL\n');
    
    // Get immediately
    var value = await cache.get<String>('temp_value');
    _appendOutput('📥 Immediate: $value\n');
    
    // Wait 3 seconds
    _appendOutput('⏳ Waiting 3 seconds...\n');
    await Future.delayed(Duration(seconds: 3));
    
    // Try to get again
    value = await cache.get<String>('temp_value');
    _appendOutput('📥 After 3s: ${value ?? "EXPIRED ✅"}\n');
    
    await _refreshStats();
  }

  Future<void> _runPriorityTest() async {
    setState(() => _output = 'Running priority test...\n');
    
    // Add items with different priorities
    await cache.put('high', 'High priority data', 
      priority: CachePriority.high);
    await cache.put('medium', 'Medium priority data', 
      priority: CachePriority.medium);
    await cache.put('low', 'Low priority data', 
      priority: CachePriority.low);
    
    _appendOutput('✅ Stored 3 items with different priorities\n');
    _appendOutput('  🔴 High: Will be kept longest\n');
    _appendOutput('  🟡 Medium: Default behavior\n');
    _appendOutput('  🟢 Low: Evicted first when full\n');
    
    await _refreshStats();
  }

  Future<void> _runGetOrPutTest() async {
    setState(() => _output = 'Running getOrPut test...\n');
    
    // First call - will compute
    _appendOutput('First call (will compute)...\n');
    final value1 = await cache.getOrPut(
      'expensive_data',
      () async {
        await Future.delayed(Duration(seconds: 1));
        return 'Computed value';
      },
    );
    _appendOutput('✅ Result: $value1 (took 1s)\n');
    
    // Second call - from cache
    _appendOutput('\nSecond call (from cache)...\n');
    final start = DateTime.now();
    final value2 = await cache.getOrPut(
      'expensive_data',
      () async {
        await Future.delayed(Duration(seconds: 1));
        return 'Computed value';
      },
    );
    final duration = DateTime.now().difference(start).inMilliseconds;
    _appendOutput('✅ Result: $value2 (took ${duration}ms)\n');
    
    await _refreshStats();
  }

  Future<void> _clearCache() async {
    await cache.clear();
    setState(() {
      _output = '🗑️ Cache cleared\n';
    });
    await _refreshStats();
  }

  void _appendOutput(String text) {
    setState(() {
      _output += text;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CachePro Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshStats,
            tooltip: 'Refresh Stats',
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats Card
          if (_stats != null)
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cache Statistics',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    _buildStatRow('Hit Rate', '${_stats!.hitRate.toStringAsFixed(1)}%'),
                    _buildStatRow('Hits', _stats!.hits.toString()),
                    _buildStatRow('Misses', _stats!.misses.toString()),
                    _buildStatRow('Memory Entries', _stats!.memoryEntries.toString()),
                    _buildStatRow('Disk Entries', _stats!.diskEntries.toString()),
                    _buildStatRow('Memory Size', _stats!.formatSize(_stats!.memorySize)),
                    _buildStatRow('Disk Size', _stats!.formatSize(_stats!.diskSize)),
                  ],
                ),
              ),
            ),
          
          // Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: _runBasicTest,
                  child: const Text('Basic Test'),
                ),
                ElevatedButton(
                  onPressed: _runTtlTest,
                  child: const Text('TTL Test'),
                ),
                ElevatedButton(
                  onPressed: _runPriorityTest,
                  child: const Text('Priority Test'),
                ),
                ElevatedButton(
                  onPressed: _runGetOrPutTest,
                  child: const Text('GetOrPut Test'),
                ),
                ElevatedButton(
                  onPressed: _clearCache,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Clear Cache'),
                ),
              ],
            ),
          ),
          
          // Output
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                child: Text(
                  _output.isEmpty ? 'Run a test to see output...' : _output,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    color: Colors.greenAccent,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
