


import 'package:flutter/widgets.dart';
import 'package:flutter_image_loader/adapter/image_loader_adapter.dart';
import 'package:flutter_image_loader/bean/loadable_source.dart';
import 'package:flutter_image_loader/bean/loadable_source_config.dart';
import 'package:flutter_image_loader/engine/simple_image_provider.dart';


/// 简单的图片适配器
class SimpleImageAdapter extends ImageLoaderAdapter{

  /// 加载图片资源模式
  final LoadAsyncFunction loadAsync;

  SimpleImageAdapter({
    required this.loadAsync,
  });

  @override
  Widget load(LoadableSource source, LoadableSourceConfig config) {
    return Image(
      key: config.key,
      image: resizeIfNeeded(config.cacheWidth, config.cacheHeight, SimpleImageProvider(loadAsync, source, config)),
      width: config.width,
      height: config.height,
      fit: config.fit,
      alignment: config.alignment,
      gaplessPlayback: config.gaplessPlayback,
      filterQuality: config.filterQuality,
      loadingBuilder: config.placeholderBuild == null ? null :
          (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
        // 加载完成
        if (loadingProgress == null) {
          return child;
        }
        // 加载中
        return config.placeholderWidget;
      },
      errorBuilder: config.errorBuild == null ? null :
          (BuildContext context, Object error, StackTrace? stackTrace) {
        return config.errorWidget;
      },
    );
  }

}

