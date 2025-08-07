// lib/screens/home/home.dart
import 'package:evalumate/screens/home/profilepicture.dart'; // Re-import ProfilePicture
import 'package:evalumate/models/profile.dart';
import 'package:evalumate/services/auth.dart';
import 'package:flutter/material.dart';
import 'package:evalumate/services/database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:evalumate/models/post.dart'; // Import Post model
import 'package:evalumate/screens/home/edit_post_screen.dart'; // Re-import PostDetailScreen

class Home extends StatelessWidget {
  final AuthService _auth;
  Home({super.key}) : _auth = AuthService();

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    // Handle null user case gracefully, e.g., navigate to login
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('User not logged in. Please restart app.')),
      );
    }
    final String uid = user.uid;

    return Scaffold(
      backgroundColor: Colors.green[100],
      appBar: AppBar(
        backgroundColor: Colors.green[300],
        elevation: 0.0,
        // Update AppBar title to show current user's display name or 'Profile'
        title: StreamBuilder<Profile?>(
          stream: DatabaseService(uid: uid).userData,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Text('Loading...');
            }
            if (snapshot.hasError) {
              print('Error loading profile for AppBar: ${snapshot.error}');
              return const Text('Error');
            }
            final profile = snapshot.data;
            return Text(profile?.displayName ?? 'My Profile');
          },
        ),
        actions: <Widget>[
          Builder(
            builder: (context) {
              return IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  Scaffold.of(context).openEndDrawer();
                },
              );
            },
          ),
        ],
      ),
      endDrawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.green[300],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text(
                    'Settings',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  StreamBuilder<Profile?>(
                    stream: DatabaseService(uid: uid).userData,
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data != null) {
                        return Text(
                          snapshot.data!.userName,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        );
                      }
                      return const Text(
                        'User',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Change Username'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.phone),
              title: const Text('Phone Number'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.lock),
              title: const Text('Privacy'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Notifications'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text('Change Bio'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Change Website'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.bookmark),
              title: const Text('Saved Posts'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                Navigator.pop(context);
                await _auth.signOut();
              },
            ),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // Align profile content to start
        children: [
          // Profile area (Profile Picture + Stats + Username + Bio)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: StreamBuilder<Profile?>(
              stream: DatabaseService(uid: uid).userData,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                }
                if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                  return const Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          ProfilePicture(
                            uid: '', // Provide a default or empty UID if profile is null
                            size: 110,
                          ),
                          SizedBox(width: 20),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _ProfileStatColumn(label: 'Posts', value: 0),
                                _ProfileStatColumn(label: 'Followers', value: 0),
                                _ProfileStatColumn(label: 'Following', value: 0),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Loading user profile...',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  );
                }
                final profile = snapshot.data!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ProfilePicture(
                          uid: uid,
                          size: 110,
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _ProfileStatColumn(
                                  label: 'Posts', value: profile.numberOfPosts),
                              _ProfileStatColumn(
                                  label: 'Followers', value: profile.numberOfFollowers),
                              _ProfileStatColumn(
                                  label: 'Following', value: profile.numberOfFollowing),
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

          // --- User Posts Grid Section with White Background ---
          Expanded(
            child: Container(
              color: Colors.white, // Set background to white
              child: StreamBuilder<List<Post>>(
                stream: DatabaseService(uid: uid).getUserPosts(uid), // Get only current user's posts
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    print("Home Screen Post Grid Error: ${snapshot.error}");
                    return Center(
                      child: Text(
                        'Error loading posts: ${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    );
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No posts created yet!'));
                  } else {
                    final List<Post> userPosts = snapshot.data!;
                    return GridView.builder(
                      padding: const EdgeInsets.all(8.0),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4, // As requested: 4 items per row
                        crossAxisSpacing: 4.0, // Horizontal spacing between items
                        mainAxisSpacing: 4.0, // Vertical spacing between items
                        childAspectRatio: 1.0, // Make each grid item a square
                      ),
                      itemCount: userPosts.length,
                      itemBuilder: (context, index) {
                        final Post post = userPosts[index];
                        return GestureDetector(
                          onTap: () {
                            // Navigate to PostDetailScreen when an image is clicked
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditPostScreen(post: post),
                              ),
                            );
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8.0), // Slightly rounded corners for the images
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
                                : Container( // Placeholder for video thumbnails in the grid
                              color: Colors.black,
                              child: const Center(
                                child: Icon(Icons.videocam, color: Colors.white, size: 30),
                              ),
                            )
                                : Container( // Fallback if no media URL is available
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

// Your existing _ProfileStatColumn widget (keep this in the same file or its own widget file)
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