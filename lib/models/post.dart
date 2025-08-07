// lib/models/post.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String postId;
  final String uid;
  final String userName;
  final String? userDisplayName;
  final String? userProfilePicUrl;
  final String mediaUrl;
  final String mediaType; // 'image' or 'video'
  final String? caption;
  final int rating; // e.g., 1-100%
  final String? websiteLink;
  final Timestamp createdAt;
  final double aspectRatio; // For media display
  final List<String> likes; // UIDs of users who liked the post
  final int commentsCount; // Denormalized count of comments
  final int likesCount;
  final String? brand; // New field
  final String? product; // New field
  final List<String> categories;

  Post({
    required this.postId,
    required this.uid,
    required this.userName,
    this.userDisplayName,
    this.userProfilePicUrl,
    required this.mediaUrl,
    required this.mediaType,
    this.caption,
    required this.rating,
    this.websiteLink,
    required this.createdAt,
    required this.aspectRatio,
    this.likes = const [], // Initialize as empty list
    this.commentsCount = 0, // Initialize with 0
    this.likesCount = 0,
    this.brand, // Initialize as null
    this.product, // Initialize as null
    this.categories = const [],
  });

  factory Post.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Post(
      postId: doc.id,
      uid: data['uid'] ?? '',
      userName: data['userName'] ?? 'Unknown User',
      userDisplayName: data['userDisplayName'],
      userProfilePicUrl: data['userProfilePicUrl'],
      mediaUrl: data['mediaUrl'] ?? '',
      mediaType: data['mediaType'] ?? 'image',
      caption: data['caption'],
      rating: data['rating'] ?? 0,
      websiteLink: data['websiteLink'],
      createdAt: data['createdAt'] ?? Timestamp.now(),
      aspectRatio: (data['aspectRatio'] as num?)?.toDouble() ?? 1.0,
      likes: List<String>.from(data['likes'] ?? []),
      commentsCount: data['commentsCount'] ?? 0,
      likesCount: data['likesCount'] ?? 0,
      brand: data['brand'], // Map new field
      product: data['product'], // Map new field
      categories: List<String>.from(data['categories'] ?? []), // Map new field
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'userName': userName,
      'userDisplayName': userDisplayName,
      'userProfilePicUrl': userProfilePicUrl,
      'mediaUrl': mediaUrl,
      'mediaType': mediaType,
      'caption': caption,
      'rating': rating,
      'websiteLink': websiteLink,
      'createdAt': createdAt,
      'aspectRatio': aspectRatio,
      'likes': likes,
      'commentsCount': commentsCount,
      'likesCount': likesCount,
      'brand': brand, // Add new field
      'product': product, // Add new field
      'categories': categories, // Add new field
    };
  }
}