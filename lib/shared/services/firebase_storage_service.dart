import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as path;
import 'package:vibe_app/shared/services/storage_service.dart';

/// Firebase implementation of [StorageService]
///
/// Handles file uploads to Firebase Storage with image compression
/// and progress tracking.
class FirebaseStorageService implements StorageService {
  final FirebaseStorage _storage;

  FirebaseStorageService({FirebaseStorage? storage})
    : _storage = storage ?? FirebaseStorage.instance;

  @override
  Future<String> uploadFile({
    required String path,
    required File file,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final ref = _storage.ref().child(path);
      final uploadTask = ref.putFile(file);

      // Track upload progress if callback provided
      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        });
      }

      // Wait for upload to complete
      final snapshot = await uploadTask;

      // Get and return download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } on FirebaseException catch (e) {
      throw StorageUploadException('Upload failed: ${e.message}');
    } catch (e) {
      throw StorageUploadException('Unexpected error during upload: $e');
    }
  }

  @override
  Future<void> deleteFile(String path) async {
    try {
      final ref = _storage.ref().child(path);
      await ref.delete();
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') {
        throw StorageNotFoundException('File not found: $path');
      }
      throw StorageException('Delete failed: ${e.message}');
    } catch (e) {
      throw StorageException('Unexpected error during delete: $e');
    }
  }

  @override
  Future<String> getDownloadUrl(String path) async {
    try {
      final ref = _storage.ref().child(path);
      final downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') {
        throw StorageNotFoundException('File not found: $path');
      }
      throw StorageException('Failed to get download URL: ${e.message}');
    } catch (e) {
      throw StorageException('Unexpected error getting download URL: $e');
    }
  }

  @override
  Future<File> compressImage(File image) async {
    try {
      // Get file extension
      final ext = path.extension(image.path).toLowerCase();

      // Validate image format
      if (!['.jpg', '.jpeg', '.png', '.heic'].contains(ext)) {
        throw const StorageException('Unsupported image format');
      }

      // Create output path in temp directory
      final outputPath = path.join(
        Directory.systemTemp.path,
        '${DateTime.now().millisecondsSinceEpoch}_compressed$ext',
      );

      // Compress image: max 1024x1024, 85% quality
      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        image.absolute.path,
        outputPath,
        minWidth: 1024,
        minHeight: 1024,
        quality: 85,
      );

      if (compressedFile == null) {
        throw const StorageException('Image compression failed');
      }

      return File(compressedFile.path);
    } catch (e) {
      if (e is StorageException) {
        rethrow;
      }
      throw StorageException('Image compression error: $e');
    }
  }
}
