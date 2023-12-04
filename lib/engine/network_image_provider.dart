import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui show Codec, ImmutableBuffer;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_image_loader/bean/loadable_source.dart';
import 'package:flutter_image_loader/bean/loadable_source_config.dart';
import 'package:flutter_image_loader/cache/cache_manager.dart';
import 'package:flutter_image_loader/engine/completer/multi_frame_image_stream_completer_safe.dart';


/// 参考[NetworkImage]改写的文件图片加载器
/// 修正部分崩溃问题
/// 增加监听能力
class ImageLoaderNetworkImage extends ImageProvider<ImageLoaderNetworkImage> {

  final String url;

  final double scale;

  final LoadableSource source;

  final LoadableSourceConfig config;

  const ImageLoaderNetworkImage(this.url, { this.scale = 1.0, required this.source, required this.config });


  @override
  Future<ImageLoaderNetworkImage> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<ImageLoaderNetworkImage>(this);
  }

  @override
  // ignore: deprecated_member_use
  ImageStreamCompleter load(ImageLoaderNetworkImage key, DecoderCallback decode) {
    final StreamController<ImageChunkEvent> chunkEvents = StreamController<ImageChunkEvent>();

    return MultiFrameImageStreamCompleterSafe(
      codec: _loadAsync(key, chunkEvents, null, decode),
      chunkEvents: chunkEvents.stream,
      scale: key.scale,
      debugLabel: key.url,
      informationCollector: () => <DiagnosticsNode>[
        DiagnosticsProperty<ImageProvider>('Image provider', this),
        DiagnosticsProperty<ImageLoaderNetworkImage>('Image key', key),
      ],
      listener: config.listener,
    );
  }


  /// Flutter 3.3+ API
  @override
  ImageStreamCompleter loadBuffer(ImageLoaderNetworkImage key, DecoderBufferCallback decode) {
    final StreamController<ImageChunkEvent> chunkEvents = StreamController<ImageChunkEvent>();

    return MultiFrameImageStreamCompleterSafe(
      codec: _loadAsync(key, chunkEvents, decode, null),
      chunkEvents: chunkEvents.stream,
      scale: key.scale,
      debugLabel: key.url,
      informationCollector: () => <DiagnosticsNode>[
        DiagnosticsProperty<ImageProvider>('Image provider', this),
        DiagnosticsProperty<ImageLoaderNetworkImage>('Image key', key),
      ],
      listener: config.listener,
    );
  }


  /// 不要直接访问此成员，用[_httpClient]方法代替
  static final HttpClient _sharedHttpClient = HttpClient()..autoUncompress = false;

  static HttpClient get _httpClient {
    HttpClient client = _sharedHttpClient;
    assert(() {
      if (debugNetworkImageHttpClientProvider != null) {
        client = debugNetworkImageHttpClientProvider!();
      }
      return true;
    }());
    return client;
  }

  Future<ui.Codec> _loadAsync(
      ImageLoaderNetworkImage key,
      StreamController<ImageChunkEvent> chunkEvents,
      DecoderBufferCallback? decode,
      // ignore: deprecated_member_use
      DecoderCallback? decodeDeprecated,
      ) async {
    try {
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

      // 缓存前还是不要通知loading
      // 不然导致读取缓存时中间闪一下placeHolder
      chunkEvents.add(const ImageChunkEvent(cumulativeBytesLoaded: 0, expectedTotalBytes: 100));

      final Uri resolved = Uri.base.resolve(key.url);

      final HttpClientRequest request = await _httpClient.getUrl(resolved);

      config.headers?.forEach((String name, String value) {
        request.headers.add(name, value);
      });

      final HttpClientResponse response = await request.close();
      if (response.statusCode != HttpStatus.ok) {
        // 有时候网络突然不行
        await response.drain<List<int>>(<int>[]);
        throw NetworkImageLoadException(statusCode: response.statusCode, uri: resolved);
      }

      final Uint8List bytes = await consolidateHttpClientResponseBytes(
        response,
        onBytesReceived: (int cumulative, int? total) {
          chunkEvents.add(ImageChunkEvent(
            cumulativeBytesLoaded: cumulative,
            expectedTotalBytes: total,
          ));
        },
      );
      if (bytes.lengthInBytes == 0) {
        throw Exception('NetworkImage is an empty file: $resolved');
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

    } catch (e) {
      scheduleMicrotask(() {
        PaintingBinding.instance.imageCache.evict(key);

        ImageLoaderCacheManager().deleteCache(key.source, key.config);
      });
      rethrow;
    } finally {
      chunkEvents.close();
    }
  }

  @override
  bool operator ==(Object other) {
    if (other is ImageLoaderNetworkImage) {

      if (other.runtimeType == runtimeType &&
          other.scale == scale) {

        if (config.key != null && other.config.key == config.key) {
          return true;
        }

        // 如果没设置cacheKey，按地址
        if (config.cacheKey == null || other.config.cacheKey == null) {
          return other.url == url;
        }

        return other.config == config;
      }
    }

    return false;
  }

  @override
  int get hashCode => Object.hash(url, scale);

  @override
  String toString() => '${objectRuntimeType(this, 'ImageLoaderNetworkImage')}("$url", scale: $scale)';

}