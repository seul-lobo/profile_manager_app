import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  //get current user
  User? get currentUser => _auth.currentUser;

  //auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  //sign up with email and password
  Future<UserCredential?> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      //clear any previous auth state
      await _auth.signOut();

      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      //send email verification
      if (result.user != null && !result.user!.emailVerified) {
        await result.user!.sendEmailVerification();
      }

      return result;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      print('Unexpected error in signUp: $e');
      throw 'An unexpected error occurred. Please try again.';
    }
  }

  //sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      print('Unexpected error in signIn: $e');
      throw 'An unexpected error occurred. Please try again.';
    }
  }

  //sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
      throw 'Failed to sign out. Please try again.';
    }
  }

  //reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Failed to send password reset email.';
    }
  }

  //handle Firebase Auth exceptions with field-specific errors
  String _handleAuthException(FirebaseAuthException e) {
    print('FirebaseAuthException: ${e.code} - ${e.message}');

    switch (e.code) {
      case 'user-not-found':
        return 'EMAIL_ERROR:No account found with this email address.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'PASSWORD_ERROR:Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'EMAIL_ERROR:An account already exists with this email address.';
      case 'weak-password':
        return 'PASSWORD_ERROR:The password is too weak. Please choose a stronger password.';
      case 'invalid-email':
        return 'EMAIL_ERROR:Please enter a valid email address.';
      case 'user-disabled':
        return 'EMAIL_ERROR:This user account has been disabled.';
      case 'too-many-requests':
        return 'GENERAL_ERROR:Too many failed attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'GENERAL_ERROR:Email/password accounts are not enabled.';
      case 'network-request-failed':
        return 'GENERAL_ERROR:Network error. Please check your internet connection.';
      case 'configuration-not-found':
        return 'GENERAL_ERROR:Firebase configuration error. Please contact support.';
      default:
        return 'GENERAL_ERROR:${e.message ?? 'An authentication error occurred.'}';
    }
  }
}
