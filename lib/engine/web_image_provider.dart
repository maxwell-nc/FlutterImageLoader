import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:js';

import 'dart:typed_data';
import 'dart:ui' as ui show Codec, ImmutableBuffer;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
// 此类没有导出，后续会被移除，新版使用这个处理web不支持header问题
// https://github.com/flutter/flutter/issues/113402
// ignore: implementation_imports
import 'package:flutter/src/services/dom.dart';
import 'package:flutter_image_loader/bean/loadable_source.dart';
import 'package:flutter_image_loader/bean/loadable_source_config.dart';
import 'package:flutter_image_loader/cache/cache_manager.dart';
import 'package:flutter_image_loader/engine/completer/multi_frame_image_stream_completer_safe.dart';


typedef HttpRequestFactory = DomXMLHttpRequest Function();

HttpRequestFactory httpRequestFactory = _httpClient;

/// 网页图片用
DomXMLHttpRequest _httpClient() {
  return createDomXMLHttpRequest();
}


/// 参考[NetworkImage]改写的文件图片加载器
/// 修正部分崩溃问题
/// 增加监听能力
///
/// 此处构造函数必须与network_image_provider.dart一致
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
      codec: _loadAsync(key, null, decode, chunkEvents),
      chunkEvents: chunkEvents.stream,
      scale: key.scale,
      debugLabel: key.url,
      informationCollector: _imageStreamInformationCollector(key),
      listener: config.listener,
    );
  }


  @override
  ImageStreamCompleter loadBuffer(ImageLoaderNetworkImage key, DecoderBufferCallback decode) {
    final StreamController<ImageChunkEvent> chunkEvents = StreamController<ImageChunkEvent>();

    return MultiFrameImageStreamCompleterSafe(
      chunkEvents: chunkEvents.stream,
      codec: _loadAsync(key, decode, null, chunkEvents),
      scale: key.scale,
      debugLabel: key.url,
      informationCollector: _imageStreamInformationCollector(key),
      listener: config.listener,
    );
  }

  InformationCollector? _imageStreamInformationCollector(ImageLoaderNetworkImage key) {
    InformationCollector? collector;
    assert(() {
      collector = () => <DiagnosticsNode>[
        DiagnosticsProperty<ImageProvider>('Image provider', this),
        DiagnosticsProperty<ImageLoaderNetworkImage>('Image key', key),
      ];
      return true;
    }());
    return collector;
  }

  Future<ui.Codec> _loadAsync(
      ImageLoaderNetworkImage key,
      DecoderBufferCallback? decode,
      // ignore: deprecated_member_use
      DecoderCallback? decodeDeprecated,
      StreamController<ImageChunkEvent> chunkEvents,
      ) async {

      assert(key == this);

      // 显示loading用
      chunkEvents.add(const ImageChunkEvent(cumulativeBytesLoaded: 0, expectedTotalBytes: 100));

      // 读取缓存（web仅支持内存缓存）
      var cacheData = await ImageLoaderCacheManager().loadCache(key.source, key.config);
      if (cacheData != null) {
        if (decode != null) {
          final ui.ImmutableBuffer buffer = await ui.ImmutableBuffer.fromUint8List(cacheData);
          return decode(buffer);
        } else if (decodeDeprecated != null) {
          return decodeDeprecated(cacheData);
        }
      }

      final Uri resolved = Uri.base.resolve(key.url);

      // ui.webOnlyInstantiateImageCodecFromUrl不支持headers
      final Completer<DomXMLHttpRequest> completer = Completer<DomXMLHttpRequest>();
      final DomXMLHttpRequest request = httpRequestFactory();

      request.open('GET', key.url, true);
      request.responseType = 'arraybuffer';
      key.config.headers?.forEach((String header, String value) {
        request.setRequestHeader(header, value);
      });

      request.addEventListener('load', allowInterop((DomEvent e) {
        final int? status = request.status;
        final bool accepted = status! >= 200 && status < 300;
        final bool fileUri = status == 0; // file:// URIs have status of 0.
        final bool notModified = status == 304;
        final bool unknownRedirect = status > 307 && status < 400;
        final bool success =
            accepted || fileUri || notModified || unknownRedirect;

        if (success) {
          completer.complete(request);
        } else {
          completer.completeError(e);
          throw NetworkImageLoadException(
              statusCode: request.status ?? 400, uri: resolved);
        }
      }));

      request.addEventListener('error', allowInterop(completer.completeError));

      request.send();

      await completer.future;

      final Uint8List bytes = (request.response as ByteBuffer).asUint8List();

      if (bytes.lengthInBytes == 0) {
        ImageLoaderCacheManager().deleteCache(key.source, key.config);
        throw NetworkImageLoadException(
            statusCode: request.status!, uri: resolved);
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
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is ImageLoaderNetworkImage
        && other.url == url
        && other.scale == scale;
  }

  @override
  int get hashCode => Object.hash(url, scale);

  @override
  String toString() => '${objectRuntimeType(this, 'ImageLoaderNetworkImage')}("$url", scale: $scale)';


}