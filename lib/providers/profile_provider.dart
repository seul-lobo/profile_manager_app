import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/document_model.dart';
import '../models/profile.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';

class ProfileProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();

  Profile? _profile;
  List<DocumentModel> _documents = [];
  bool _isLoading = false;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _error;

  Profile? get profile => _profile;
  List<DocumentModel> get documents => _documents;
  bool get isLoading => _isLoading;
  bool get isUploading => _isUploading;
  double get uploadProgress => _uploadProgress;
  String? get error => _error;

  //clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  //set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  //set uploading state
  void _setUploading(bool uploading) {
    _isUploading = uploading;
    if (!uploading) {
      _uploadProgress = 0.0;
    }
    notifyListeners();
  }

  //set upload progress
  void _setUploadProgress(double progress) {
    _uploadProgress = progress;
    notifyListeners();
  }

  //set error
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  //load user profile
  Future<void> loadUserProfile(String userId) async {
  try {
    Future.microtask(() => clearError()); // <--- wrapped safely
    _setLoading(true);

    final Profile? profile = await _firestoreService.getUserProfile(userId);
    _profile = profile;

    await loadUserDocuments(userId);

    _setLoading(false);
  } catch (e) {
    _setLoading(false);
    _setError(e.toString());
  }
}

  //load user documents
  Future<void> loadUserDocuments(String userId) async {
    try {
      final documents = await _firestoreService.getUserDocuments(userId);
      _documents = documents;
      notifyListeners();
    } catch (e) {
      print('Error loading documents: $e');
    }
  }

  //create or update profile
  Future<bool> saveProfile({
    required String userId,
    required String name,
    required String email,
    required int age,
    String? phoneNumber,
  }) async {
    try {
      clearError();
      _setLoading(true);

      final Profile newProfile = Profile(
        id: userId,
        name: name,
        email: email,
        age: age,
        phoneNumber: phoneNumber,
        photoURL: _profile?.photoURL,
        docURL: _profile?.docURL, //keep for backward compatibility
        createdAt: _profile?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestoreService.saveUserProfile(userId, newProfile);
      _profile = newProfile;

      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError(e.toString());
      return false;
    }
  }

  //update profile with new data
  Future<bool> updateProfile({
    required String userId,
    String? name,
    String? email,
    int? age,
    String? phoneNumber,
    String? photoURL,
    String? docURL,
  }) async {
    try {
      clearError();
      _setLoading(true);

      final Profile updatedProfile = _profile?.copyWith(
            name: name ?? _profile?.name,
            email: email ?? _profile?.email,
            age: age ?? _profile?.age,
            phoneNumber: phoneNumber ?? _profile?.phoneNumber,
            photoURL: photoURL ?? _profile?.photoURL,
            docURL: docURL ?? _profile?.docURL,
            updatedAt: DateTime.now(),
          ) ??
          Profile(
            id: userId,
            name: name ?? '',
            email: email ?? '',
            age: age ?? 0,
            phoneNumber: phoneNumber,
            photoURL: photoURL,
            docURL: docURL,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

      await _firestoreService.saveUserProfile(userId, updatedProfile);
      _profile = updatedProfile;

      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError(e.toString());
      return false;
    }
  }

  //upload profile image
  Future<bool> uploadProfileImage({
    required String userId,
    required File imageFile,
  }) async {
    try {
      clearError();
      _setUploading(true);

      //delete old image if exists
      if (_profile?.photoURL != null) {
        try {
          await _storageService.deleteFileByURL(_profile!.photoURL!);
        } catch (e) {
          print('Error deleting old image: $e');
        }
      }

      final String downloadURL = await _storageService.uploadProfileImage(
        userId: userId,
        imageFile: imageFile,
        onProgress: _setUploadProgress,
      );

      //update profile with new photo URL
      final bool success = await updateProfile(
        userId: userId,
        photoURL: downloadURL,
      );

      _setUploading(false);
      return success;
    } catch (e) {
      _setUploading(false);
      _setError(e.toString());
      return false;
    }
  }

  //upload single document (backward compatibility)
  Future<bool> uploadDocument({
    required String userId,
    required File documentFile,
    required String fileName,
  }) async {
    return await uploadMultipleDocuments(
      userId: userId,
      documentFiles: [documentFile],
      fileNames: [fileName],
    );
  }

  //upload multiple documents
  Future<bool> uploadMultipleDocuments({
    required String userId,
    required List<File> documentFiles,
    required List<String> fileNames,
  }) async {
    try {
      clearError();
      _setUploading(true);

      for (int i = 0; i < documentFiles.length; i++) {
        final File documentFile = documentFiles[i];
        final String fileName = fileNames[i];

        _setUploadProgress((i / documentFiles.length) * 0.8); //80% for upload

        final String downloadURL = await _storageService.uploadDocument(
          userId: userId,
          documentFile: documentFile,
          fileName: fileName,
          onProgress: (progress) {
            _setUploadProgress(((i + progress) / documentFiles.length) * 0.8);
          },
        );

        //save document info to Firestore
        final DocumentModel document = DocumentModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: userId,
          name: fileName,
          url: downloadURL,
          type: _getDocumentType(fileName),
          size: documentFile.lengthSync(),
          uploadedAt: DateTime.now(),
        );

        await _firestoreService.saveDocument(document);

        //update first document URL in profile for backward compatibility
        if (i == 0) {
          await updateProfile(userId: userId, docURL: downloadURL);
        }
      }

      _setUploadProgress(0.9); //90% complete
      await loadUserDocuments(userId); //reload documents
      _setUploadProgress(1.0); //100% complete

      _setUploading(false);
      return true;
    } catch (e) {
      _setUploading(false);
      _setError(e.toString());
      return false;
    }
  }

  //delete document
  Future<bool> deleteDocument(String documentId, String documentUrl) async {
    try {
      clearError();
      _setLoading(true);

      //delete from storage
      await _storageService.deleteFileByURL(documentUrl);

      //delete from Firestore
      await _firestoreService.deleteDocument(documentId);

      //remove from local list
      _documents.removeWhere((doc) => doc.id == documentId);

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setLoading(false);
      _setError(e.toString());
      return false;
    }
  }

  //get document type from file extension
  String _getDocumentType(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    switch (extension) {
      case 'pdf':
        return 'PDF';
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return 'Image';
      case 'doc':
      case 'docx':
        return 'Word';
      case 'txt':
        return 'Text';
      default:
        return 'Document';
    }
  }

  //check if file is valid image
  bool isValidImageFile(File file, String fileName) {
    return _storageService.isValidImageFile(file, fileName);
  }

  //check if file is valid document
  bool isValidDocumentFile(File file, String fileName) {
    return _storageService.isValidDocumentFile(file, fileName);
  }

  //clear profile data
  void clearProfile() {
    _profile = null;
    _documents.clear();
    clearError();
    notifyListeners();
  }

  //get profile completion percentage
  int getProfileCompletionPercentage() {
    if (_profile == null) return 0;

    int completed = 0;
    int total = 5;

    if (_profile!.name.isNotEmpty) completed++;
    if (_profile!.email.isNotEmpty) completed++;
    if (_profile!.age > 0) completed++;
    if (_profile!.photoURL != null) completed++;
    if (_documents.isNotEmpty || _profile!.docURL != null) completed++;

    return ((completed / total) * 100).round();
  }
}
