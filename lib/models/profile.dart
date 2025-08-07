import 'package:cloud_firestore/cloud_firestore.dart';

class Profile {
  final String uid;
  final String userName;
  final String? displayName;
  final String? email;
  final String phoneNumber;
  final String? bio;
  final String? website;
  final bool isPrivate;
  final int numberOfPosts;
  final int numberOfFollowers;
  final int numberOfFollowing;
  final Timestamp? createdAt;
  final Timestamp? lastActive;
  final List<String>? fcmTokens;
  final bool? isVerified;
  final Map<String, dynamic>? settings;
  final List<String>? blockedUsers;
  final String? userProfilePicUrl; // <--- This field was added previously

  Profile({
    required this.uid,
    required this.userName,
    this.displayName,
    this.email,
    required this.phoneNumber,
    this.bio,
    this.website,
    this.isPrivate = false,
    this.numberOfPosts = 0,
    this.numberOfFollowers = 0,
    this.numberOfFollowing = 0,
    this.createdAt,
    this.lastActive,
    this.fcmTokens,
    this.isVerified,
    this.settings,
    this.blockedUsers,
    this.userProfilePicUrl, // <--- This was added to the constructor previously
  });

  // --- THIS IS THE CRUCIAL PART YOU NEED TO ADD/VERIFY IN YOUR PROFILE.DART FILE ---
  factory Profile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      // In a real application, you might want more robust error handling here
      // or return a default/empty profile if a document is expected but null.
      // For now, we'll return a minimal profile to prevent crashing.
      print('Warning: Profile document data is null for doc ID: ${doc.id}');
      return Profile(uid: doc.id, userName: 'Unknown User', phoneNumber: '');
    }

    return Profile(
      uid: doc.id,
      userName: data['userName'] as String? ?? '',
      phoneNumber: data['phoneNumber'] as String? ?? '',
      displayName: data['displayName'] as String?,
      email: data['email'] as String?,
      bio: data['bio'] as String?,
      website: data['website'] as String?,
      isPrivate: data['isPrivate'] as bool? ?? false,
      numberOfPosts: data['numberOfPosts'] as int? ?? 0,
      numberOfFollowers: data['numberOfFollowers'] as int? ?? 0,
      numberOfFollowing: data['numberOfFollowing'] as int? ?? 0,
      createdAt: data['createdAt'] as Timestamp?,
      lastActive: data['lastActive'] as Timestamp?,
      fcmTokens: (data['fcmTokens'] as List?)?.map((e) => e.toString()).toList(),
      isVerified: data['isVerified'] as bool?,
      settings: data['settings'] as Map<String, dynamic>?,
      blockedUsers: (data['blockedUsers'] as List?)?.map((e) => e.toString()).toList(),
      userProfilePicUrl: data['userProfilePicUrl'] as String?, // Ensure this is read
    );
  }
}

