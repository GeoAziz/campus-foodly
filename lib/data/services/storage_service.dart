import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:logger/logger.dart';

import 'firebase_service.dart';

final _logger = Logger();

/// Exception for storage service errors
class StorageException implements Exception {
  StorageException(this.message);
  final String message;

  @override
  String toString() => message;
}

class StorageService {
  StorageService._(this._storage);

  final FirebaseStorage _storage;

  static StorageService? _instance;

  static StorageService get instance {
    if (!FirebaseService.isInitialized) {
      throw StorageException('Firebase is not initialized for storage.');
    }
    return _instance ??= StorageService._(FirebaseStorage.instance);
  }

  /// Upload file with optional progress callback
  Future<String> uploadFile({
    required File file,
    required String destinationPath,
    void Function(double progress)? onProgress,
    int maxRetries = 3,
  }) async {
    int attempts = 0;

    while (attempts < maxRetries) {
      try {
        if (!await file.exists()) {
          throw StorageException('File does not exist: ${file.path}');
        }

        final ref = _storage.ref(destinationPath);
        final uploadTask = ref.putFile(file);

        if (onProgress != null) {
          uploadTask.snapshotEvents.listen(
            (TaskSnapshot snapshot) {
              final progress =
                  snapshot.bytesTransferred / snapshot.totalBytes;
              onProgress(progress);
            },
            onError: (error) {
              _logger.e('Upload progress error: $error');
            },
          );
        }

        final task = await uploadTask;
        final downloadUrl = await task.ref.getDownloadURL();
        _logger.i('File uploaded successfully: $destinationPath');
        return downloadUrl;
      } catch (e) {
        attempts++;
        _logger.e('Upload attempt $attempts failed: $e');

        if (attempts >= maxRetries) {
          throw StorageException(
            'Failed to upload file after $maxRetries attempts: $e',
          );
        }

        // Wait before retry
        await Future.delayed(Duration(seconds: attempts));
      }
    }

    throw StorageException('Upload failed after max retries');
  }

  /// Resolve download URL with error handling
  Future<String> resolveDownloadUrl(String pathOrUrl) async {
    try {
      if (pathOrUrl.isEmpty) {
        return pathOrUrl;
      }

      final normalized = pathOrUrl.trim();
      if (normalized.startsWith('http://') ||
          normalized.startsWith('https://')) {
        return normalized;
      }

      if (normalized.startsWith('gs://')) {
        final ref = _storage.refFromURL(normalized);
        final url = await ref.getDownloadURL();
        return url;
      }

      final ref = _storage.ref(normalized);
      final url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      _logger.e('Error resolving download URL: $e');
      // Return original path if resolution fails
      return pathOrUrl;
    }
  }

  /// Delete file with error handling
  Future<void> deleteFile(String path) async {
    try {
      await _storage.ref(path).delete();
      _logger.i('File deleted: $path');
    } catch (e) {
      _logger.e('Error deleting file: $e');
      throw StorageException('Failed to delete file: $e');
    }
  }
}
