import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

import 'firebase_service.dart';

class StorageService {
  StorageService._(this._storage);

  final FirebaseStorage _storage;

  static StorageService? _instance;

  static StorageService get instance {
    if (!FirebaseService.isInitialized) {
      throw StateError('Firebase is not initialized for storage.');
    }
    return _instance ??= StorageService._(FirebaseStorage.instance);
  }

  Future<String> uploadFile({
    required File file,
    required String destinationPath,
  }) async {
    final ref = _storage.ref(destinationPath);
    final task = await ref.putFile(file);
    return task.ref.getDownloadURL();
  }

  Future<String> resolveDownloadUrl(String pathOrUrl) async {
    if (pathOrUrl.isEmpty) {
      return pathOrUrl;
    }

    final normalized = pathOrUrl.trim();
    if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
      return normalized;
    }

    try {
      if (normalized.startsWith('gs://')) {
        final ref = _storage.refFromURL(normalized);
        return await ref.getDownloadURL();
      }

      final ref = _storage.ref(normalized);
      return await ref.getDownloadURL();
    } catch (_) {
      return pathOrUrl;
    }
  }
}
