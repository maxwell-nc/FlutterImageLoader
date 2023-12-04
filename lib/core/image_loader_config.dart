
import 'dart:typed_data';

import 'package:flutter_image_loader/adapter/image_loader_adapter.dart';
import 'package:flutter_image_loader/adapter/impl/simple_adapter.dart';
import 'package:flutter_image_loader/bean/loadable_source.dart';
import 'package:flutter_image_loader/bean/loadable_source_config.dart';
import 'package:flutter_image_loader/cache/image_loader_cache.dart';
import 'package:flutter_image_loader/transform/image_loader_transformer.dart';

typedef CreateCacheKeyFunction = String? Function(LoadableSource source, LoadableSourceConfig config);

typedef LogPrinter = void Function(String log);

/// 全局配置
class ImageLoaderConfig {

  /// 工厂方法构造函数
  factory ImageLoaderConfig() => _getInstance();

  /// 静态变量_instance，存储唯一对象
  static ImageLoaderConfig? _instance;

  /// 获取唯一对象
  static ImageLoaderConfig _getInstance() {
    _instance ??= ImageLoaderConfig._internal();
    return _instance!;
  }

  /// 单例
  ImageLoaderConfig._internal();

  /// 转换器
  ImageLoaderTransformer? _transformer;

  ImageLoaderTransformer get transformer => _transformer ?? ImageLoaderTransformer.getDefault();

  set transformer(ImageLoaderTransformer transformer) {
    _transformer = transformer;
  }

  /// 自定义的适配器
  /// key：LoadableSource的Type
  /// value：处理的逻辑
  ///
  /// 注意，此集合包括用户创建的适配器
  /// [SimpleImageAdapter] 可以使用这个类简单创建
  final Map<String, ImageLoaderAdapter> customAdapters = {};

  /// 内存缓存
  /// 默认参考[ImageLoaderMemoryCache]
  /// 不设置则没有缓存
  ImageLoaderCache<String, Uint8List>? memoryCache;

  /// 本地缓存
  /// 默认参考[ImageLoaderDiskCache]
  /// 不设置则没有缓存
  ImageLoaderCache<String, Uint8List>? diskCache;

  /// 创建默认缓存key
  /// 当某个图片设置 cacheKey 为null 则使用此方法生成，若还返回null，则表示不缓存
  CreateCacheKeyFunction getDefaultCacheKey = (source, config) {
    // 默认不缓存
    return null;
  };

  /// 打印日志
  LogPrinter? logger;

}
