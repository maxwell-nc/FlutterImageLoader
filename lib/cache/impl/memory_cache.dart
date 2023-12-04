

import 'dart:typed_data';

import 'package:flutter_image_loader/cache/lru_cache.dart';
import 'package:flutter_image_loader/cache/image_loader_cache.dart';

/// 内存缓存管理
class ImageLoaderMemoryCache extends ImageLoaderCache<String, Uint8List> {

  late LruCache<String, Uint8List> _cache;

  /// [maxSize] 最大缓存图片数量
  /// [maxMB] 最大缓存容量
  ImageLoaderMemoryCache({int maxSize = 6000, int maxMB = 150}) {
    _cache = LruCache<String, Uint8List>((element) {
      return element.length;
    }, maxSize: maxSize, maxMB: maxMB);
  }

  @override
  Future<Uint8List?> load(String key) async {
    return _cache[key];
  }

  @override
  Future<void> store(String key, Uint8List value) async {
    _cache.put(key, value);
  }

  @override
  Future<void> delete(String key) async {
    _cache.remove(key);
  }

  @override
  Future<void> clear() async {
    _cache.clear();
  }

}