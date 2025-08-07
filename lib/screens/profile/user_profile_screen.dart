

import 'package:evalumate/screens/feed/view_post_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // For current user UID
import 'package:cloud_firestore/cloud_firestore.dart'; // For Timestamp in PostDetailScreen
import 'package:evalumate/models/profile.dart';
import 'package:evalumate/models/post.dart';
import 'package:evalumate/services/database.dart';
import 'package:evalumate/screens/home/profilepicture.dart'; // Re-use the ProfilePicture widget


class UserProfileScreen extends StatefulWidget {
  final Profile profile; // The profile of the user being viewed

  const UserProfileScreen({super.key, required this.profile});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  // Current logged-in user's UID (the one viewing the profile)
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;

  // Helper widget for profile stats (copy from home.dart if not already separate)
  Widget _profileStatColumn(String label, int value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black54,
          ),
        ),
        Text(
          value.toString(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Check if the viewed profile is the current logged-in user's profile
    final bool isCurrentUserProfile = _currentUserId == widget.profile.uid;

    return Scaffold(
      backgroundColor: Colors.green[100],
      appBar: AppBar(
        backgroundColor: Colors.green[300],
        elevation: 0.0,
        title: Text(widget.profile.displayName ?? widget.profile.userName), // Display viewed user's name
        actions: <Widget>[
          // You could add a share profile button here for example
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // Align content to start for username/bio
        children: [
          // Profile Info Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: StreamBuilder<Profile?>(
              // Listen to the viewed user's profile data for real-time updates
              stream: DatabaseService(uid: widget.profile.uid).userData,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                }
                if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start, // Ensure children align to start
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          ProfilePicture(
                            uid: widget.profile.uid, // Use the viewed profile's UID
                            size: 110,
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _profileStatColumn('Posts', 0),
                                _profileStatColumn('Followers', 0),
                                _profileStatColumn('Following', 0),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        // Display username even if profile data is null, fallback to initial profile's username
                        '${widget.profile.userName}',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Loading user profile...',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  );
                }
                final profile = snapshot.data!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start, // Align children to start
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ProfilePicture(
                          uid: profile.uid, // Use the real-time profile's UID
                          size: 110,
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column( // Changed to Column to stack stats and follow button
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _profileStatColumn('Posts', profile.numberOfPosts),
                                  _profileStatColumn('Followers', profile.numberOfFollowers),
                                  _profileStatColumn('Following', profile.numberOfFollowing),
                                ],
                              ),
                              if (!isCurrentUserProfile && _currentUserId != null) // Only show follow button if not self and logged in
                                const SizedBox(height: 16),
                              if (!isCurrentUserProfile && _currentUserId != null)
                                StreamBuilder<bool>(
                                  stream: DatabaseService().isFollowing(_currentUserId!, profile.uid),
                                  builder: (context, snapshot) {
                                    final bool isFollowing = snapshot.data ?? false;
                                    return ElevatedButton(
                                      onPressed: () async {
                                        if (_currentUserId == null) return; // Should not happen if button is shown
                                        try {
                                          if (isFollowing) {
                                            await DatabaseService().unfollowUser(_currentUserId!, profile.uid);
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Unfollowed ${profile.userName}')),
                                            );
                                          } else {
                                            await DatabaseService().followUser(_currentUserId!, profile.uid);
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Following ${profile.userName}')),
                                            );
                                          }
                                        } catch (e) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Action failed: ${e.toString()}')),
                                          );
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isFollowing ? Colors.grey[400] : Colors.green[600],
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                                      ),
                                      child: Text(isFollowing ? 'Following' : 'Follow'),
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Display userName
                    Text(
                      profile.userName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Display bio
                    if (profile.bio != null && profile.bio!.isNotEmpty)
                      Text(
                        profile.bio!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    //const SizedBox(height: 16),
                  ],
                );
              },
            ),
          ),
          //const SizedBox(height: 16), // Spacing below profile info

          // User Posts Grid Section (for the viewed user) with White Background
          Expanded(
            child: Container(
              color: Colors.white, // Set background to white
              child: StreamBuilder<List<Post>>(
                stream: DatabaseService(uid: widget.profile.uid).getUserPosts(widget.profile.uid), // Get posts for the viewed user
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    print("User Profile Screen Post Grid Error: ${snapshot.error}");
                    return Center(
                      child: Text(
                        'Error loading posts: ${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    );
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No posts created yet by this user.'));
                  } else {
                    final List<Post> userPosts = snapshot.data!;
                    return GridView.builder(
                      padding: const EdgeInsets.all(8.0),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 4.0,
                        mainAxisSpacing: 4.0,
                        childAspectRatio: 1.0,
                      ),
                      itemCount: userPosts.length,
                      itemBuilder: (context, index) {
                        final Post post = userPosts[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ViewPostScreen(post: post),
                              ),
                            );
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: post.mediaUrl.isNotEmpty
                                ? post.mediaType == 'image'
                                ? Image.network(
                              post.mediaUrl,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) =>
                              const Center(child: Icon(Icons.broken_image, size: 30, color: Colors.grey)),
                            )
                                : Container(
                              color: Colors.black,
                              child: const Center(
                                child: Icon(Icons.videocam, color: Colors.white, size: 30),
                              ),
                            )
                                : Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: Icon(Icons.image_not_supported, size: 30, color: Colors.grey),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Your existing _ProfileStatColumn widget (re-added if it was not already separate)
class _ProfileStatColumn extends StatelessWidget {
  final String label;
  final int value;

  const _ProfileStatColumn({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black54,
          ),
        ),
        Text(
          value.toString(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}