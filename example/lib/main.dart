import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_loader/flutter_image_loader.dart';

void main() {

  // 全局配置,一般放在引擎初始化位置
  ImageLoaderConfig()
    // 自定义转换器
    ..transformer = ImageLoaderTransformer((source) {
      if (source is MusicCover) {
        return LoadableSource(source.file, "MusicCover");
      }
      return ImageLoaderTransformer.defaultApply(source);
    })
    // 自定义适配器
    ..customAdapters["MusicCover"] = SimpleImageAdapter(
        loadAsync: (source, config) async {
          return File(source.uri).readAsBytes();
        }
    )
    // 设置缓存
    ..getDefaultCacheKey = (source, config) {
      String key = source.uri;
      return md5.convert(const Utf8Encoder().convert(key)).toString();
    }
    // 开启本地缓存
    ..diskCache = ImageLoaderDiskCache("D:/")
    ..memoryCache = ImageLoaderMemoryCache()
    // 打日志
    ..logger = debugPrint;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter图片加载器',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: '图片加载测试'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}


class _MyHomePageState extends State<MyHomePage> {

  int i = 0;

  @override
  void initState() {
    super.initState();

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          TextButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) {
                return _buildMultiLoadFailed(context);
              }));
            },
            child: const Text("测试多次加载失败图情况"),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                i++;
              });
            },
            child: const Text("刷新"),
          ),
          _buildAssetImage(),
          _buildFileImage(),
          _buildNetworkImage(),
          _buildCustomImage(),
        ],
      ),
    );
  }

  Material _buildMultiLoadFailed(BuildContext context) {
    return Material(
      child: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 100,
              child: ImageLoaderWidget(
                "/sdcard/3.jpg",
                errorBuilder: () => const Text("已回调加载失败"),
              ),
            ),
            const Text("如果上面多次进入后显示一片空白则为错误"),
            TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text("后退"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssetImage() {
    return const ImageLoaderWidget(
        "assets/test.png",
    );
  }

  Widget _buildFileImage() {
    return ImageLoaderWidget(
        "D:/1.jpg",
        errorBuilder: ()=> const Text("error"),
    );
  }

  Widget _buildNetworkImage() {
    return ImageLoaderWidget(
        "https://gimg2.baidu.com/image_search/src=http%3A%2F%2Fc-ssl.duitang.com%2Fuploads%2Fitem%2F202004%2F03%2F20200403044930_Wc8jP.thumb.1000_0.gif&refer=http%3A%2F%2Fc-ssl.duitang.com&app=2002&size=f9999,10000&q=a80&n=0&g=0n&fmt=auto?sec=1664673249&t=07bf853bfde4d87ccf7f3601865c6aa3&a=$i",
        width: 100,
        height: 100,
        // key: ObjectKey("123"),
        // cacheKey: "123",
        placeholderBuilder: ()=> const Text("loading"),
        errorBuilder: ()=> const Text("error"),
        fit: BoxFit.fill,
        listener: ImageLoaderListener(
          onError: (o, s){
            debugPrint("onError $o");
          },
          onLoadCompleted: (){
            debugPrint("onLoadCompleted");
          },
        )
    );
  }

  Widget _buildCustomImage() {
    return ImageLoaderWidget(
        MusicCover(
          "D:/1.png",
        ),
        width: 100,
        height: 100,
        placeholder: "assets/test.png",
        error: "assets/test.png",
        fit: BoxFit.fill,
        listener: ImageLoaderListener(
          onError: (o, s) {
            debugPrint("onError $o");
          },
          onLoadCompleted: () {
            debugPrint("onLoadCompleted");
          },
        ));
  }

}



/// 自定义适配示例: 音乐封面对象
class MusicCover {

  String file;

  MusicCover(this.file);

}
