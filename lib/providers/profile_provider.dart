import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/profile.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';

class ProfileProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();

  Profile? _profile;
  bool _isLoading = false;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _error;

  Profile? get profile => _profile;
  bool get isLoading => _isLoading;
  bool get isUploading => _isUploading;
  double get uploadProgress => _uploadProgress;
  String? get error => _error;

  // Clear error
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
      clearError();
      _setLoading(true);

      final Profile? profile = await _firestoreService.getUserProfile(userId);
      _profile = profile;

      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      _setError(e.toString());
    }
  }

  //create or update profile
  Future<bool> saveProfile({
    required String userId,
    required String name,
    required String email,
    required int age,
  }) async {
    try {
      clearError();
      _setLoading(true);

      final Profile newProfile = Profile(
        id: userId,
        name: name,
        email: email,
        age: age,
        photoURL: _profile?.photoURL,
        docURL: _profile?.docURL,
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
            photoURL: photoURL ?? _profile?.photoURL,
            docURL: docURL ?? _profile?.docURL,
          ) ??
          Profile(
            id: userId,
            name: name ?? '',
            email: email ?? '',
            age: age ?? 0,
            photoURL: photoURL,
            docURL: docURL,
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
          //ignore delete errors
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

  //upload document
  Future<bool> uploadDocument({
    required String userId,
    required File documentFile,
    required String fileName,
  }) async {
    try {
      clearError();
      _setUploading(true);

      //delete old document if exists
      if (_profile?.docURL != null) {
        try {
          await _storageService.deleteFileByURL(_profile!.docURL!);
        } catch (e) {
          //ignore delete errors
        }
      }

      final String downloadURL = await _storageService.uploadDocument(
        userId: userId,
        documentFile: documentFile,
        fileName: fileName,
        onProgress: _setUploadProgress,
      );

      //update profile with new document URL
      final bool success = await updateProfile(
        userId: userId,
        docURL: downloadURL,
      );

      _setUploading(false);
      return success;
    } catch (e) {
      _setUploading(false);
      _setError(e.toString());
      return false;
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
    clearError();
    notifyListeners();
  }
}
