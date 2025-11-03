// lib/services/database.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:evalumate/models/profile.dart';
import 'package:evalumate/models/post.dart';
import 'package:evalumate/models/comment.dart';
import 'package:evalumate/models/notification.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseService {
  final String? uid;
  DatabaseService({this.uid});

  final CollectionReference profileCollection =
  FirebaseFirestore.instance.collection('profiles');
  final CollectionReference postsCollection =
  FirebaseFirestore.instance.collection('posts');
  // No need for a top-level commentsCollection or likesCollection anymore,
  // as they are subcollections of posts.

  // --- Existing Profile Data Operations (Adapted for subcollections) ---

  // NOTE: The `updateUserData` method provided in your new version of database.dart
  // is quite comprehensive. It expects many fields including `numberOfFollowers`,
  // `numberOfFollowing`, etc. If you want these counts to be strictly managed
  // by the follow/unfollow methods via FieldValue.increment/decrement,
  // ensure that when you *initially create* a user profile, these fields
  // are set to 0. Otherwise, merging might not initialize them.
  // For simplicity, I'm keeping your provided updateUserData as is,
  // assuming it handles initial setup or careful updates elsewhere.
  Future<void> updateUserData({
    String? userName,
    String? phoneNumber,
    String? displayName,
    String? email,
    String? bio,
    String? website,
    bool? isPrivate,
    int? numberOfPosts,
    int? numberOfFollowers,
    int? numberOfFollowing,
    dynamic createdAt,
    dynamic lastActive,
    List<String>? fcmTokens,
    bool? isVerified,
    Map<String, dynamic>? settings,
    List<String>? blockedUsers,
    String? userProfilePicUrl,
  }) async {
    if (uid == null) {
      print("Error: UID is null when trying to update user data.");
      return;
    }
    Map<String, dynamic> dataToUpdate = {};

    // Only add fields that are not null
    if (userName != null) dataToUpdate['userName'] = userName;
    if (phoneNumber != null) dataToUpdate['phoneNumber'] = phoneNumber;
    if (displayName != null) dataToUpdate['displayName'] = displayName;
    if (email != null) dataToUpdate['email'] = email;
    if (bio != null) dataToUpdate['bio'] = bio;
    if (website != null) dataToUpdate['website'] = website;
    if (isPrivate != null) dataToUpdate['isPrivate'] = isPrivate;
    if (numberOfPosts != null) dataToUpdate['numberOfPosts'] = numberOfPosts;
    if (numberOfFollowers != null) dataToUpdate['numberOfFollowers'] = numberOfFollowers;
    if (numberOfFollowing != null) dataToUpdate['numberOfFollowing'] = numberOfFollowing;
    if (fcmTokens != null) dataToUpdate['fcmTokens'] = fcmTokens;
    if (isVerified != null) dataToUpdate['isVerified'] = isVerified;
    if (settings != null) dataToUpdate['settings'] = settings;
    if (blockedUsers != null) dataToUpdate['blockedUsers'] = blockedUsers;
    if (userProfilePicUrl != null) dataToUpdate['userProfilePicUrl'] = userProfilePicUrl;
    if (createdAt != null) dataToUpdate['createdAt'] = createdAt;
    if (lastActive != null) dataToUpdate['lastActive'] = lastActive;
    if (dataToUpdate.isNotEmpty) {
      return await profileCollection.doc(uid).update(dataToUpdate);
    }
  }


  Future<void> incrementPostCount() async {
    if (uid == null) {
      print("Warning: Cannot increment post count, UID is null.");
      return;
    }
    return await profileCollection.doc(uid).update({
      'numberOfPosts': FieldValue.increment(1),
    });
  }

  Future<void> decrementPostCount(String userId) async {
    await profileCollection.doc(userId).update({
      'numberOfPosts': FieldValue.increment(-1),
    });
  }

  Stream<Profile?> get userData {
    if (uid == null) {
      return Stream.value(null);
    }
    return profileCollection.doc(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      return Profile.fromFirestore(doc);
    });
  }

  Stream<List<Profile>> get profiles {
    return profileCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Profile.fromFirestore(doc)).toList();
    });
  }

  Stream<List<Profile>> searchProfilesByUserName(String query) {
    if (query.trim().isEmpty) {
      return Stream.value([]);
    }
    String searchLower = query.toLowerCase();

    // Get all profiles and filter client-side for both userName and displayName
    return profileCollection.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Profile.fromFirestore(doc))
          .where((profile) {
        // Search in userName
        bool matchesUserName = profile.userName.toLowerCase().contains(searchLower);
        // Search in displayName (if it exists)
        bool matchesDisplayName = profile.displayName != null &&
            profile.displayName!.toLowerCase().contains(searchLower);

        return matchesUserName || matchesDisplayName;
      })
          .toList();
    });
  }
  // --- MODIFIED: Follow/Unfollow Logic (Already updated to subcollections) ---

  // Future<void> followUser(String currentUserId, String targetUserId) async {
  //   // Add current user to target user's followers subcollection
  //   await profileCollection.doc(targetUserId).collection('followers').doc(currentUserId).set({
  //     'followedAt': FieldValue.serverTimestamp(),
  //   });
  //
  //   // Add target user to current user's following subcollection
  //   await profileCollection.doc(currentUserId).collection('following').doc(targetUserId).set({
  //     'followingAt': FieldValue.serverTimestamp(),
  //   });
  //
  //   // Increment target user's followers count (in the profile document)
  //   await profileCollection.doc(targetUserId).update({
  //     'numberOfFollowers': FieldValue.increment(1),
  //   });
  //
  //   // Increment current user's following count (in the profile document)
  //   await profileCollection.doc(currentUserId).update({
  //     'numberOfFollowing': FieldValue.increment(1),
  //   });
  // }

  Future<void> unfollowUser(String currentUserId, String targetUserId) async {
    // Remove current user from target user's followers subcollection
    await profileCollection.doc(targetUserId).collection('followers').doc(currentUserId).delete();

    // Remove target user from current user's following subcollection
    await profileCollection.doc(currentUserId).collection('following').doc(targetUserId).delete();

    // Decrement target user's followers count
    await profileCollection.doc(targetUserId).update({
      'numberOfFollowers': FieldValue.increment(-1),
    });

    // Decrement current user's following count
    await profileCollection.doc(currentUserId).update({
      'numberOfFollowing': FieldValue.increment(-1),
    });
  }

  // Check if current user is following target user (Already updated)
  Stream<bool> isFollowing(String currentUserId, String targetUserId) {
    return profileCollection.doc(currentUserId).collection('following').doc(targetUserId).snapshots().map((snapshot) {
      return snapshot.exists;
    });
  }

  // NEW: Get a stream of UIDs that the current user is following (Already updated)
  Stream<List<String>> getFollowingUids(String currentUserId) {
    return profileCollection
        .doc(currentUserId)
        .collection('following')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => doc.id).toList(); // doc.id is the UID of the followed user
    });
  }

  // --- MODIFIED & NEW: Post Data Operations including Brand/Product ---

  // Modified `createPost` to include brand and product
  Future<String?> createPost({
    required String uid,
    required String mediaUrl,
    required String mediaType,
    required double aspectRatio,
    String? caption,
    required int rating,
    String? websiteLink,
    required String userName,
    String? userDisplayName,
    String? userProfilePicUrl,
    String? brand, // Added new field
    String? product, // Added new field
    List<String>? categories,
  }) async {
    try {
      final docRef = await postsCollection.add({
        'uid': uid,
        'mediaUrl': mediaUrl,
        'mediaType': mediaType,
        'aspectRatio': aspectRatio,
        'caption': caption,
        'rating': rating,
        'websiteLink': websiteLink,
        'createdAt': FieldValue.serverTimestamp(),
        // likesCount and commentsCount are now denormalized counts, updated via subcollection listeners
        'likesCount': 0,
        'commentsCount': 0,
        'userName': userName,
        'userDisplayName': userDisplayName,
        'userProfilePicUrl': userProfilePicUrl,
        'brand': brand, // Store brand
        'product': product, // Store product
        'categories': categories,
      });

      await incrementPostCount(); // Increment the user's total post count

      return docRef.id;
    } catch (e) {
      print('Error creating post: $e');
      return null;
    }
  }

  Stream<List<Post>> getUserPosts(String userId) {
    return postsCollection
        .where('uid', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList();
    });
  }

  Stream<List<Post>> getFeedPosts(List<String> uidsToFetchPostsFrom) {
    if (uidsToFetchPostsFrom.isEmpty) {
      return Stream.value([]); // No UIDs to query, return empty list
    }
    // Firestore's `whereIn` clause has a limit of 10.
    // If you need to support more, you'll have to break this into multiple queries
    // or use a Cloud Function to pre-aggregate a user's feed.
    // For now, we'll proceed assuming the list is <= 10.
    if (uidsToFetchPostsFrom.length > 10) {
      print("Warning: getFeedPosts received more than 10 UIDs. Firestore whereIn limit is 10.");
      uidsToFetchPostsFrom = uidsToFetchPostsFrom.sublist(0, 10);
    }

    return postsCollection
        .where('uid', whereIn: uidsToFetchPostsFrom)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList();
    });
  }

  // Modified updatePost to allow updating brand and product
  Future<void> updatePost({
    required String postId,
    String? caption,
    int? rating,
    String? websiteLink,
    String? brand, // Added
    String? product, // Added
  }) async {
    try {
      Map<String, dynamic> updateData = {};
      if (caption != null) updateData['caption'] = caption;
      if (rating != null) updateData['rating'] = rating;
      if (websiteLink != null) updateData['websiteLink'] = websiteLink;
      if (brand != null) updateData['brand'] = brand; // Update brand
      if (product != null) updateData['product'] = product; // Update product

      if (updateData.isNotEmpty) {
        await postsCollection.doc(postId).update(updateData);
        print('Post $postId updated successfully.');
      } else {
        print('No data provided to update for post $postId.');
      }
    } catch (e) {
      print('Error updating post $postId: $e');
      rethrow;
    }
  }


  Future<void> deletePost(String postId, String userId) async {
    try {
      // 1. Delete all comments subcollection
      final commentsSnapshot = await postsCollection.doc(postId).collection('comments').get();
      for (final doc in commentsSnapshot.docs) {
        await doc.reference.delete();
      }

      // 2. Delete all likes subcollection
      final likesSnapshot = await postsCollection.doc(postId).collection('likes').get();
      for (final doc in likesSnapshot.docs) {
        await doc.reference.delete();
      }

      // 3. Delete the post document itself
      await postsCollection.doc(postId).delete();

      // 4. Decrement the user's post count
      await decrementPostCount(userId);

      print('Post $postId and its subcollections deleted successfully.');
    } catch (e) {
      print('Error deleting post $postId: $e');
      rethrow;
    }
  }
  // --- Existing Comment Data Operations (Already updated to subcollections) ---

  // Future<void> addComment({
  //   required String postId,
  //   required String uid,
  //   required String text,
  //   required String userName,
  //   String? userProfilePicUrl,
  // }) async {
  //   try {
  //     final commentSubCollection = postsCollection.doc(postId).collection('comments');
  //     await commentSubCollection.add({
  //       'uid': uid,
  //       'text': text,
  //       'createdAt': FieldValue.serverTimestamp(),
  //       'userName': userName,
  //       'userProfilePicUrl': userProfilePicUrl,
  //     });
  //     // Increment commentsCount on the post document
  //     await postsCollection.doc(postId).update({
  //       'commentsCount': FieldValue.increment(1),
  //     });
  //   } catch (e) {
  //     print('Error adding comment: $e');
  //   }
  // }

  Stream<List<Comment>> getCommentsForPost(String postId) {
    return postsCollection.doc(postId).collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Comment.fromFirestore(doc)).toList();
    });
  }

  // --- Existing Like/Unlike Post Operations (Already updated to subcollections) ---

  // Future<void> toggleLikePost(String postId, String userId) async {
  //   final likeDocRef = postsCollection.doc(postId).collection('likes').doc(userId);
  //   final doc = await likeDocRef.get();
  //
  //   if (doc.exists) {
  //     await likeDocRef.delete();
  //     await postsCollection.doc(postId).update({'likesCount': FieldValue.increment(-1)});
  //   } else {
  //     await likeDocRef.set({'likedAt': FieldValue.serverTimestamp()});
  //     await postsCollection.doc(postId).update({'likesCount': FieldValue.increment(1)});
  //   }
  // }

  Stream<bool> hasLikedPost(String postId, String userId) {
    return postsCollection.doc(postId).collection('likes').doc(userId).snapshots().map((snapshot) {
      return snapshot.exists;
    });
  }

  // --- NEW: Brand & Product Related Methods (FIXED for case-insensitive matching) ---

  // Method to get distinct brands for auto-suggestion
  Stream<List<String>> getDistinctBrands() {
    return postsCollection
        .orderBy('brand')
        .snapshots()
        .map((snapshot) {
      Set<String> brands = {};
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('brand') && data['brand'] != null && data['brand'].toString().trim().isNotEmpty) {
          // Store original case, not lowercase
          brands.add(data['brand'].toString().trim());
        }
      }
      return brands.toList()..sort();
    });
  }

  // Method to get distinct products for auto-suggestion
  Stream<List<String>> getDistinctProducts() {
    return postsCollection
        .orderBy('product')
        .snapshots()
        .map((snapshot) {
      Set<String> products = {};
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('product') && data['product'] != null && data['product'].toString().trim().isNotEmpty) {
          // Store original case, not lowercase
          products.add(data['product'].toString().trim());
        }
      }
      return products.toList()..sort();
    });
  }

  // NEW: Get all distinct categories from posts
  Stream<List<String>> getDistinctCategories() {
    return postsCollection.snapshots().map((snapshot) {
      Set<String> distinctCategories = {};
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('categories') && data['categories'] is List) {
          for (var category in (data['categories'] as List).cast<String>()) {
            // Store original case, not lowercase
            distinctCategories.add(category.trim());
          }
        }
      }
      return distinctCategories.toList()..sort();
    });
  }

  // FIXED: Method to search posts by brand (case-insensitive, exclude private users)
  Stream<List<Post>> getPostsByBrand(String brandName) {
    return postsCollection
        .orderBy('brand')
        .snapshots()
        .asyncMap((snapshot) async {
      // Get all posts matching the brand
      final matchingPosts = snapshot.docs
          .where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('brand') && data['brand'] != null) {
          return data['brand'].toString().toLowerCase() == brandName.toLowerCase();
        }
        return false;
      })
          .map((doc) => Post.fromFirestore(doc))
          .toList();

      // Filter out posts from private users who aren't being followed
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) {
        // Not logged in - only show public posts
        final filteredPosts = <Post>[];
        for (var post in matchingPosts) {
          final userDoc = await profileCollection.doc(post.uid).get();
          final userData = userDoc.data() as Map<String, dynamic>?;
          if (userData?['isPrivate'] != true) {
            filteredPosts.add(post);
          }
        }
        return filteredPosts..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }

      // Get list of users current user is following
      final followingSnapshot = await profileCollection
          .doc(currentUserId)
          .collection('following')
          .get();
      final followingIds = followingSnapshot.docs.map((doc) => doc.id).toSet();

      // Filter posts
      final filteredPosts = <Post>[];
      for (var post in matchingPosts) {
        final userDoc = await profileCollection.doc(post.uid).get();
        final userData = userDoc.data() as Map<String, dynamic>?;
        final isPrivate = userData?['isPrivate'] == true;

        // Include post if: user is public, or user is private but being followed, or it's user's own post
        if (!isPrivate || followingIds.contains(post.uid) || post.uid == currentUserId) {
          filteredPosts.add(post);
        }
      }

      return filteredPosts..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

// FIXED: Method to search posts by product (case-insensitive, exclude private users)
  Stream<List<Post>> getPostsByProduct(String productName) {
    return postsCollection
        .orderBy('product')
        .snapshots()
        .asyncMap((snapshot) async {
      final matchingPosts = snapshot.docs
          .where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('product') && data['product'] != null) {
          return data['product'].toString().toLowerCase() == productName.toLowerCase();
        }
        return false;
      })
          .map((doc) => Post.fromFirestore(doc))
          .toList();

      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) {
        final filteredPosts = <Post>[];
        for (var post in matchingPosts) {
          final userDoc = await profileCollection.doc(post.uid).get();
          final userData = userDoc.data() as Map<String, dynamic>?;
          if (userData?['isPrivate'] != true) {
            filteredPosts.add(post);
          }
        }
        return filteredPosts..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }

      final followingSnapshot = await profileCollection
          .doc(currentUserId)
          .collection('following')
          .get();
      final followingIds = followingSnapshot.docs.map((doc) => doc.id).toSet();

      final filteredPosts = <Post>[];
      for (var post in matchingPosts) {
        final userDoc = await profileCollection.doc(post.uid).get();
        final userData = userDoc.data() as Map<String, dynamic>?;
        final isPrivate = userData?['isPrivate'] == true;

        if (!isPrivate || followingIds.contains(post.uid) || post.uid == currentUserId) {
          filteredPosts.add(post);
        }
      }

      return filteredPosts..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

// FIXED: Method to search posts by category (case-insensitive, exclude private users)
  Stream<List<Post>> getPostsByCategory(String categoryName) {
    return postsCollection
        .snapshots()
        .asyncMap((snapshot) async {
      final matchingPosts = snapshot.docs
          .where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('categories') && data['categories'] is List) {
          return (data['categories'] as List)
              .any((cat) => cat.toString().toLowerCase() == categoryName.toLowerCase());
        }
        return false;
      })
          .map((doc) => Post.fromFirestore(doc))
          .toList();

      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) {
        final filteredPosts = <Post>[];
        for (var post in matchingPosts) {
          final userDoc = await profileCollection.doc(post.uid).get();
          final userData = userDoc.data() as Map<String, dynamic>?;
          if (userData?['isPrivate'] != true) {
            filteredPosts.add(post);
          }
        }
        return filteredPosts..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }

      final followingSnapshot = await profileCollection
          .doc(currentUserId)
          .collection('following')
          .get();
      final followingIds = followingSnapshot.docs.map((doc) => doc.id).toSet();

      final filteredPosts = <Post>[];
      for (var post in matchingPosts) {
        final userDoc = await profileCollection.doc(post.uid).get();
        final userData = userDoc.data() as Map<String, dynamic>?;
        final isPrivate = userData?['isPrivate'] == true;

        if (!isPrivate || followingIds.contains(post.uid) || post.uid == currentUserId) {
          filteredPosts.add(post);
        }
      }

      return filteredPosts..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  Future<bool> isPhoneNumberTaken(String phoneNumber) async {
    final querySnapshot = await profileCollection
        .where('phoneNumber', isEqualTo: phoneNumber)
        .limit(1)
        .get();
    return querySnapshot.docs.isNotEmpty;
  }

  Future<bool> isUserNameTaken(String userName) async {
    final querySnapshot = await profileCollection
        .where('userName', isEqualTo: userName) // FIXED: Changed from 'displayName' to 'userName'
        .limit(1)
        .get();
    return querySnapshot.docs.isNotEmpty;
  }

  // Add these methods after the existing getPostsByCategory method

// Get posts by brand filtered by friends only
  Stream<List<Post>> getPostsByBrandFromFriends(String brandName, String currentUserId) {
    return getFollowingUids(currentUserId).asyncMap((followingUids) async {
      if (followingUids.isEmpty) {
        return <Post>[];
      }

      final snapshot = await postsCollection
          .where('uid', whereIn: followingUids.length > 10 ? followingUids.sublist(0, 10) : followingUids)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('brand') && data['brand'] != null) {
          return data['brand'].toString().toLowerCase() == brandName.toLowerCase();
        }
        return false;
      })
          .map((doc) => Post.fromFirestore(doc))
          .toList();
    });
  }

// Get posts by product filtered by friends only
  Stream<List<Post>> getPostsByProductFromFriends(String productName, String currentUserId) {
    return getFollowingUids(currentUserId).asyncMap((followingUids) async {
      if (followingUids.isEmpty) {
        return <Post>[];
      }

      final snapshot = await postsCollection
          .where('uid', whereIn: followingUids.length > 10 ? followingUids.sublist(0, 10) : followingUids)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('product') && data['product'] != null) {
          return data['product'].toString().toLowerCase() == productName.toLowerCase();
        }
        return false;
      })
          .map((doc) => Post.fromFirestore(doc))
          .toList();
    });
  }

// Get posts by category filtered by friends only
  Stream<List<Post>> getPostsByCategoryFromFriends(String categoryName, String currentUserId) {
    return getFollowingUids(currentUserId).asyncMap((followingUids) async {
      if (followingUids.isEmpty) {
        return <Post>[];
      }

      final snapshot = await postsCollection
          .where('uid', whereIn: followingUids.length > 10 ? followingUids.sublist(0, 10) : followingUids)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('categories') && data['categories'] is List) {
          return (data['categories'] as List)
              .any((cat) => cat.toString().toLowerCase() == categoryName.toLowerCase());
        }
        return false;
      })
          .map((doc) => Post.fromFirestore(doc))
          .toList();
    });
  }

  // --- NOTIFICATIONS SYSTEM ---

  final CollectionReference notificationsCollection =
  FirebaseFirestore.instance.collection('notifications');

  // Create a notification
  Future<void> createNotification({
    required String type,
    required String fromUserId,
    required String fromUserName,
    String? fromUserProfilePic,
    required String toUserId,
    String? postId,
    String? postImageUrl,
    String? commentText,
  }) async {
    try {
      // Don't create notification for self-actions
      if (fromUserId == toUserId) return;

      await notificationsCollection.add({
        'type': type,
        'fromUserId': fromUserId,
        'fromUserName': fromUserName,
        'fromUserProfilePic': fromUserProfilePic,
        'toUserId': toUserId,
        'postId': postId,
        'postImageUrl': postImageUrl,
        'commentText': commentText,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    } catch (e) {
      print('Error creating notification: $e');
    }
  }

  // Get notifications for a user
  Stream<List<AppNotification>> getUserNotifications(String userId) {
    return notificationsCollection
        .where('toUserId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => AppNotification.fromFirestore(doc)).toList();
    });
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await notificationsCollection.doc(notificationId).update({'isRead': true});
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  // Mark all notifications as read
  Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      final unreadNotifications = await notificationsCollection
          .where('toUserId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in unreadNotifications.docs) {
        await doc.reference.update({'isRead': true});
      }
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  // Get unread notification count
  Stream<int> getUnreadNotificationCount(String userId) {
    return notificationsCollection
        .where('toUserId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // --- FOLLOW REQUESTS (FOR PRIVATE ACCOUNTS) ---

  // Send follow request to private account
  Future<void> sendFollowRequest(String currentUserId, String targetUserId, String currentUserName, String? currentUserProfilePic) async {
    try {
      // Add to follow requests subcollection
      await profileCollection.doc(targetUserId).collection('followRequests').doc(currentUserId).set({
        'requestedAt': FieldValue.serverTimestamp(),
        'userName': currentUserName,
        'userProfilePicUrl': currentUserProfilePic,
      });

      // Create notification
      final targetProfile = await profileCollection.doc(targetUserId).get();
      final targetData = targetProfile.data() as Map<String, dynamic>?;

      await createNotification(
        type: 'follow_request',
        fromUserId: currentUserId,
        fromUserName: currentUserName,
        fromUserProfilePic: currentUserProfilePic,
        toUserId: targetUserId,
      );
    } catch (e) {
      print('Error sending follow request: $e');
      rethrow;
    }
  }

  // Accept follow request

  Future<void> acceptFollowRequest(String currentUserId, String requesterId) async {
    try {
      // Execute the follow action
      await followUser(requesterId, currentUserId);

      // Remove from follow requests
      await profileCollection.doc(currentUserId).collection('followRequests').doc(requesterId).delete();

      // Delete the follow_request notification
      final notifications = await notificationsCollection
          .where('toUserId', isEqualTo: currentUserId)
          .where('fromUserId', isEqualTo: requesterId)
          .where('type', isEqualTo: 'follow_request')
          .get();

      for (var doc in notifications.docs) {
        await doc.reference.delete();
      }

      // Create a follow notification - FIXED: Send to the requester, not current user
      final currentProfile = await profileCollection.doc(currentUserId).get();
      final currentData = currentProfile.data() as Map<String, dynamic>?;

      await createNotification(
        type: 'follow_accepted', // Changed type to be more specific
        fromUserId: currentUserId, // Current user (who accepted)
        fromUserName: currentData?['userName'] ?? 'User',
        fromUserProfilePic: currentData?['userProfilePicUrl'],
        toUserId: requesterId, // Send to the person who requested
      );
    } catch (e) {
      print('Error accepting follow request: $e');
      rethrow;
    }
  }

  // Reject follow request
  Future<void> rejectFollowRequest(String currentUserId, String requesterId) async {
    try {
      // Remove from follow requests
      await profileCollection.doc(currentUserId).collection('followRequests').doc(requesterId).delete();

      // Delete the notification
      final notifications = await notificationsCollection
          .where('toUserId', isEqualTo: currentUserId)
          .where('fromUserId', isEqualTo: requesterId)
          .where('type', isEqualTo: 'follow_request')
          .get();

      for (var doc in notifications.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      print('Error rejecting follow request: $e');
      rethrow;
    }
  }

  // Check if follow request is pending
  Stream<bool> hasFollowRequestPending(String currentUserId, String targetUserId) {
    return profileCollection
        .doc(targetUserId)
        .collection('followRequests')
        .doc(currentUserId)
        .snapshots()
        .map((snapshot) => snapshot.exists);
  }

  // Get follow requests for current user
  Stream<List<Map<String, dynamic>>> getFollowRequests(String userId) {
    return profileCollection
        .doc(userId)
        .collection('followRequests')
        .snapshots()
        .asyncMap((snapshot) async {
      List<Map<String, dynamic>> requests = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        requests.add({
          'userId': doc.id,
          'userName': data['userName'],
          'userProfilePicUrl': data['userProfilePicUrl'],
          'requestedAt': data['requestedAt'],
        });
      }
      return requests;
    });
  }

  // Update existing followUser method to create notification
  Future<void> followUser(String currentUserId, String targetUserId) async {
    // Add current user to target user's followers subcollection
    await profileCollection.doc(targetUserId).collection('followers').doc(currentUserId).set({
      'followedAt': FieldValue.serverTimestamp(),
    });

    // Add target user to current user's following subcollection
    await profileCollection.doc(currentUserId).collection('following').doc(targetUserId).set({
      'followingAt': FieldValue.serverTimestamp(),
    });

    // Increment target user's followers count (in the profile document)
    await profileCollection.doc(targetUserId).update({
      'numberOfFollowers': FieldValue.increment(1),
    });

    // Increment current user's following count (in the profile document)
    await profileCollection.doc(currentUserId).update({
      'numberOfFollowing': FieldValue.increment(1),
    });

    // Create follow notification
    final currentProfile = await profileCollection.doc(currentUserId).get();
    final currentData = currentProfile.data() as Map<String, dynamic>?;

    await createNotification(
      type: 'follow',
      fromUserId: currentUserId,
      fromUserName: currentData?['userName'] ?? 'User',
      fromUserProfilePic: currentData?['userProfilePicUrl'],
      toUserId: targetUserId,
    );
  }

  // Update toggleLikePost to create notification
  Future<void> toggleLikePost(String postId, String userId) async {
    final likeDocRef = postsCollection.doc(postId).collection('likes').doc(userId);
    final doc = await likeDocRef.get();

    if (doc.exists) {
      await likeDocRef.delete();
      await postsCollection.doc(postId).update({'likesCount': FieldValue.increment(-1)});

      // Optionally: Delete the like notification (we'll keep it for history)
    } else {
      await likeDocRef.set({'likedAt': FieldValue.serverTimestamp()});
      await postsCollection.doc(postId).update({'likesCount': FieldValue.increment(1)});

      // Create like notification
      final postDoc = await postsCollection.doc(postId).get();
      final postData = postDoc.data() as Map<String, dynamic>?;
      final userDoc = await profileCollection.doc(userId).get();
      final userData = userDoc.data() as Map<String, dynamic>?;

      if (postData != null) {
        await createNotification(
          type: 'like',
          fromUserId: userId,
          fromUserName: userData?['userName'] ?? 'User',
          fromUserProfilePic: userData?['userProfilePicUrl'],
          toUserId: postData['uid'],
          postId: postId,
          postImageUrl: postData['mediaUrl'],
        );
      }
    }
  }

  // Update addComment to create notification
  Future<void> addComment({
    required String postId,
    required String uid,
    required String text,
    required String userName,
    String? userProfilePicUrl,
  }) async {
    try {
      final commentSubCollection = postsCollection.doc(postId).collection('comments');
      await commentSubCollection.add({
        'uid': uid,
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
        'userName': userName,
        'userProfilePicUrl': userProfilePicUrl,
      });

      // Increment commentsCount on the post document
      await postsCollection.doc(postId).update({
        'commentsCount': FieldValue.increment(1),
      });

      // Create comment notification
      final postDoc = await postsCollection.doc(postId).get();
      final postData = postDoc.data() as Map<String, dynamic>?;

      if (postData != null) {
        await createNotification(
          type: 'comment',
          fromUserId: uid,
          fromUserName: userName,
          fromUserProfilePic: userProfilePicUrl,
          toUserId: postData['uid'],
          postId: postId,
          postImageUrl: postData['mediaUrl'],
          commentText: text,
        );
      }
    } catch (e) {
      print('Error adding comment: $e');
    }
  }
}