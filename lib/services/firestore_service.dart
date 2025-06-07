import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:travel_guide/models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // User Collection Reference
  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  // Get stream of itineraries
  Stream<List<Map<String, dynamic>>> getItineraries() {
    return _firestore.collection('itineraries').snapshots().asyncMap((snapshot) async {
      final List<Map<String, dynamic>> itineraries = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final authorRef = data['author'] as DocumentReference;

        // Fetch author details
        final authorDoc = await authorRef.get();
        final authorData = authorDoc.data() as Map<String, dynamic>;
        final authorName = authorData['displayName'] ?? 'Unknown';

        itineraries.add({
          'id': doc.id,
          'title': data['title'] ?? '',
          'author': authorName,
          'description': data['description'] ?? '',
          'location': data['location'] ?? '',
          'startDate': data['startDate'],
          'endDate': data['endDate'],
          'tags': data['tags'] ?? [],
          'places': data['places'] ?? [],
          'status': data['status'] ?? 'planned',
          'createdAt': data['createdAt'],
          'updatedAt': data['updatedAt'],
        });
      }
      return itineraries;
    });
  }

  // Create or Update User
  Future<void> createOrUpdateUser(auth.User user, {Map<String, dynamic>? additionalData}) async {
    final userData = {
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName,
      'photoURL': user.photoURL,
      'lastSignIn': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
      ...?additionalData,
    };

    await _usersCollection.doc(user.uid).set(userData, SetOptions(merge: true));
  }

  // Get User Data
  Future<UserModel?> getUser(String uid) async {
    final docSnapshot = await _usersCollection.doc(uid).get();
    if (!docSnapshot.exists) return null;

    return UserModel.fromFirestore(
      docSnapshot.data() as Map<String, dynamic>,
      docSnapshot.id,
    );
  }

  // Update User Profile
  Future<void> updateUserProfile(String uid, {
    String? displayName,
    String? localPhotoPath,
    Map<String, dynamic>? preferences,
  }) async {
    final updates = <String, dynamic>{
      if (displayName != null) 'displayName': displayName,
      if (localPhotoPath != null) 'localPhotoPath': localPhotoPath,
      if (preferences != null) 'preferences': preferences,
      'lastUpdated': FieldValue.serverTimestamp(),
    };

    await _usersCollection.doc(uid).update(updates);
  }

  // Get User's Saved Places
  Stream<List<Map<String, dynamic>>> getUserSavedPlaces(String uid) {
    return _usersCollection
        .doc(uid)
        .collection('savedPlaces')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => {
      'id': doc.id,
      ...doc.data(),
    })
        .toList());
  }

  // Save a Place for User
  Future<void> savePlace(String uid, Map<String, dynamic> placeData) async {
    await _usersCollection
        .doc(uid)
        .collection('savedPlaces')
        .add({
      ...placeData,
      'savedAt': FieldValue.serverTimestamp(),
    });
  }

  // Remove Saved Place
  Future<void> removeSavedPlace(String uid, String placeId) async {
    await _usersCollection
        .doc(uid)
        .collection('savedPlaces')
        .doc(placeId)
        .delete();
  }

  // Get User's Travel History
  Stream<List<Map<String, dynamic>>> getUserTravelHistory(String uid) {
    return _usersCollection
        .doc(uid)
        .collection('travelHistory')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => {
      'id': doc.id,
      ...doc.data(),
    })
        .toList());
  }

  // Add Travel History
  Future<void> addTravelHistory(String uid, Map<String, dynamic> travelData) async {
    await _usersCollection
        .doc(uid)
        .collection('travelHistory')
        .add({
      ...travelData,
      'addedAt': FieldValue.serverTimestamp(),
    });
  }

  // Delete User Account and Related Data
  Future<void> deleteUserAccount(String uid) async {
    // Delete user document and all sub-collections
    await _usersCollection.doc(uid).delete();
  }

  // Update User Last Sign In
  Future<void> updateLastSignIn(String uid) async {
    await _usersCollection.doc(uid).update({
      'lastSignIn': FieldValue.serverTimestamp(),
    });
  }

  Future<void> savePlaceForUser(String userId, Map<String, dynamic> place) async {
    final userPlacesRef = _firestore.collection('users').doc(userId).collection('saved_places');
    await userPlacesRef.doc(place['name']).set(place);
  }

  Future<List<Map<String, dynamic>>> getSavedPlacesForUser(String userId) async {
    final userPlacesRef = _firestore.collection('users').doc(userId).collection('saved_places');
    final snapshot = await userPlacesRef.get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<void> removeSavedPlaceForUser(String userId, String placeName) async {
    final userPlacesRef = _firestore.collection('users').doc(userId).collection('saved_places');
    await userPlacesRef.doc(placeName).delete();
  }
}