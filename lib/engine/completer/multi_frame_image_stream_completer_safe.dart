import 'dart:async';
import 'dart:ui' as ui show Codec;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_image_loader/core/image_loader_config.dart';
import 'package:flutter_image_loader/core/image_loader_widget.dart';

/// 保护图片加载失败时app不崩溃
class MultiFrameImageStreamCompleterSafe extends MultiFrameImageStreamCompleter {

  final ImageLoaderListener? listener;

  /// 当前错误信息
  /// 图片加载第一次后,Completer会进入缓存
  /// 在addListener处要判断是否错误,错误的时候要告诉监听器
  /// 否则第二次加载的时候,将不执行任何操作,导致RawImage的image为null而空白
  FlutterErrorDetails? _currentError;

  final List<ImageStreamListener> _errorListener = <ImageStreamListener>[];

  MultiFrameImageStreamCompleterSafe({
    required Future<ui.Codec> codec,
    required double scale,
    String? debugLabel,
    Stream<ImageChunkEvent>? chunkEvents,
    InformationCollector? informationCollector,
    this.listener,
  }) : super(codec: codec,
      scale: scale,
      debugLabel: debugLabel,
      chunkEvents: chunkEvents,
      informationCollector: informationCollector) {

    ImageStreamListener? callListener;
    callListener = ImageStreamListener(
      (ImageInfo? image, bool sync) {
        // 加载完成
        listener?.onLoadCompleted?.call();

        SchedulerBinding.instance.addPostFrameCallback((Duration timeStamp) {
          removeListener(callListener!);
        });
      },
      onError: (Object exception, StackTrace? stackTrace) {
        // 错误
        listener?.onError?.call(exception, stackTrace);

        SchedulerBinding.instance.addPostFrameCallback((Duration timeStamp) {
          removeListener(callListener!);
        });
      },
    );

    addListener(callListener);
  }


  @override
  void addListener(ImageStreamListener listener) {
    if (listener.onError != null) {
      _errorListener.add(listener);

      // 之前的错误通知新监听的
      if (_currentError != null) {
        _callListenerOnError(listener, _currentError!.exception, _currentError!.stack);
      }
    }
    super.addListener(listener);
  }

  @override
  void removeListener(ImageStreamListener listener) {
    _errorListener.remove(listener);
    super.removeListener(listener);
  }


  @override
  void reportError({
    DiagnosticsNode? context,
    required Object exception,
    StackTrace? stack,
    InformationCollector? informationCollector,
    bool silent = false,
  }) {
    _currentError = FlutterErrorDetails(
      exception: exception,
      stack: stack,
      library: 'image resource service',
      context: context,
      informationCollector: informationCollector,
      silent: silent,
    );

    if (_errorListener.isNotEmpty) {
      var iterator = _errorListener.iterator;
      while (iterator.moveNext()) {
        // 防止错误处理出错
        _callListenerOnError(iterator.current, exception, stack);
      }
      return;
    }

    // 下面为某些情况，
    // 例如先加载一个错误网络图片，立刻加载另一张错误本地图片，导致不存在错误监听器，异常没有处理
    _debugPrint("MultiFrameImageStreamCompleterSafe error inside, no listener ignore");

  }

  /// 通知监听器发生错误
  void _callListenerOnError(ImageStreamListener? listener, Object exception, StackTrace? stack) {
    try {
      listener?.onError?.call(exception, stack);
    } catch (newException) {
      // 排查是否同一个异常
      if (newException != exception) {
        _debugPrint("MultiFrameImageStreamCompleterSafe error inside listener new diff error");
      }
    }
  }

  /// 输出日志
  void _debugPrint(String log) {
    ImageLoaderConfig().logger?.call(log);
  }

}