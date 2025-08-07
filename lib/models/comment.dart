import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String commentId; // Document ID
  final String uid; // User who commented
  final String text;
  final Timestamp createdAt;
  final String userName; // Denormalized from Profile
  final String? userProfilePicUrl; // Denormalized

  Comment({
    required this.commentId,
    required this.uid,
    required this.text,
    required this.createdAt,
    required this.userName,
    this.userProfilePicUrl,
  });

  // Factory constructor to create a Comment object from a Firestore DocumentSnapshot
  factory Comment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Comment(
      commentId: doc.id,
      uid: data['uid'] ?? '',
      text: data['text'] ?? '',
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
      userName: data['userName'] ?? '',
      userProfilePicUrl: data['userProfilePicUrl'],
    );
  }

  // Method to convert a Comment object to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'text': text,
      'createdAt': createdAt,
      'userName': userName,
      'userProfilePicUrl': userProfilePicUrl,
    };
  }
}