import 'dart:io';

/// Abstract interface for file storage service
///
/// Handles file uploads to Firebase Storage, including image compression
/// and progress tracking.
abstract class StorageService {
  /// Upload file to Firebase Storage
  ///
  /// [path]: Storage path (e.g., 'profile_photos/user123.jpg')
  /// [file]: File to upload
  /// [onProgress]: Optional callback for upload progress (0.0 to 1.0)
  ///
  /// Returns download URL of uploaded file.
  /// Throws [StorageUploadException] on upload failure.
  Future<String> uploadFile({
    required String path,
    required File file,
    void Function(double progress)? onProgress,
  });

  /// Delete file from Firebase Storage
  ///
  /// [path]: Storage path of file to delete
  ///
  /// Throws [StorageNotFoundException] if file doesn't exist.
  Future<void> deleteFile(String path);

  /// Get download URL for stored file
  ///
  /// [path]: Storage path of file
  ///
  /// Returns download URL.
  /// Throws [StorageNotFoundException] if file doesn't exist.
  Future<String> getDownloadUrl(String path);

  /// Compress image before upload
  ///
  /// Resizes image to max 1024x1024 pixels and compresses to 85% quality.
  ///
  /// [image]: Image file to compress
  ///
  /// Returns compressed image file.
  /// Throws [StorageException] on compression failure.
  Future<File> compressImage(File image);
}

/// Base storage exception
class StorageException implements Exception {
  final String message;

  const StorageException(this.message);

  @override
  String toString() => 'StorageException: $message';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StorageException &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => message.hashCode;
}

/// Upload failed
class StorageUploadException extends StorageException {
  const StorageUploadException(super.message);

  @override
  String toString() => 'StorageUploadException: $message';
}

/// File not found in storage
class StorageNotFoundException extends StorageException {
  const StorageNotFoundException(super.message);

  @override
  String toString() => 'StorageNotFoundException: $message';
}
