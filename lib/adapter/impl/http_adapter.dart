

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_image_loader/adapter/image_loader_adapter.dart';
import 'package:flutter_image_loader/bean/loadable_source.dart';
import 'package:flutter_image_loader/bean/loadable_source_config.dart';

import 'package:flutter_image_loader/engine/network_image_provider.dart'
if (dart.library.html) 'package:flutter_image_loader/engine/web_image_provider.dart' as network_image;


/// 网络图默认加载适配器
class HttpImageAdapter extends ImageLoaderAdapter {

  @override
  Widget load(LoadableSource source, LoadableSourceConfig config) {
    return Image(
      key: config.key,
      image: resizeIfNeeded(config.cacheWidth, config.cacheHeight, network_image.ImageLoaderNetworkImage(
          source.uri,
          source: source,
          config: config
      )),
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