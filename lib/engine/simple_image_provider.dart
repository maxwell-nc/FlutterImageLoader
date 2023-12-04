import 'dart:async';
import 'dart:ui' as ui show Codec, ImmutableBuffer;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_image_loader/bean/loadable_source.dart';
import 'package:flutter_image_loader/bean/loadable_source_config.dart';
import 'package:flutter_image_loader/cache/cache_manager.dart';
import 'package:flutter_image_loader/engine/completer/multi_frame_image_stream_completer_safe.dart';


typedef LoadAsyncFunction = Future<Uint8List> Function(LoadableSource source, LoadableSourceConfig config);

/// 利用加载方法加载图片的
class SimpleImageProvider extends ImageProvider<SimpleImageProvider> {

  /// 加载方法
  final LoadAsyncFunction loadAsync;

  final LoadableSource source;

  final LoadableSourceConfig config;

  SimpleImageProvider(this.loadAsync, this.source, this.config);

  @override
  // ignore: deprecated_member_use
  ImageStreamCompleter load(SimpleImageProvider key, DecoderCallback decode) {
    final StreamController<ImageChunkEvent> chunkEvents = StreamController<ImageChunkEvent>();

    return MultiFrameImageStreamCompleterSafe(
      codec: _loadAsync(key, chunkEvents, null, decode),
      chunkEvents: chunkEvents.stream,
      scale: 1.0,
      debugLabel: key.source.uri,
      informationCollector: () => <DiagnosticsNode>[
        ErrorDescription('Uri: ${key.source.uri}'),
      ],
      listener: key.config.listener,
    );
  }


  /// Flutter 3.3+ API
  @override
  ImageStreamCompleter loadBuffer(SimpleImageProvider key, DecoderBufferCallback decode) {
    final StreamController<ImageChunkEvent> chunkEvents = StreamController<ImageChunkEvent>();

    return MultiFrameImageStreamCompleterSafe(
      codec: _loadAsync(key, chunkEvents, decode, null),
      chunkEvents: chunkEvents.stream,
      scale: 1.0,
      debugLabel: key.source.uri,
      informationCollector: () => <DiagnosticsNode>[
        ErrorDescription('Uri: ${key.source.uri}'),
      ],
      listener: key.config.listener,
    );
  }

  Future<ui.Codec> _loadAsync(
    SimpleImageProvider key,
    StreamController<ImageChunkEvent> chunkEvents,
    DecoderBufferCallback? decode,
    // ignore: deprecated_member_use
    DecoderCallback? decodeDeprecated,
  ) async {
    assert(key == this);

    // 读取缓存
    var cacheData = await ImageLoaderCacheManager().loadCache(key.source, key.config);
    if (cacheData != null) {
      if (decode != null) {
        final ui.ImmutableBuffer buffer = await ui.ImmutableBuffer.fromUint8List(cacheData);
        return decode(buffer);
      } else if (decodeDeprecated != null){
        return decodeDeprecated(cacheData);
      }
    }

    // 显示loading用
    chunkEvents.add(const ImageChunkEvent(cumulativeBytesLoaded: 0, expectedTotalBytes: 100));

    final Uint8List bytes = await loadAsync.call(source, config);

    chunkEvents.close();

    if (bytes.lengthInBytes == 0) {
      // The file may become available later.
      PaintingBinding.instance.imageCache.evict(key);

      ImageLoaderCacheManager().deleteCache(key.source, key.config);
      throw StateError('$source is empty and cannot be loaded as an image.');
    }

    // 缓存
    ImageLoaderCacheManager().storeCache(key.source, key.config, bytes);
    if (decode != null) {
      final ui.ImmutableBuffer buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      return decode(buffer);
    } else {
      assert(decodeDeprecated != null);
      return decodeDeprecated!(bytes);
    }
  }

  @override
  Future<SimpleImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<SimpleImageProvider>(this);
  }

  @override
  bool operator ==(Object other) {
    if (other is SimpleImageProvider) {

      if (other.runtimeType == runtimeType) {

        if (other.config.key == config.key) {
          return true;
        }

        // 如果没设置cacheKey，按地址
        if (config.cacheKey == null || other.config.cacheKey == null) {
          return other.source == source;
        }

        return other.config == config;
      }
    }

    return false;
  }

  @override
  int get hashCode => Object.hash(source, config);

  @override
  String toString() => '${objectRuntimeType(this, 'SimpleImageProvider')}("$source", config: $config)';

}