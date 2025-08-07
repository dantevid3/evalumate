// lib/screens/feed/feed_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:evalumate/models/post.dart';
import 'package:evalumate/services/database.dart';
import 'package:evalumate/screens/feed/post_card.dart'; // Import the new PostCard widget

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
    // Listen for auth state changes to update the feed if user logs in/out
    _auth.authStateChanges().listen((User? user) {
      if (mounted) {
        setState(() {
          _currentUser = user;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // If no user is logged in, show a message
    if (_currentUser == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.login, size: 60, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'Please log in to see your feed.',
              style: TextStyle(fontSize: 18, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Evalumate Feed'),
        backgroundColor: Colors.green[300],
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(

        children: [
          Expanded( // Wrap the StreamBuilder with Expanded to give it bounded height
            child: StreamBuilder<List<String>>(
              stream: DatabaseService().getFollowingUids(_currentUser!.uid),
              builder: (context, followingSnapshot) {
                if (followingSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (followingSnapshot.hasError) {
                  return Center(child: Text('Error loading following list: ${followingSnapshot.error}'));
                }

                List<String> uidsToFetchPostsFrom = [];
                // Add current user's UID to the list so they see their own posts
                uidsToFetchPostsFrom.add(_currentUser!.uid);

                // Add UIDs of followed users
                if (followingSnapshot.hasData && followingSnapshot.data!.isNotEmpty) {
                  uidsToFetchPostsFrom.addAll(followingSnapshot.data!);
                }

                // IMPORTANT: Firestore `whereIn` clause is limited to 10 items.
                // If you follow more than 10 people, this will only fetch posts
                // from the first 10, plus the current user's posts.
                // For a robust solution, you would need to implement pagination
                // or multiple queries.
                if (uidsToFetchPostsFrom.length > 10) {
                  uidsToFetchPostsFrom = uidsToFetchPostsFrom.sublist(0, 10);
                }

                // If no UIDs to fetch posts from, show a message
                if (uidsToFetchPostsFrom.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_add_alt_1, size: 80, color: Colors.grey),
                          SizedBox(height: 20),
                          Text(
                            'Follow users to see their posts in your feed!',
                            style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Start by searching for users on the search tab.',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Second StreamBuilder (nested): Get posts based on the collected UIDs
                return StreamBuilder<List<Post>>(
                  stream: DatabaseService().getFeedPosts(uidsToFetchPostsFrom),
                  builder: (context, postsSnapshot) {
                    if (postsSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (postsSnapshot.hasError) {
                      return Center(child: Text('Error loading posts: ${postsSnapshot.error}'));
                    }
                    if (!postsSnapshot.hasData || postsSnapshot.data!.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.content_paste_off, size: 80, color: Colors.grey),
                              SizedBox(height: 20),
                              Text(
                                'No posts from you or your followed users yet.',
                                style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 10),
                              Text(
                                'Create your first post or wait for your friends to share something!',
                                style: TextStyle(fontSize: 16, color: Colors.grey),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final List<Post> posts = postsSnapshot.data!;
                    return ListView.builder(
                      itemCount: posts.length,
                      itemBuilder: (context, index) {
                        final Post post = posts[index];
                        // Use the PostCard widget here to display all post details!
                        return PostCard(post: post);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

// Removed the _formatTimestamp helper function as it's already in PostCard and ViewPostScreen
// and is not directly used within FeedScreen itself.
}