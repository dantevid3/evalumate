// lib/screens/inapp/brand_product_category_feed_screen.dart

import 'package:flutter/material.dart';
import 'package:evalumate/models/post.dart';
import 'package:evalumate/services/database.dart';
import 'package:evalumate/screens/feed/post_card.dart';
import 'package:evalumate/utils/feed_type.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BrandProductCategoryFeedScreen extends StatefulWidget {
  final String query;
  final FeedType feedType;

  const BrandProductCategoryFeedScreen({
    super.key,
    required this.query,
    required this.feedType,
  });

  @override
  State<BrandProductCategoryFeedScreen> createState() => _BrandProductCategoryFeedScreenState();
}

class _BrandProductCategoryFeedScreenState extends State<BrandProductCategoryFeedScreen> {
  bool _showFriendsOnly = false;

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    String appBarTitle;
    Stream<List<Post>> postsStream;

    // Determine app bar title and corresponding stream based on feedType and friends filter
    switch (widget.feedType) {
      case FeedType.brand:
        appBarTitle = 'Brand: ${widget.query}';
        postsStream = _showFriendsOnly && currentUser != null
            ? DatabaseService().getPostsByBrandFromFriends(widget.query, currentUser.uid)
            : DatabaseService().getPostsByBrand(widget.query);
        break;
      case FeedType.product:
        appBarTitle = 'Product: ${widget.query}';
        postsStream = _showFriendsOnly && currentUser != null
            ? DatabaseService().getPostsByProductFromFriends(widget.query, currentUser.uid)
            : DatabaseService().getPostsByProduct(widget.query);
        break;
      case FeedType.category:
        appBarTitle = 'Category: ${widget.query}';
        postsStream = _showFriendsOnly && currentUser != null
            ? DatabaseService().getPostsByCategoryFromFriends(widget.query, currentUser.uid)
            : DatabaseService().getPostsByCategory(widget.query);
        break;
      default:
        appBarTitle = 'Feed: ${widget.query}';
        postsStream = Stream.value([]);
        break;
    }

    String getFeedTypeString() {
      switch (widget.feedType) {
        case FeedType.brand:
          return 'brand';
        case FeedType.product:
          return 'product';
        case FeedType.category:
          return 'category';
        default:
          return 'item';
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        backgroundColor: Colors.green[300],
        elevation: 0,
        actions: [
          // Friends filter toggle button
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: Icon(
                _showFriendsOnly ? Icons.people : Icons.people_outline,
                color: _showFriendsOnly ? Colors.white : Colors.white70,
              ),
              tooltip: _showFriendsOnly ? 'Show All' : 'Friends Only',
              onPressed: () {
                setState(() {
                  _showFriendsOnly = !_showFriendsOnly;
                });
              },
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<Post>>(
        stream: postsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      widget.feedType == FeedType.brand
                          ? Icons.business
                          : (widget.feedType == FeedType.product ? Icons.shopping_bag : Icons.label),
                      size: 80,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _showFriendsOnly
                          ? 'No posts from friends for "${widget.query}".'
                          : 'No posts found for "${widget.query}".',
                      style: const TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _showFriendsOnly
                          ? 'Your friends haven\'t posted about this ${getFeedTypeString()} yet!'
                          : 'Be the first to post about this ${getFeedTypeString()}!',
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          final List<Post> posts = snapshot.data!;
          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final Post post = posts[index];
              return PostCard(post: post);
            },
          );
        },
      ),
    );
  }
}