

import 'package:flutter/widgets.dart';
import 'package:flutter_image_loader/bean/loadable_source.dart';
import 'package:flutter_image_loader/bean/loadable_source_config.dart';

/// 图片加载适配器
abstract class ImageLoaderAdapter {

  /// [source] 由ImageLoaderTransformer传递进来的source
  /// [config] 加载的图片配置
  Widget load(LoadableSource source, LoadableSourceConfig config);

  /// 减少图片加载内存，按图片控件大小加载图质量
  ImageProvider resizeIfNeeded(int? cacheWidth, int? cacheHeight, ImageProvider provider){
    return ResizeImage.resizeIfNeeded(cacheWidth, cacheHeight, provider);
  }

}