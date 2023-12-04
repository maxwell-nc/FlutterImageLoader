
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_loader/bean/loadable_source.dart';

/// 由ImageLoaderWidget传递进来的任意类型source，转换为统一的LoadableSource
typedef ApplyFunction = LoadableSource Function(dynamic source);


/// 转换器接口
class ImageLoaderTransformer {

  final ApplyFunction apply;

  ImageLoaderTransformer(this.apply);

  /// 默认为单例
  static ImageLoaderTransformer? _defaultTransformer;

  /// 默认转换器
  static ImageLoaderTransformer getDefault() {
    _defaultTransformer ??= ImageLoaderTransformer(defaultApply);
    return _defaultTransformer!;
  }

  static ApplyFunction defaultApply = (source) {
    if (source is String) {
      if (source.startsWith("http")) {
        return LoadableSource.http(source);
      }

      // web不支持本地文件访问
      if (kIsWeb != true) {
        if (Platform.isWindows) {
          // 大小写盘符，加冒号
          if (source.length > 3 && source[1] == ':') {
            return LoadableSource.local(source);
          }
        }

        if (Platform.isLinux ||
            Platform.isAndroid ||
            Platform.isIOS ||
            Platform.isMacOS) {
          if (source.startsWith("/") || source.startsWith("file:")) {
            return LoadableSource.local(source);
          }
        }
      }

      // 示例：
      // package:
      // assets/
      // images/
      return LoadableSource.asset(source);
    }

    if (source is File && kIsWeb != true) {
      return LoadableSource.local(source.path);
    }

    return LoadableSource.unknown(source.toString());
  };

}


