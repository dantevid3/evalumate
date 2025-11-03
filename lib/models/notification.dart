// lib/models/notification.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String id;
  final String type; // 'follow', 'like', 'comment', 'follow_request'
  final String fromUserId;
  final String fromUserName;
  final String? fromUserProfilePic;
  final String toUserId;
  final String? postId; // For like/comment notifications
  final String? postImageUrl; // Thumbnail of the post
  final String? commentText; // For comment notifications
  final DateTime createdAt;
  final bool isRead;

  AppNotification({
    required this.id,
    required this.type,
    required this.fromUserId,
    required this.fromUserName,
    this.fromUserProfilePic,
    required this.toUserId,
    this.postId,
    this.postImageUrl,
    this.commentText,
    required this.createdAt,
    this.isRead = false,
  });

  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppNotification(
      id: doc.id,
      type: data['type'] ?? '',
      fromUserId: data['fromUserId'] ?? '',
      fromUserName: data['fromUserName'] ?? '',
      fromUserProfilePic: data['fromUserProfilePic'],
      toUserId: data['toUserId'] ?? '',
      postId: data['postId'],
      postImageUrl: data['postImageUrl'],
      commentText: data['commentText'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'fromUserId': fromUserId,
      'fromUserName': fromUserName,
      'fromUserProfilePic': fromUserProfilePic,
      'toUserId': toUserId,
      'postId': postId,
      'postImageUrl': postImageUrl,
      'commentText': commentText,
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': isRead,
    };
  }
}