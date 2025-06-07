import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_model.dart';

class AuthService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  UserModel? _currentUser;

  // Get current user
  UserModel? get currentUser => _currentUser;

  Stream<UserModel?> get authStateChanges {
    if (_currentUser == null) {
      print("current user is null");
      return Stream.value(null);
    }

    return _firestore
        .collection('users')
        .doc(_currentUser!.uid)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return UserModel.fromFirestore(doc.data()!, doc.id);
      } else {
        return null;
      }
    });
  }

  // Stream of authentication state changes
  // Stream<UserModel?> get authStateChanges async* {
  //   // First yield the current user immediately
  //   yield _currentUser;
  //
  //   // Then listen to Firestore changes
  //   await for (final snapshot in _firestore.collection('users').snapshots()) {
  //     try {
  //       if (_currentUser == null) {
  //         yield null;
  //         continue;
  //       }
  //
  //       final userDoc = snapshot.docs.firstWhere(
  //             (doc) => doc.id == _currentUser!.uid,
  //         orElse: () => throw Exception('User document not found'),
  //       );
  //
  //       _currentUser = UserModel.fromFirestore(userDoc.data(), userDoc.id);
  //       yield _currentUser;
  //     } catch (e) {
  //       print('Error in auth state changes: $e');
  //       _currentUser = null;
  //       yield null;
  //     }
  //   }
  // }

  // Initialize current user from local storage
  Future<void> initializeCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      if (userId != null) {
        final userDoc = await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          _currentUser = UserModel.fromFirestore(userDoc.data()!, userDoc.id);
          print("find current user");
          print("current user: ${_currentUser}");
        }
      }
    } catch (e) {
      print('Error initializing current user: $e');
      _currentUser = null;
    }
  }

  // Save user ID to local storage
  Future<void> _saveUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', userId);
  }

  // Clear user ID from local storage
  Future<void> _clearUserId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
  }

  // Hash password
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Sign Up with Email/Password
  Future<UserModel> signUpWithEmail(
      String email,
      String password, {
        String? displayName,
        String? region,
        String? regionCode,
        String? country,
        String? countryCode,
        String? city, // Added city parameter
      }) async {
    try {
      // Check if email already exists
      final existingUser = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (existingUser.docs.isNotEmpty) {
        throw Exception('Email already in use');
      }

      // Create new user document
      final userDoc = await _firestore.collection('users').add({
        'email': email,
        'password': _hashPassword(password),
        'displayName': displayName,
        'region': region,
        'regionCode': regionCode,
        'country': country,
        'countryCode': countryCode,
        'city': city, // Added city to document
        'createdAt': FieldValue.serverTimestamp(),
        'lastSignIn': FieldValue.serverTimestamp(),
      });

      // Get the created user
      final userData = await userDoc.get();
      _currentUser = UserModel.fromFirestore(
        userData.data()!,
        userData.id,
      );

      // Save user ID to local storage
      await _saveUserId(_currentUser!.uid);

      return _currentUser!;
    } catch (e) {
      throw Exception('Failed to create account: $e');
    }
  }

  // Sign In with Email/Password
  Future<UserModel> signInWithEmail(String email, String password) async {
    try {
      final hashedPassword = _hashPassword(password);

      // Find user with matching email and password
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .where('password', isEqualTo: hashedPassword)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw Exception('Invalid email or password');
      }

      final userDoc = querySnapshot.docs.first;

      // Update last sign in
      await userDoc.reference.update({
        'lastSignIn': FieldValue.serverTimestamp(),
      });

      _currentUser = UserModel.fromFirestore(
        userDoc.data(),
        userDoc.id,
      );

      // Save user ID to local storage
      await _saveUserId(_currentUser!.uid);

      return _currentUser!;
    } catch (e) {
      throw Exception('Failed to sign in: $e');
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _clearUserId();
    _currentUser = null;
  }

  // Update Profile
  Future<UserModel> updateProfile({
    required String uid,
    String? displayName,
    String? region,
    String? country,
    String? city, // Added city parameter
    String? localPhotoPath,
  }) async {
    try {
      final updates = <String, dynamic>{
        if (displayName != null) 'displayName': displayName,
        if (region != null) 'region': region,
        if (country != null) 'country': country,
        if (city != null) 'city': city, // Added city to updates
        if (localPhotoPath != null) 'localPhotoPath': localPhotoPath,
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('users').doc(uid).update(updates);

      final updatedDoc = await _firestore.collection('users').doc(uid).get();
      _currentUser = UserModel.fromFirestore(
        updatedDoc.data()!,
        updatedDoc.id,
      );

      return _currentUser!;
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  // Reset Password
  Future<void> resetPassword(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw Exception('Email not found');
      }

      // Here you would typically:
      // 1. Generate a password reset token
      // 2. Store it in Firestore with an expiration
      // 3. Send an email to the user with a reset link
      // For now, we'll just throw a "not implemented" exception
      throw Exception('Password reset not implemented');
    } catch (e) {
      throw Exception('Failed to reset password: $e');
    }
  }

  // Delete Account
  Future<void> deleteAccount(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).delete();
      _currentUser = null;
    } catch (e) {
      throw Exception('Failed to delete account: $e');
    }
  }

  // Check if user is signed in
  bool isSignedIn() {
    return _currentUser != null;
  }

  // Change Password
  Future<void> changePassword(String uid, String oldPassword, String newPassword) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();

      if (!userDoc.exists) {
        throw Exception('User not found');
      }

      final userData = userDoc.data()!;
      if (userData['password'] != _hashPassword(oldPassword)) {
        throw Exception('Invalid current password');
      }

      await userDoc.reference.update({
        'password': _hashPassword(newPassword),
      });
    } catch (e) {
      throw Exception('Failed to change password: $e');
    }
  }
}