

class LoadableSource {

  /// 网络图
  static const String typeHttp = "Http";

  /// 资源图
  static const String typeAsset = "Asset";

  /// 本地图
  static const String typeLocal = "Local";

  /// 未知
  static const String typeUnknown = "Unknown";

  /// 加载地址
  final String uri;

  /// 类型，用于拦截器处理
  final String type;

  LoadableSource(this.uri, this.type);

  LoadableSource.http(uri) : this(uri, typeHttp);

  LoadableSource.asset(uri) : this(uri, typeAsset);

  LoadableSource.local(uri) : this(uri, typeLocal);

  LoadableSource.unknown(uri) : this(uri, typeUnknown);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoadableSource &&
          runtimeType == other.runtimeType &&
          uri == other.uri &&
          type == other.type;

  @override
  int get hashCode => uri.hashCode ^ type.hashCode;

  @override
  String toString() {
    return 'LoadableSource{uri: $uri, type: $type}';
  }

}

