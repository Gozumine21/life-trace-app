import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage;

  StorageService(this._storage);

  Future<String> uploadUserIcon(String uid, File file) async {
    final ref = _storage.ref('users/$uid/icon.jpg');
    await ref.putFile(file);
    return ref.getDownloadURL();
  }

  Future<String> uploadLifeEventImage(
    String authorId,
    String eventId,
    File file,
  ) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref(
      'lifeEvents/$authorId/$eventId/$fileName',
    );
    await ref.putFile(file);
    return ref.getDownloadURL();
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
