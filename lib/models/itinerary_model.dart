import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_model.dart';

class ItineraryModel {
  final String id;
  final String title;
  final String description;
  final String location;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> tags;
  final String status;
  final UserModel author;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int likeCount;
  final List<DocumentReference> likes;
  final List<Map<String, dynamic>> places;
  final String shareStatus;

  ItineraryModel({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.startDate,
    required this.endDate,
    required this.shareStatus,
    List<String>? tags,
    String? status,
    required this.author,
    required this.createdAt,
    required this.updatedAt,
    int? likeCount,
    List<DocumentReference>? likes,
    List<Map<String, dynamic>>? places,
  })  : tags = tags ?? [],
        status = status ?? 'planned',
        likeCount = likeCount ?? 0,
        likes = likes ?? [],
        places = places ?? [];

  factory ItineraryModel.fromFirestore(
      Map<String, dynamic> data,
      String id,
      UserModel author,
      ) {
    return ItineraryModel(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      location: data['location'] ?? '',
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      tags: List<String>.from(data['tags'] ?? []),
      status: data['status'] ?? 'planned',
      author: author,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null ? (data['updatedAt'] as Timestamp).toDate() : DateTime.now(), // Default to current time if null
      likeCount: data['likeCount'] ?? 0,
      likes: List<DocumentReference>.from(data['likes'] ?? []),
      places: data['places'] != null ? List<Map<String, dynamic>>.from(data['places']) : [],
      shareStatus: data['shareStatus'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'location': location,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'tags': tags,
      'status': status,
      'author': FirebaseFirestore.instance.collection('users').doc(author.uid),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'likeCount': likeCount,
      'likes': likes,
      'places': places,
      'searchTerms': _generateSearchTerms(),
      'shareStatus': shareStatus,
    };
  }

  List<String> _generateSearchTerms() {
    final terms = <String>{};

    // Add title terms
    terms.addAll(title.toLowerCase().split(' '));

    // Add location terms
    terms.addAll(location.toLowerCase().split(' '));

    // Add tags
    terms.addAll(tags.map((tag) => tag.toLowerCase()));

    // Add author name if available
    if (author.displayName != null) {
      terms.addAll(author.displayName!.toLowerCase().split(' '));
    }

    return terms.toList();
  }

  ItineraryModel copyWith({
    String? title,
    String? description,
    String? location,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? tags,
    String? status,
    UserModel? author,
    DateTime? updatedAt,
    int? likeCount,
    List<DocumentReference>? likes,
  }) {
    return ItineraryModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      tags: tags ?? this.tags,
      status: status ?? this.status,
      author: author ?? this.author,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      likeCount: likeCount ?? this.likeCount,
      likes: likes ?? this.likes,
      shareStatus: 'private',
    );
  }

  bool get isCompleted => status == 'completed';
  bool get isPending => status == 'planned';
  bool get isCancelled => status == 'cancelled';
  bool get isInProgress => status == 'in_progress';

  Duration get duration => endDate.difference(startDate);
  int get durationInDays => duration.inDays;


  bool isLikedBy(String userId) {
    // Convert the list of DocumentReference to a list of String IDs
    List<String> likedUser = likes.map((docRef) => docRef.id).toList();

    // Check if the userId is in the list of liked user IDs
    return likedUser.contains(userId);
  }

  @override
  String toString() {
    return 'ItineraryModel(id: $id, title: $title, location: $location, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ItineraryModel &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.location == location &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.status == status &&
        other.author == author;
  }

  @override
  int get hashCode {
    return id.hashCode ^
    title.hashCode ^
    description.hashCode ^
    location.hashCode ^
    startDate.hashCode ^
    endDate.hashCode ^
    status.hashCode ^
    author.hashCode;
  }
}