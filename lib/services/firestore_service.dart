import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/profile.dart';
import '../models/document_model.dart';
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
          .update({
        field: value,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      throw 'Failed to update profile: ${e.toString()}';
    }
  }

  //delete user profile
  Future<void> deleteUserProfile(String userId) async {
    try {
      //delete all user documents first
      final documentsSnapshot = await _firestore
          .collection(Constants.documentsCollection)
          .where('userId', isEqualTo: userId)
          .get();

      final batch = _firestore.batch();

      for (final doc in documentsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      //delete the profile
      batch.delete(
        _firestore.collection(Constants.usersCollection).doc(userId),
      );

      await batch.commit();
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

  //save document
  Future<void> saveDocument(DocumentModel document) async {
    try {
      await _firestore
          .collection(Constants.documentsCollection)
          .doc(document.id)
          .set(document.toMap());
    } catch (e) {
      throw 'Failed to save document: ${e.toString()}';
    }
  }

  //get user documents
  Future<List<DocumentModel>> getUserDocuments(String userId) async {
    try {
      final QuerySnapshot querySnapshot = await _firestore
          .collection(Constants.documentsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('uploadedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) =>
              DocumentModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Failed to load documents: ${e.toString()}');
      return [];
    }
  }

  //get documents stream for real-time updates
  Stream<List<DocumentModel>> getUserDocumentsStream(String userId) {
    return _firestore
        .collection(Constants.documentsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => DocumentModel.fromMap(doc.data()))
          .toList();
    });
  }

  //delete document
  Future<void> deleteDocument(String documentId) async {
    try {
      await _firestore
          .collection(Constants.documentsCollection)
          .doc(documentId)
          .delete();
    } catch (e) {
      throw 'Failed to delete document: ${e.toString()}';
    }
  }

  //get document by ID
  Future<DocumentModel?> getDocument(String documentId) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection(Constants.documentsCollection)
          .doc(documentId)
          .get();

      if (doc.exists && doc.data() != null) {
        return DocumentModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw 'Failed to get document: ${e.toString()}';
    }
  }

  //get all profiles (for admin purposes)
  Future<List<Profile>> getAllProfiles() async {
    try {
      final QuerySnapshot querySnapshot =
          await _firestore.collection(Constants.usersCollection).get();

      return querySnapshot.docs
          .map((doc) => Profile.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
    } catch (e) {
      throw 'Failed to load profiles: ${e.toString()}';
    }
  }

  //search profiles by name or email
  Future<List<Profile>> searchProfiles(String query) async {
    try {
      query = query.toLowerCase();

      final QuerySnapshot querySnapshot =
          await _firestore.collection(Constants.usersCollection).get();

      return querySnapshot.docs
          .map((doc) => Profile.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .where((profile) =>
              profile.name.toLowerCase().contains(query) ||
              profile.email.toLowerCase().contains(query))
          .toList();
    } catch (e) {
      throw 'Failed to search profiles: ${e.toString()}';
    }
  }
}
