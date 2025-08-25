import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import '../utils/constants.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  //upload profile image
  Future<String> uploadProfileImage({
    required String userId,
    required File imageFile,
    Function(double)? onProgress,
  }) async {
    try {
      final String fileName =
          'profile_${userId}_${DateTime.now().millisecondsSinceEpoch}';
      final Reference ref =
          _storage.ref().child(Constants.profileImagesPath).child(fileName);

      final UploadTask uploadTask = ref.putFile(imageFile);

      //listen to upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        if (onProgress != null) {
          final double progress =
              snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        }
      });

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadURL = await snapshot.ref.getDownloadURL();

      return downloadURL;
    } catch (e) {
      throw 'Failed to upload image: ${e.toString()}';
    }
  }

  //upload document
  Future<String> uploadDocument({
    required String userId,
    required File documentFile,
    required String fileName,
    Function(double)? onProgress,
  }) async {
    try {
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String fullFileName = '${userId}_${timestamp}_$fileName';
      final Reference ref =
          _storage.ref().child(Constants.documentsPath).child(fullFileName);

      final UploadTask uploadTask = ref.putFile(documentFile);

      // Listen to upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        if (onProgress != null) {
          final double progress =
              snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        }
      });

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadURL = await snapshot.ref.getDownloadURL();

      return downloadURL;
    } catch (e) {
      throw 'Failed to upload document: ${e.toString()}';
    }
  }

  //delete file by URL
  Future<void> deleteFileByURL(String downloadURL) async {
    try {
      final Reference ref = _storage.refFromURL(downloadURL);
      await ref.delete();
    } catch (e) {
      throw 'Failed to delete file: ${e.toString()}';
    }
  }

  //get file metadata
  Future<FullMetadata> getFileMetadata(String downloadURL) async {
    try {
      final Reference ref = _storage.refFromURL(downloadURL);
      return await ref.getMetadata();
    } catch (e) {
      throw 'Failed to get file metadata: ${e.toString()}';
    }
  }

  //check if file exists
  Future<bool> fileExists(String downloadURL) async {
    try {
      final Reference ref = _storage.refFromURL(downloadURL);
      await ref.getMetadata();
      return true;
    } catch (e) {
      return false;
    }
  }

  //validate file size
  bool isValidFileSize(File file) {
    return file.lengthSync() <= Constants.maxFileSizeBytes;
  }

  //get file extension
  String getFileExtension(String fileName) {
    return fileName.split('.').last.toLowerCase();
  }

  //validate image file
  bool isValidImageFile(File file, String fileName) {
    final String extension = getFileExtension(fileName);
    return Constants.imageExtensions.contains(extension) &&
        isValidFileSize(file);
  }

  //validate document file
  bool isValidDocumentFile(File file, String fileName) {
    final String extension = getFileExtension(fileName);
    return Constants.documentExtensions.contains(extension) &&
        isValidFileSize(file);
  }
}
