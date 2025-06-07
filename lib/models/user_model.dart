class UserModel {
  final String uid;
  final String email;
  final String? displayName;
  final String? localPhotoPath;
  final Map<String, dynamic>? preferences;
  final String? region;
  final String? country;
  final String? city; // Added city field
  final DateTime? createdAt;
  final DateTime? lastSignIn;
  final String? regionCode; // Added regionCode
  final String? countryCode; // Added countryCode

  UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.localPhotoPath,
    this.preferences,
    this.region,
    this.regionCode, // Add here
    this.country,
    this.countryCode, // Add here
    this.city,
    this.createdAt,
    this.lastSignIn,
  });

  factory UserModel.fromFirestore(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      email: data['email'] ?? '',
      displayName: data['displayName'],
      localPhotoPath: data['localPhotoPath'],
      preferences: data['preferences'] as Map<String, dynamic>?,
      region: data['region'] as String?,
      regionCode: data['regionCode'] as String?, // Add here
      country: data['country'] as String?,
      countryCode: data['countryCode'] as String?, // Add here
      city: data['city'] as String?,
      createdAt: data['createdAt']?.toDate(),
      lastSignIn: data['lastSignIn']?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'localPhotoPath': localPhotoPath,
      'preferences': preferences,
      'region': region,
      'regionCode': regionCode, // Add here
      'country': country,
      'countryCode': countryCode, // Add here
      'city': city,
      'createdAt': createdAt,
      'lastSignIn': lastSignIn,
    };
  }

  UserModel copyWith({
    String? displayName,
    String? localPhotoPath,
    Map<String, dynamic>? preferences,
    String? state,
    String? regionCode, // Add here
    String? country,
    String? countryCode, // Add here
    String? city,
    DateTime? lastSignIn,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      localPhotoPath: localPhotoPath ?? this.localPhotoPath,
      preferences: preferences ?? this.preferences,
      region: state ?? this.region,
      regionCode: regionCode ?? this.regionCode,
      country: country ?? this.country,
      countryCode: countryCode ?? this.countryCode,
      city: city ?? this.city,
      createdAt: createdAt,
      lastSignIn: lastSignIn ?? this.lastSignIn,
    );
  }
}