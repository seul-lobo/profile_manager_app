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
      _user = user;
      notifyListeners();
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
}
