


import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_image_loader/adapter/impl/asset_adapter.dart';
import 'package:flutter_image_loader/adapter/impl/http_adapter.dart';
import 'package:flutter_image_loader/adapter/impl/local_adapter.dart';
import 'package:flutter_image_loader/adapter/image_loader_adapter.dart';
import 'package:flutter_image_loader/bean/loadable_source.dart';
import 'package:flutter_image_loader/bean/loadable_source_config.dart';
import 'package:flutter_image_loader/core/asset_placeholder_widget.dart';
import 'package:flutter_image_loader/core/image_loader_config.dart';


typedef ImageErrorCallback = void Function(Object exception, StackTrace? stackTrace);

typedef ImageWidgetBuilder = Widget? Function();


/// 图片加载回调
class ImageLoaderListener {

  /// 加载完成
  final VoidCallback? onLoadCompleted;

  /// 加载失败
  final ImageErrorCallback? onError;

  ImageLoaderListener({this.onLoadCompleted, this.onError});

}

/// 图片加载控件
class ImageLoaderWidget<T> extends StatelessWidget {

  /// 要加载的资源
  /// 根据不同资源，转换器转换成可加载资源，交给拦截器加载
  final T source;

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

  /// 加载中占位图资源路径
  /// 如果要使用自定义Widget，请使用[placeholderBuilder]
  /// 若[placeholderBuilder]不为空，则此参数无效
  final String? placeholder;

  /// 错误占位图资源路径
  /// 如果要使用自定义Widget，请使用[errorBuilder]
  /// 若[errorBuilder]不为空，则此参数无效
  final String? error;

  /// 支持传入加载中自定义Widget
  final ImageWidgetBuilder? placeholderBuilder;

  /// 支持传入错误自定义Widget
  final ImageWidgetBuilder? errorBuilder;

  /// 加载状态监听
  final ImageLoaderListener? listener;

  /// 缓存的key，用于解决不同timestamp同一图片缓存问题
  final String? cacheKey;

  /// 图片适配方式
  final BoxFit? fit;

  /// 用于支持雪碧图偏移显示
  final Alignment alignment;

  /// 用于解决图片切换间隔时闪一下
  final bool gaplessPlayback;

  /// 滤镜质量
  final FilterQuality filterQuality;

  /// 网络请求头部
  final Map<String, String>? headers;

  const ImageLoaderWidget(
    this.source, {
    Key? key,
    this.width,
    this.height,
    this.cacheWidth,
    this.cacheHeight,
    this.placeholder,
    this.error,
    this.placeholderBuilder,
    this.errorBuilder,
    this.listener,
    this.cacheKey,
    this.fit,
    this.alignment = Alignment.center,
    this.gaplessPlayback = false,
    this.filterQuality = FilterQuality.medium,
    this.headers,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {

    var globalConfig = ImageLoaderConfig();

    // 转换器
    LoadableSource loadableSource = globalConfig.transformer.apply(source);
    String type = loadableSource.type;

    // 图片加载配置，仅针对当前图片
    LoadableSourceConfig loadableSourceConfig = LoadableSourceConfig(
      key: key,
      width: width,
      height: height,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
      placeholderBuild: _getPlaceholderBuild(),
      errorBuild: _getErrorBuild(),
      listener: listener,
      cacheKey: cacheKey,
      fit: fit,
      alignment: alignment,
      gaplessPlayback: gaplessPlayback,
      filterQuality: filterQuality,
      headers: headers,
    );

    // 记录默认的key
    loadableSourceConfig.cacheKey ??= ImageLoaderConfig().getDefaultCacheKey(loadableSource, loadableSourceConfig);

    // 用户拦截
    var customAdapters = globalConfig.customAdapters;
    if (customAdapters.containsKey(type)) {
      return customAdapters[type]!.load(loadableSource, loadableSourceConfig);
    }

    // 默认适配器
    ImageLoaderAdapter? adapter = _getDefaultAdapter(type);
    if (adapter != null) {
      return adapter.load(loadableSource, loadableSourceConfig);
    }

    // 没有处理
    listener?.onError?.call(Exception("未找到适配器图片格式 ${loadableSource.uri}"), null);
    return loadableSourceConfig.errorWidget;
  }


  /// 获取默认的适配器
  ImageLoaderAdapter? _getDefaultAdapter(String type) {
    switch(type){
      case LoadableSource.typeHttp:
        return HttpImageAdapter();
      case LoadableSource.typeLocal:
        return LocalImageAdapter();
      case LoadableSource.typeAsset:
        return AssetImageAdapter();
    }
    return null;
  }


  /// 占位控件构建
  ImageWidgetBuilder? _getPlaceholderBuild() {
    if (placeholderBuilder != null) {
      return placeholderBuilder;
    }
    if (placeholder != null) {
      return _buildImageWidget(placeholder);
    }
    return null;
  }

  /// 错误控件构建
  ImageWidgetBuilder? _getErrorBuild() {
    if (errorBuilder != null) {
      return errorBuilder;
    }
    if (error != null) {
      return _buildImageWidget(error);
    }
    return null;
  }

  /// 占位控件构建
  ImageWidgetBuilder? _buildImageWidget(String? asset) {
    if (asset == null) {
      return null;
    }

    // 此处不使用自身控件基于两个考虑
    // 1.可能存在嵌套地狱
    // 2.部分情况，可能存在渲染问题判断问题（同Widget）
    return ()=> AssetPlaceholderWidget(
      asset,
      fit: fit,
      width: width,
      height: height,
      alignment: alignment,
    );
  }

}

