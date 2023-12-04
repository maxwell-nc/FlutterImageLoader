


import 'dart:typed_data';

import 'package:flutter_image_loader/bean/loadable_source.dart';
import 'package:flutter_image_loader/bean/loadable_source_config.dart';
import 'package:flutter_image_loader/core/image_loader_config.dart';

/// 缓存管理器
class ImageLoaderCacheManager {

  /// 工厂方法构造函数
  factory ImageLoaderCacheManager() => _getInstance();

  /// 静态变量_instance，存储唯一对象
  static ImageLoaderCacheManager? _instance;

  /// 获取唯一对象
  static ImageLoaderCacheManager _getInstance() {
    _instance ??= ImageLoaderCacheManager._internal();
    return _instance!;
  }

  /// 单例
  ImageLoaderCacheManager._internal();

  /// 加载已缓存的图像数据
  Future<Uint8List?> loadCache(LoadableSource source, LoadableSourceConfig config) async {
    var cacheKey = config.cacheKey;
    if (cacheKey == null) {
      return null;
    }

    // 内存缓存
    var memCache = await ImageLoaderConfig().memoryCache?.load(cacheKey);
    if (memCache != null) {
      _debugPrint("image from memory");
      return memCache;
    }

    // 本地缓存
    var diskCache = await ImageLoaderConfig().diskCache?.load(cacheKey);
    if (diskCache != null) {

      // 此处代表存在本地缓存，但是没有内存缓存
      // 放一份到内存缓存
      ImageLoaderConfig().memoryCache?.store(cacheKey, diskCache);

      _debugPrint("image from disk");
      return diskCache;
    }

    return null;
  }

  /// 缓存图像数据
  Future<void> storeCache(LoadableSource source, LoadableSourceConfig config, Uint8List data) async {
    var cacheKey = config.cacheKey;
    if (cacheKey == null) {
      return;
    }

    // 内存缓存
    await ImageLoaderConfig().memoryCache?.store(cacheKey, data);

    // 本地缓存
    await ImageLoaderConfig().diskCache?.store(cacheKey, data);
  }

  /// 删除指定的缓存图像
  Future<void> deleteCache(LoadableSource source, LoadableSourceConfig config) async {
    var cacheKey = config.cacheKey;
    if (cacheKey == null) {
      return;
    }

    await ImageLoaderConfig().memoryCache?.delete(cacheKey);
    await ImageLoaderConfig().diskCache?.delete(cacheKey);
  }

  /// 清空所有缓存
  Future<void> clearCache() async {
    await ImageLoaderConfig().memoryCache?.clear();
    await ImageLoaderConfig().diskCache?.clear();
  }

  /// 输出日志
  void _debugPrint(String log) {
    ImageLoaderConfig().logger?.call(log);
  }

}