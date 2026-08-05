import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/utils/image_codec.dart';

/// ローカルでBase64エンコードされたdata URIと、従来のネットワークURLの
/// どちらも表示できる画像ウィジェット。
class AppImage extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;

  const AppImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  ImageProvider toImageProvider() {
    return ImageCodec.isDataUri(url)
        ? MemoryImage(ImageCodec.decodeDataUri(url))
        : CachedNetworkImageProvider(url);
  }

  @override
  Widget build(BuildContext context) {
    if (ImageCodec.isDataUri(url)) {
      return Image.memory(
        ImageCodec.decodeDataUri(url),
        width: width,
        height: height,
        fit: fit,
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
    );
  }
}
