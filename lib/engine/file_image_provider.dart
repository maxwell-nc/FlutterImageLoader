
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui show Codec, ImmutableBuffer;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_image_loader/core/image_loader_widget.dart';
import 'package:flutter_image_loader/engine/completer/multi_frame_image_stream_completer_safe.dart';

/// 参考[FileImage]改写的文件图片加载器
/// 修正部分崩溃问题
/// 增加监听能力
class ImageLoaderFileImage extends ImageProvider<ImageLoaderFileImage> {

  /// 加载的文件
  final File file;

  /// 缩放比例
  final double scale;

  final ImageLoaderListener? listener;

  const ImageLoaderFileImage(this.file, { this.scale = 1.0 , this.listener});

  @override
  Future<ImageLoaderFileImage> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<ImageLoaderFileImage>(this);
  }

  @override
  // ignore: deprecated_member_use
  ImageStreamCompleter load(ImageLoaderFileImage key, DecoderCallback decode) {
    return MultiFrameImageStreamCompleterSafe(
      codec: _loadAsync(key, null, decode),
      scale: key.scale,
      debugLabel: key.file.path,
      informationCollector: () => <DiagnosticsNode>[
        ErrorDescription('Path: ${file.path}'),
      ],
      listener: listener,
    );
  }

  /// Flutter 3.3+ API
  @override
  ImageStreamCompleter loadBuffer(ImageLoaderFileImage key, DecoderBufferCallback decode) {
    return MultiFrameImageStreamCompleterSafe(
      codec: _loadAsync(key, decode, null),
      scale: key.scale,
      debugLabel: key.file.path,
      informationCollector: () => <DiagnosticsNode>[
        ErrorDescription('Path: ${file.path}'),
      ],
      listener: listener,
    );
  }

  // ignore: deprecated_member_use
  Future<ui.Codec> _loadAsync(ImageLoaderFileImage key, DecoderBufferCallback? decode, DecoderCallback? decodeDeprecated) async {
    assert(key == this);

    // 官方使用异步方式，但根据github，应该改成同步
    // https://github.com/flutter/flutter/issues/113044
    final int lengthInBytes = file.lengthSync();

    if (lengthInBytes == 0) {
      PaintingBinding.instance.imageCache.evict(key);
      throw StateError('$file is empty and cannot be loaded as an image.');
    }

    if (decode != null) {
      if (file.runtimeType == File) {
        return decode(await ui.ImmutableBuffer.fromFilePath(file.path));
      }
      return decode(await ui.ImmutableBuffer.fromUint8List(await file.readAsBytes()));
    }
    return decodeDeprecated!(await file.readAsBytes());
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is ImageLoaderFileImage
        && other.file.path == file.path
        && other.scale == scale;
  }

  @override
  int get hashCode => Object.hash(file.path, scale);

  @override
  String toString() => '${objectRuntimeType(this, 'ImageLoaderFileImage')}("${file.path}", scale: $scale)';

}