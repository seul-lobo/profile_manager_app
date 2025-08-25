import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _init();
  }

  void _init() {
    //listen to auth state changes
    _authService.authStateChanges.listen((User? user) {
      final bool wasAuthenticated = _user != null;
      _user = user;

      //only notify if authentication state actually changed
      if (wasAuthenticated != (_user != null)) {
        notifyListeners();
      }
    });
  }

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

  //set error
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  //sign up
  Future<bool> signUp({
    required String email,
    required String password,
  }) async {
    try {
      clearError();
      _setLoading(true);

      final UserCredential? result =
          await _authService.signUpWithEmailAndPassword(
        email: email,
        password: password,
      );

      _setLoading(false);
      return result != null;
    } catch (e) {
      _setLoading(false);
      _setError(e.toString());
      return false;
    }
  }

  //sign in
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      clearError();
      _setLoading(true);

      final UserCredential? result =
          await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      _setLoading(false);
      return result != null;
    } catch (e) {
      _setLoading(false);
      _setError(e.toString());
      return false;
    }
  }

  //reset password
  Future<void> resetPassword(String email) async {
    try {
      clearError();
      _setLoading(true);

      await _authService.resetPassword(email);

      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      _setError(e.toString());
      rethrow;
    }
  }

  //sign out
  Future<void> signOut() async {
    try {
      clearError();
      _setLoading(true);

      await _authService.signOut();
      _user = null;

      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      _setError(e.toString());
    }
  }

  //get current user ID
  String? get currentUserId => _user?.uid;

  //get current user email
  String? get currentUserEmail => _user?.email;

  //check if user email is verified
  bool get isEmailVerified => _user?.emailVerified ?? false;

  //send email verification
  Future<bool> sendEmailVerification() async {
    try {
      clearError();

      if (_user == null) {
        throw 'No user signed in';
      }

      await _user!.sendEmailVerification();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  //reload user
  Future<void> reloadUser() async {
    try {
      if (_user != null) {
        await _user!.reload();
        _user = _authService.currentUser;
        notifyListeners();
      }
    } catch (e) {
      print('Error reloading user: $e');
    }
  }

  //update user profile
  Future<bool> updateUserProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      clearError();

      if (_user == null) {
        throw 'No user signed in';
      }

      await _user!.updateDisplayName(displayName);
      await _user!.updatePhotoURL(photoURL);
      await _user!.reload();

      _user = _authService.currentUser;
      notifyListeners();

      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  //delete user account
  Future<bool> deleteAccount() async {
    try {
      clearError();
      _setLoading(true);

      if (_user == null) {
        throw 'No user signed in';
      }

      await _user!.delete();
      _user = null;

      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError(e.toString());
      return false;
    }
  }
}
