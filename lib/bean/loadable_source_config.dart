


import 'package:flutter/widgets.dart';
import 'package:flutter_image_loader/core/image_loader_widget.dart';

class LoadableSourceConfig {

  final Key? key;

  /// 图片宽
  /// 如果不设置则为动态宽度
  final double? width;

  /// 图片高
  /// 如果不设置则为动态高度
  final double? height;

  /// 调整图片宽
  /// 如果不设置则按原图加载
  final int? cacheWidth;

  /// 调整图片高
  /// 如果不设置则按原图加载
  final int? cacheHeight;

  /// 加载中控件构建方法
  final ImageWidgetBuilder? placeholderBuild;

  /// 错误控件构建方法
  final ImageWidgetBuilder? errorBuild;

  /// 加载状态监听
  final ImageLoaderListener? listener;

  /// 缓存的key，用于解决不同timestamp同一图片缓存问题
  String? cacheKey;

  /// 图片适配方式
  final BoxFit? fit;

  /// 用于支持雪碧图偏移显示
  final Alignment alignment;

  /// 用于解决图片切换间隔时闪一下
  final bool gaplessPlayback;

  /// 滤镜质量
  final FilterQuality filterQuality;

  /// 仅用于网络图片时有效
  final Map<String, String>? headers;

  Widget get errorWidget =>
      errorBuild?.call() ?? SizedBox(height: height, width: width);

  Widget get placeholderWidget =>
      placeholderBuild?.call() ?? SizedBox(height: height, width: width);

  LoadableSourceConfig({
    required this.key,
    required this.width,
    required this.height,
    required this.cacheWidth,
    required this.cacheHeight,
    required this.placeholderBuild,
    required this.errorBuild,
    required this.listener,
    required this.cacheKey,
    required this.fit,
    required this.alignment,
    required this.gaplessPlayback,
    required this.filterQuality,
    required this.headers,
  });


  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is LoadableSourceConfig) {
      // key相同则相同
      if (key == other.key) {
        return true;
      }

      return
        runtimeType == other.runtimeType &&
            width == other.width &&
            height == other.height &&
            cacheKey == other.cacheKey &&
            fit == other.fit &&
            alignment == other.alignment &&
            headers == other.headers;
    }

    return false;
  }

  @override
  int get hashCode =>
      width.hashCode ^
      height.hashCode ^
      cacheKey.hashCode ^
      fit.hashCode ^
      alignment.hashCode ^
      headers.hashCode;

  @override
  String toString() {
    return 'LoadableSourceConfig{width: $width, height: $height, placeholderBuild: $placeholderBuild, errorBuild: $errorBuild, listener: $listener, cacheKey: $cacheKey, fit: $fit, alignment: $alignment, headers: $headers}';
  }

}