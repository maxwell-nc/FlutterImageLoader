

import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_image_loader/adapter/image_loader_adapter.dart';
import 'package:flutter_image_loader/bean/loadable_source.dart';
import 'package:flutter_image_loader/bean/loadable_source_config.dart';
import 'package:flutter_image_loader/engine/file_image_provider.dart';

/// 本地图默认加载适配器
class LocalImageAdapter extends ImageLoaderAdapter {

  @override
  Widget load(LoadableSource source, LoadableSourceConfig config) {
    return Image(
      key: config.key,
      image: resizeIfNeeded(config.cacheWidth, config.cacheHeight, ImageLoaderFileImage(File(source.uri), listener: config.listener)),
      width: config.width,
      height: config.height,
      fit: config.fit,
      alignment: config.alignment,
      gaplessPlayback: config.gaplessPlayback,
      filterQuality: config.filterQuality,
      errorBuilder: config.errorBuild == null ? null :
          (BuildContext context, Object error, StackTrace? stackTrace) {
        return config.errorWidget;
      },
    );
  }

}