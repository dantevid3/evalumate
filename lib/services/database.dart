// lib/services/database.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:evalumate/models/profile.dart';
import 'package:evalumate/models/post.dart';
import 'package:evalumate/models/comment.dart';

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
    required String userName,
    required String phoneNumber,
    String? displayName,
    String? email,
    String? bio,
    String? website,
    bool? isPrivate,
    int? numberOfPosts,
    int? numberOfFollowers, // Explicitly passed, but often managed by increments
    int? numberOfFollowing, // Explicitly passed, but often managed by increments
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

    Map<String, dynamic> dataToUpdate = {
      'userName': userName,
      'phoneNumber': phoneNumber,
      if (displayName != null) 'displayName': displayName,
      if (email != null) 'email': email,
      if (bio != null) 'bio': bio,
      if (website != null) 'website': website,
      'isPrivate': isPrivate ?? false,
      'numberOfPosts': numberOfPosts ?? 0,
      'numberOfFollowers': numberOfFollowers ?? 0,
      'numberOfFollowing': numberOfFollowing ?? 0,
      if (fcmTokens != null) 'fcmTokens': fcmTokens,
      'isVerified': isVerified ?? false,
      if (settings != null) 'settings': settings,
      if (blockedUsers != null) 'blockedUsers': blockedUsers,
      if (userProfilePicUrl != null) 'userProfilePicUrl': userProfilePicUrl,
    };

    if (createdAt != null) dataToUpdate['createdAt'] = createdAt;
    if (lastActive != null) dataToUpdate['lastActive'] = lastActive;

    return await profileCollection.doc(uid).set(
      dataToUpdate,
      SetOptions(merge: true),
    );
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
    // Using startAt and endAt for prefix search (case-insensitive for usernames)
    return profileCollection
        .orderBy('userName') // Ensure index is set up for 'userName' field
        .startAt([searchLower])
        .endAt(['$searchLower\uf8ff'])
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Profile.fromFirestore(doc))
          .where((profile) => profile.userName.toLowerCase().contains(searchLower))
          .toList();
    });
  }

  // --- MODIFIED: Follow/Unfollow Logic (Already updated to subcollections) ---

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
  }

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
    } catch (e) {
      print('Error adding comment: $e');
    }
  }

  Stream<List<Comment>> getCommentsForPost(String postId) {
    return postsCollection.doc(postId).collection('comments')
        .orderBy('createdAt', descending: false) // Usually comments are oldest first
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Comment.fromFirestore(doc)).toList();
    });
  }

  // --- Existing Like/Unlike Post Operations (Already updated to subcollections) ---

  Future<void> toggleLikePost(String postId, String userId) async {
    final likeDocRef = postsCollection.doc(postId).collection('likes').doc(userId);
    final doc = await likeDocRef.get();

    if (doc.exists) {
      await likeDocRef.delete();
      await postsCollection.doc(postId).update({'likesCount': FieldValue.increment(-1)});
    } else {
      await likeDocRef.set({'likedAt': FieldValue.serverTimestamp()});
      await postsCollection.doc(postId).update({'likesCount': FieldValue.increment(1)});
    }
  }

  Stream<bool> hasLikedPost(String postId, String userId) {
    return postsCollection.doc(postId).collection('likes').doc(userId).snapshots().map((snapshot) {
      return snapshot.exists;
    });
  }

  // --- NEW: Brand & Product Related Methods (Incorporating the new subcollection structure) ---

  // Method to get distinct brands for auto-suggestion
  // This approach is not ideal for large datasets as it reads ALL posts.
  // For production, consider using Firestore indexes or a Cloud Function to
  // maintain a separate collection of distinct brands/products.
  Stream<List<String>> getDistinctBrands() {
    return postsCollection
        .orderBy('brand') // Ensure an index exists for 'brand'
        .snapshots()
        .map((snapshot) {
      Set<String> brands = {};
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('brand') && data['brand'] != null && data['brand'].isNotEmpty) {
          brands.add(data['brand'].toString().toLowerCase()); // Store in lowercase for case-insensitive matching
        }
      }
      return brands.toList()..sort(); // Return sorted list of unique brands
    });
  }

  // Method to get distinct products for auto-suggestion
  // Same caveat as getDistinctBrands applies here.
  Stream<List<String>> getDistinctProducts() {
    return postsCollection
        .orderBy('product') // Ensure an index exists for 'product'
        .snapshots()
        .map((snapshot) {
      Set<String> products = {};
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('product') && data['product'] != null && data['product'].isNotEmpty) {
          products.add(data['product'].toString().toLowerCase()); // Store in lowercase
        }
      }
      return products.toList()..sort(); // Return sorted list of unique products
    });
  }


  // NEW: Get all distinct categories from posts
  Stream<List<String>> getDistinctCategories() {
    return postsCollection.snapshots().map((snapshot) {
      Set<String> distinctCategories = {};
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('categories') && data['categories'] is List) {
          // Ensure categories is a List<String>
          for (var category in (data['categories'] as List).cast<String>()) {
            distinctCategories.add(category.toLowerCase().trim());
          }
        }
      }
      return distinctCategories.toList()..sort(); // Add .sort() for consistent order
    });
  }

  // Method to search posts by brand (exact match)
  Stream<List<Post>> getPostsByBrand(String brandName) {
    return postsCollection
        .where('brand', isEqualTo: brandName) // Ensure an index exists for 'brand'
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList());
  }

  // Method to search posts by product (exact match)
  Stream<List<Post>> getPostsByProduct(String productName) {
    return postsCollection
        .where('product', isEqualTo: productName) // Ensure an index exists for 'product'
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList());
  }

  // Method to search posts by category (using arrayContains for list field)
  Stream<List<Post>> getPostsByCategory(String categoryName) {
    // Ensure an index exists for 'categories' (array) and 'createdAt'
    return postsCollection
        .where('categories', arrayContains: categoryName) // Use arrayContains for List<String> field
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList());
  }


  Future<bool> isPhoneNumberTaken(String phoneNumber) async {
    final querySnapshot = await profileCollection
        .where('phoneNumber', isEqualTo: phoneNumber)
        .limit(1)
        .get();
    return querySnapshot.docs.isNotEmpty;
  }

  // Display Name uniqueness is more complex due to case-insensitivity and being optional.
  // If you need strict uniqueness for display names, you might enforce lowercasing
  // for storage and checking, or keep a separate collection of unique display names.
  Future<bool> isUserNameTaken(String userName) async {
    final querySnapshot = await profileCollection
        .where('displayName', isEqualTo: userName)
        .limit(1)
        .get();
    return querySnapshot.docs.isNotEmpty;
  }
}

