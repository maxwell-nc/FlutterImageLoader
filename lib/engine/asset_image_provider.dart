import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:ui' as ui show Codec, ImmutableBuffer;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_image_loader/core/image_loader_widget.dart';
import 'package:flutter_image_loader/engine/completer/multi_frame_image_stream_completer_safe.dart';


const String _kAssetManifestFileName = 'AssetManifest.json';

const double _kLowDprLimit = 2.0;


/// 参考[AssetImage]改写的资源图片加载器
/// 修正部分崩溃问题
/// 增加监听能力
class ImageLoaderAssetImage extends ImageProvider<AssetBundleImageKey> {

  // 默认缩放倍率
  static const double _naturalResolution = 1.0;

  static final RegExp _extractRatioRegExp = RegExp(r'/?(\d+(\.\d*)?)x$');

  /// 资源名称
  final String assetName;

  final AssetBundle? bundle;

  final String? package;

  final ImageLoaderListener? listener;

  String get keyName => package == null ? assetName : 'packages/$package/$assetName';

  const ImageLoaderAssetImage(
    this.assetName, {
    this.bundle,
    this.package,
    this.listener,
  });


  @override
  Future<AssetBundleImageKey> obtainKey(ImageConfiguration configuration) {
    final AssetBundle chosenBundle = bundle ?? configuration.bundle ?? rootBundle;
    Completer<AssetBundleImageKey>? completer;
    Future<AssetBundleImageKey>? result;

    chosenBundle.loadStructuredData<Map<String, List<String>>?>(_kAssetManifestFileName, _manifestParser)
        .then<void>((Map<String, List<String>>? manifest) {
        final String chosenName = _chooseVariant(
          keyName,
          configuration,
          manifest == null ? null : manifest[keyName],
        )!;
        final double chosenScale = _parseScale(chosenName);
        final AssetBundleImageKey key = AssetBundleImageKey(
          bundle: chosenBundle,
          name: chosenName,
          scale: chosenScale,
        );
        if (completer != null) {
          completer.complete(key);
        } else {
          result = SynchronousFuture<AssetBundleImageKey>(key);
        }
      },
    ).catchError((Object error, StackTrace stack) {
      assert(completer != null);
      assert(result == null);
      completer!.completeError(error, stack);
    });
    if (result != null) {
      return result!;
    }
    completer = Completer<AssetBundleImageKey>();
    return completer.future;
  }

  static Future<Map<String, List<String>>?> _manifestParser(String? jsonData) {
    if (jsonData == null) {
      return SynchronousFuture<Map<String, List<String>>?>(null);
    }
    // 此处解码应该考虑UI卡死问题
    final Map<String, dynamic> parsedJson = json.decode(jsonData) as Map<String, dynamic>;
    final Iterable<String> keys = parsedJson.keys;
    final Map<String, List<String>> parsedManifest = <String, List<String>> {
      for (final String key in keys) key: List<String>.from(parsedJson[key] as List<dynamic>),
    };
    // 考虑类型转换问题
    return SynchronousFuture<Map<String, List<String>>?>(parsedManifest);
  }

  String? _chooseVariant(String main, ImageConfiguration config, List<String>? candidates) {
    if (config.devicePixelRatio == null || candidates == null || candidates.isEmpty) {
      return main;
    }
    final SplayTreeMap<double, String> mapping = SplayTreeMap<double, String>();
    for (final String candidate in candidates) {
      mapping[_parseScale(candidate)] = candidate;
    }
    // 后续支持 config.locale, config.textDirection,
    return _findBestVariant(mapping, config.devicePixelRatio!);
  }

  String? _findBestVariant(SplayTreeMap<double, String> candidates, double value) {
    if (candidates.containsKey(value)) {
      return candidates[value]!;
    }
    final double? lower = candidates.lastKeyBefore(value);
    final double? upper = candidates.firstKeyAfter(value);
    if (lower == null) {
      return candidates[upper];
    }
    if (upper == null) {
      return candidates[lower];
    }

    if (value < _kLowDprLimit || value > (lower + upper) / 2) {
      return candidates[upper];
    } else {
      return candidates[lower];
    }
  }

  /// 处理资源倍率（2x 3x）之类的
  double _parseScale(String key) {
    if (key == assetName) {
      return _naturalResolution;
    }

    final Uri assetUri = Uri.parse(key);
    String directoryPath = '';
    if (assetUri.pathSegments.length > 1) {
      directoryPath = assetUri.pathSegments[assetUri.pathSegments.length - 2];
    }

    final Match? match = _extractRatioRegExp.firstMatch(directoryPath);
    if (match != null && match.groupCount > 0) {
      return double.parse(match.group(1)!);
    }
    return _naturalResolution;
  }


  @override
  // ignore: deprecated_member_use
  ImageStreamCompleter load(AssetBundleImageKey key, DecoderCallback decode) {
    InformationCollector? collector;

    assert(() {
      collector = () => <DiagnosticsNode>[
            DiagnosticsProperty<ImageProvider>('Image provider', this),
            DiagnosticsProperty<AssetBundleImageKey>('Image key', key),
          ];
      return true;
    }());

    return MultiFrameImageStreamCompleterSafe(
      codec: _loadAsync(key, null, decode),
      scale: key.scale,
      debugLabel: key.name,
      informationCollector: collector,
      listener: listener,
    );
  }


  /// Flutter 3.3+ API
  @override
  ImageStreamCompleter loadBuffer(AssetBundleImageKey key, DecoderBufferCallback decode) {
    InformationCollector? collector;

    assert(() {
      collector = () => <DiagnosticsNode>[
        DiagnosticsProperty<ImageProvider>('Image provider', this),
        DiagnosticsProperty<AssetBundleImageKey>('Image key', key),
      ];
      return true;
    }());

    return MultiFrameImageStreamCompleterSafe(
      codec: _loadAsync(key, decode, null),
      scale: key.scale,
      debugLabel: key.name,
      informationCollector: collector,
      listener: listener,
    );
  }


  @protected
  // ignore: deprecated_member_use
  Future<ui.Codec> _loadAsync(AssetBundleImageKey key, DecoderBufferCallback? decode, DecoderCallback? decodeDeprecated) async {
    if (decode != null) {
      ui.ImmutableBuffer? buffer;

      try {
        buffer = await key.bundle.loadBuffer(key.name);
      } on FlutterError {
        PaintingBinding.instance.imageCache.evict(key);
        rethrow;
      }

      // if (buffer == null) {
      //   PaintingBinding.instance.imageCache.evict(key);
      //   throw StateError('Unable to read data');
      // }

      return decode(buffer);
    }

    ByteData? data;

    try {
      data = await key.bundle.load(key.name);
    } on FlutterError {
      PaintingBinding.instance.imageCache.evict(key);
      rethrow;
    }

    // if (data == null) {
    //   PaintingBinding.instance.imageCache.evict(key);
    //   throw StateError('Unable to read data');
    // }
    return decodeDeprecated!(data.buffer.asUint8List());
  }


  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is AssetImage
        && other.keyName == keyName
        && other.bundle == bundle;
  }

  @override
  int get hashCode => Object.hash(keyName, bundle);

  @override
  String toString() => '${objectRuntimeType(this, 'ImageLoaderAssetImage')}(bundle: $bundle, name: "$keyName")';

}
