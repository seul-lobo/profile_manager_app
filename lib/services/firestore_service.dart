import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/profile.dart';
import '../utils/constants.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  //get user profile
  Future<Profile?> getUserProfile(String userId) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection(Constants.usersCollection)
          .doc(userId)
          .get();

      if (doc.exists && doc.data() != null) {
        return Profile.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }
      return null;
    } catch (e) {
      throw 'Failed to load profile: ${e.toString()}';
    }
  }

  //create or update user profile
  Future<void> saveUserProfile(String userId, Profile profile) async {
    try {
      await _firestore
          .collection(Constants.usersCollection)
          .doc(userId)
          .set(profile.toMap(), SetOptions(merge: true));
    } catch (e) {
      throw 'Failed to save profile: ${e.toString()}';
    }
  }

  //update profile field
  Future<void> updateProfileField(
    String userId,
    String field,
    dynamic value,
  ) async {
    try {
      await _firestore
          .collection(Constants.usersCollection)
          .doc(userId)
          .update({field: value});
    } catch (e) {
      throw 'Failed to update profile: ${e.toString()}';
    }
  }

  //delete user profile
  Future<void> deleteUserProfile(String userId) async {
    try {
      await _firestore
          .collection(Constants.usersCollection)
          .doc(userId)
          .delete();
    } catch (e) {
      throw 'Failed to delete profile: ${e.toString()}';
    }
  }

  //check if profile exists
  Future<bool> profileExists(String userId) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection(Constants.usersCollection)
          .doc(userId)
          .get();
      return doc.exists;
    } catch (e) {
      throw 'Failed to check profile existence: ${e.toString()}';
    }
  }

  //get profile stream for real-time updates
  Stream<Profile?> getUserProfileStream(String userId) {
    return _firestore
        .collection(Constants.usersCollection)
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (doc.exists && doc.data() != null) {
        return Profile.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }
      return null;
    });
  }
}
