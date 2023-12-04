

/// 缓存接口
abstract class ImageLoaderCache<K, V> {

  /// 加载已缓存的图像数据
  Future<V?> load(K key);

  /// 缓存图像数据到本地存储
  Future<void> store(K key, V value);

  /// 删除指定的本地缓存图像
  Future<void> delete(K key);

  /// 清空所有缓存
  Future<void> clear();

}
