
import 'dart:collection';

/// 模拟LRU策略的集合
///
/// 只实现了FIFO能力，最近使用未实现，可以考虑用[SplayTreeMap]实现
class LruCache<K, V> {

  /// map默认创建就是[LinkedHashMap]
  final Map<K, V> _cache;

  /// 最大元素数量
  final int maxSize;

  /// 最大大小
  final int maxBytes;

  /// 获取某个元素的大小
  final int Function(V v) getElementBytes;

  /// 当前集合
  int _currentBytes = 0;

  LruCache(this.getElementBytes, {required this.maxSize, required int maxMB}):
        _cache = <K, V>{},
        maxBytes = maxMB * 1024 * 1024,
        assert(maxSize > 0),
        assert(maxMB > 0);

  put(K key, V value) {
    if (containsKey(key)) {
      remove(key);
    }
    if (length >= maxSize) {
      remove(_cache.keys.first);
    }
    _currentBytes = _currentBytes + getElementBytes.call(value);
    while (_currentBytes >= maxBytes) {
      remove(_cache.keys.first);
    }

    _cache[key] = value;
  }


  V? remove(K key) {
    V? v = _cache.remove(key);
    if (v != null) {
      _currentBytes = _currentBytes - getElementBytes.call(v);
    }
    return v;
  }

  operator [](K? key) => _cache[key];

  void operator []=(key, value) {
    put(key, value);
  }

  Map<K, V> getAll() => Map.from(_cache);

  V? get(K key) => _cache[key];

  bool containsKey(Object? key) => _cache.containsKey(key);

  bool containsValue(Object? value) => _cache.containsValue(value);

  bool get isEmpty => _cache.isEmpty;

  bool get isNotEmpty => _cache.isNotEmpty;

  Iterable<K> get keys => _cache.keys;

  Iterable<V> get values => _cache.values;

  int get length => _cache.length;

  clear() => _cache.clear();

  @override
  String toString() {
    return 'LruCache{_cache: $_cache, maxSize: $maxSize, maxMB: $maxBytes}';
  }

}