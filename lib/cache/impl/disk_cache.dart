

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_loader/cache/image_loader_cache.dart';
import 'package:flutter_image_loader/core/image_loader_config.dart';


/// 本地缓存管理
class ImageLoaderDiskCache extends ImageLoaderCache<String, Uint8List> {

  /// 缓存路径
  /// 例如：D:\
  late String cachePath;

  ImageLoaderDiskCache(String cachePath) {
    var dir = Directory(cachePath);

    try {
      // 创建不存在的文件夹
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
    } catch (e) {
      _debugPrint("$e");
    }

    // 自动追加分隔符
    if (dir.path.endsWith("/") || dir.path.endsWith('\\')) {
      this.cachePath = dir.path;
    } else {
      this.cachePath = dir.path + Platform.pathSeparator;
    }

    _debugPrint("ImageLoaderDiskCache：设置本地缓存:${this.cachePath}");
  }

  /// 缓存路径
  String _getCacheFilePath(String key) => cachePath + key;

  @override
  Future<Uint8List?> load(String key) async {
    if (_isWeb) {
      return null;
    }
    String cacheFilePath = _getCacheFilePath(key);

    var file = File(cacheFilePath);
    bool exist = await file.exists();
    if (exist) {
      final Uint8List bytes = await file.readAsBytes();
      return bytes;
    }
    return null;
  }

  @override
  Future<void> store(String key, Uint8List value) async {
    if (_isWeb) {
      return;
    }
    String cacheFilePath = _getCacheFilePath(key);
    var file = File(cacheFilePath);
    bool exist = await file.exists();
    if (!exist) {
      try {
        await file.writeAsBytes(value);
      } catch (e) {
        _debugPrint("$e");
      }
    }
  }

  @override
  Future<void> delete(String key) async {
    if (_isWeb) {
      return;
    }
    String cacheFilePath = _getCacheFilePath(key);
    var file = File(cacheFilePath);
    bool exist = await file.exists();
    if (exist) {
      try {
        await file.delete();
      } catch (e) {
        _debugPrint("$e");
      }
    }
  }

  @override
  Future<void> clear() async {
    if (_isWeb) {
      return;
    }
    var file = Directory(cachePath);
    await file.delete(recursive: true);
  }

  /// 是否网页
  /// 网页不支持文件操作
  bool get _isWeb {
    //相当Platform.isWeb
    return (kIsWeb == true);
  }

  /// 输出日志
  void _debugPrint(String log) {
    ImageLoaderConfig().logger?.call(log);
  }

}