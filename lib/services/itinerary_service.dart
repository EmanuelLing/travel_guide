import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class ItineraryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create new itinerary
  Future<void> createItinerary({
    required String userId,
    required String title,
    required String description,
    required String location,
    required DateTime startDate,
    required DateTime endDate,
    required List<String> tags,
    Map<String, dynamic>? additionalData,
  }) async {
    await _firestore.collection('itineraries').add({
      'author': _firestore.collection('users').doc(userId),
      'title': title,
      'description': description,
      'location': location,
      'startDate': startDate,
      'endDate': endDate,
      'tags': tags,
      'status': 'planned',
      'shareStatus': 'private',
      'places': additionalData?['places'] ?? [],
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Get itinerary by ID
  Future<Map<String, dynamic>?> getItinerary(String itineraryId) async {
    try {
      final doc = await _firestore.collection('itineraries').doc(itineraryId).get();
      if (!doc.exists) return null;

      final data = doc.data()!;
      final authorRef = data['author'] as DocumentReference;
      final authorDoc = await authorRef.get();
      final authorData = authorDoc.data() as Map<String, dynamic>;
      final author = UserModel.fromFirestore(authorData, authorDoc.id);

      return {
        'id': doc.id,
        ...data,
        'author': {
          'id': author.uid,
          'name': author.displayName ?? author.email,
          'email': author.email,
        },
      };
    } catch (e) {
      throw Exception('Failed to fetch itinerary: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getItinerariesByUser(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('itineraries')
          .where('author', isEqualTo: _firestore.collection('users').doc(userId))
          .orderBy('createdAt', descending: true)
          .get();

      List<Map<String, dynamic>> itineraries = [];

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final authorRef = data['author'] as DocumentReference;
        final authorDoc = await authorRef.get();
        final authorData = authorDoc.data() as Map<String, dynamic>;
        final author = UserModel.fromFirestore(authorData, authorDoc.id);

        itineraries.add({
          'id': doc.id,
          ...data,
          'author': {
            'id': author.uid,
            'name': author.displayName ?? author.email,
            'email': author.email,
          },
        });
      }

      return itineraries;
    } catch (e) {
      print('Error fetching itineraries by user: $e');
      return [];
    }
  }

  // Get itineraries by location
  Stream<List<Map<String, dynamic>>> getItinerariesByLocation(String location) {
    return _firestore
        .collection('itineraries')
        .where('location', isEqualTo: location)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final itineraries = <Map<String, dynamic>>[];
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();
          final authorRef = data['author'] as DocumentReference;
          final authorDoc = await authorRef.get();
          final authorData = authorDoc.data() as Map<String, dynamic>;
          final author = UserModel.fromFirestore(authorData, authorDoc.id);

          itineraries.add({
            'id': doc.id,
            ...data,
            'author': {
              'id': author.uid,
              'name': author.displayName ?? author.email,
              'email': author.email,
            },
          });
        } catch (e) {
          print('Error processing itinerary ${doc.id}: $e');
          continue;
        }
      }
      return itineraries;
    });
  }

  // Get popular itineraries
  Stream<List<Map<String, dynamic>>> getPopularItineraries({int limit = 10}) {
    return _firestore
        .collection('itineraries')
        .orderBy('likes', descending: true)
        .limit(limit)
        .snapshots()
        .asyncMap((snapshot) async {
      final itineraries = <Map<String, dynamic>>[];
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();
          final authorRef = data['author'] as DocumentReference;
          final authorDoc = await authorRef.get();
          final authorData = authorDoc.data() as Map<String, dynamic>;
          final author = UserModel.fromFirestore(authorData, authorDoc.id);

          itineraries.add({
            'id': doc.id,
            ...data,
            'author': {
              'id': author.uid,
              'name': author.displayName ?? author.email,
              'email': author.email,
            },
          });
        } catch (e) {
          print('Error processing itinerary ${doc.id}: $e');
          continue;
        }
      }
      return itineraries;
    });
  }

  // Like/Unlike itinerary
  Future<void> toggleLikeItinerary({
    required String itineraryId,
    required String userId,
  }) async {
    try {
      final docRef = _firestore.collection('itineraries').doc(itineraryId);
      final userRef = _firestore.collection('users').doc(userId);

      await _firestore.runTransaction((transaction) async {
        final itineraryDoc = await transaction.get(docRef);
        if (!itineraryDoc.exists) {
          throw Exception('Itinerary not found');
        }

        final likes = List<DocumentReference>.from(itineraryDoc.data()?['likes'] ?? []);
        final isLiked = likes.contains(userRef);

        if (isLiked) {
          likes.remove(userRef);
        } else {
          likes.add(userRef);
        }

        transaction.update(docRef, {
          'likes': likes,
          'likeCount': likes.length,
        });
      });
    } catch (e) {
      throw Exception('Failed to toggle like: $e');
    }
  }

  // Delete itinerary
  Future<void> deleteItinerary(String itineraryId) async {
    try {
      await _firestore.collection('itineraries').doc(itineraryId).delete();
    } catch (e) {
      throw Exception('Failed to delete itinerary: $e');
    }
  }

  // Search itineraries
  Stream<List<Map<String, dynamic>>> searchItineraries(String query) {
    return _firestore
        .collection('itineraries')
        .where('searchTerms', arrayContains: query.toLowerCase())
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final itineraries = <Map<String, dynamic>>[];
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();
          final authorRef = data['author'] as DocumentReference;
          final authorDoc = await authorRef.get();
          final authorData = authorDoc.data() as Map<String, dynamic>;
          final author = UserModel.fromFirestore(authorData, authorDoc.id);

          itineraries.add({
            'id': doc.id,
            ...data,
            'author': {
              'id': author.uid,
              'name': author.displayName ?? author.email,
              'email': author.email,
            },
          });
        } catch (e) {
          print('Error processing itinerary ${doc.id}: $e');
          continue;
        }
      }
      return itineraries;
    });
  }

  Future<void> updateItinerary({
    required String itineraryId,
    String? title,
    String? description,
    String? location,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? tags,
    String? status,
    String? shareStatus,
    Map<String, dynamic>? additionalData,
  }) async {
    final data = <String, dynamic>{};
    if (title != null) data['title'] = title;
    if (description != null) data['description'] = description;
    if (location != null) data['location'] = location;
    if (startDate != null) data['startDate'] = startDate;
    if (endDate != null) data['endDate'] = endDate;
    if (tags != null) data['tags'] = tags;
    if (status != null) data['status'] = status;
    if (shareStatus != null) data['shareStatus'] = shareStatus;
    if (additionalData != null && additionalData.containsKey('places')) {
      data['places'] = additionalData['places'];
    }
    data['updatedAt'] = FieldValue.serverTimestamp();

    await _firestore.collection('itineraries').doc(itineraryId).update(data);
  }

  // Get itineraries except those from current user
  Stream<List<Map<String, dynamic>>> getItinerariesExceptUserStream(String userId) {
    final userRef = _firestore.collection('users').doc(userId);
    return _firestore
        .collection('itineraries')
        .where('author', isNotEqualTo: userRef)
        .where('shareStatus', isEqualTo: 'public')
        .orderBy('author')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final List<Map<String, dynamic>> itineraries = [];
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();
          final authorRef = data['author'] as DocumentReference;
          final authorDoc = await authorRef.get();
          final authorData = authorDoc.data() as Map<String, dynamic>;
          final author = UserModel.fromFirestore(authorData, authorDoc.id);

          itineraries.add({
            'id': doc.id,
            'title': data['title'] ?? '',
            'description': data['description'] ?? '',
            'location': data['location'] ?? '',
            'startDate': data['startDate'],
            'endDate': data['endDate'],
            'tags': data['tags'] ?? [],
            'places': data['places'] ?? [],
            'status': data['status'] ?? 'planned',
            'shareStatus': data['shareStatus'],
            'createdAt': data['createdAt'],
            'updatedAt': data['updatedAt'],
            'author': author,
          });

          print('author: ${author.displayName}');
        } catch (e) {
          print('Error processing itinerary ${doc.id}: $e');
          continue;
        }
      }
      return itineraries;
    });
  }
}
