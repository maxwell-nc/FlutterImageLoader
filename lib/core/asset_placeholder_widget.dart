

import 'package:flutter/material.dart';
import 'package:flutter_image_loader/engine/asset_image_provider.dart';

/// 资源占位图
class AssetPlaceholderWidget extends StatelessWidget {

  /// 资源图
  ///
  /// 例如："assets/test.png"
  final String asset;

  /// 图片宽
  /// 如果不设置则为动态宽度
  final double? width;

  /// 图片高
  /// 如果不设置则为动态高度
  final double? height;

  /// 用于支持雪碧图偏移显示
  final Alignment alignment;

  /// 图片适配方式
  final BoxFit? fit;

  const AssetPlaceholderWidget(
    this.asset, {
    Key? key,
    this.width,
    this.height,
    this.fit,
    this.alignment = Alignment.center,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Image(
      image: ImageLoaderAssetImage(asset),
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
    );
  }

}
