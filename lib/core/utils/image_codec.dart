import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Firebase Storage（Blazeプラン必須）を使わずに済むよう、画像をリサイズ・圧縮して
/// Firestoreドキュメントに直接埋め込めるdata URI文字列に変換するユーティリティ。
class ImageCodec {
  static const int _maxDimension = 720;
  static const int _targetBytes = 150 * 1024;

  /// 画像ファイルを縮小・JPEG圧縮し、`data:image/jpeg;base64,...` 形式の文字列を返す。
  static Future<String> encodeToDataUri(File file) async {
    final bytes = await file.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw const FormatException('画像を読み込めませんでした');
    }

    var resized = decoded;
    if (decoded.width > _maxDimension || decoded.height > _maxDimension) {
      resized = decoded.width >= decoded.height
          ? img.copyResize(decoded, width: _maxDimension)
          : img.copyResize(decoded, height: _maxDimension);
    }

    var quality = 80;
    List<int> encoded = img.encodeJpg(resized, quality: quality);
    while (encoded.length > _targetBytes && quality > 30) {
      quality -= 10;
      encoded = img.encodeJpg(resized, quality: quality);
    }

    return 'data:image/jpeg;base64,${base64Encode(encoded)}';
  }

  static bool isDataUri(String value) => value.startsWith('data:');

  static Uint8List decodeDataUri(String dataUri) {
    final base64Part = dataUri.substring(dataUri.indexOf(',') + 1);
    return base64Decode(base64Part);
  }
}
