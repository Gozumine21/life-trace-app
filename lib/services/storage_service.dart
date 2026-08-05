import 'dart:io';

import '../core/utils/image_codec.dart';

/// 画像はFirebase Storage（Blazeプラン必須）を使わず、リサイズ・圧縮した上で
/// data URIとしてFirestoreドキュメントに直接埋め込む。無料のSparkプランのみで動作する。
class StorageService {
  Future<String> uploadUserIcon(String uid, File file) {
    return ImageCodec.encodeToDataUri(file);
  }

  Future<String> uploadLifeEventImage(
    String authorId,
    String eventId,
    File file,
  ) {
    return ImageCodec.encodeToDataUri(file);
  }

  Future<List<String>> uploadLifeEventImages(
    String authorId,
    String eventId,
    List<File> files,
  ) async {
    final urls = <String>[];
    for (final file in files) {
      urls.add(await uploadLifeEventImage(authorId, eventId, file));
    }
    return urls;
  }
}
