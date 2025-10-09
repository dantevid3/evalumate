// lib/screens/inapp/brand_product_category_feed_screen.dart

import 'package:flutter/material.dart';
import 'package:evalumate/models/post.dart';
import 'package:evalumate/services/database.dart';
import 'package:evalumate/screens/feed/post_card.dart'; // Re-use your PostCard widget
import 'package:evalumate/utils/feed_type.dart';

class BrandProductCategoryFeedScreen extends StatelessWidget {
  final String query; // The brand name, product name, or category name
  final FeedType feedType;

  const BrandProductCategoryFeedScreen({
    super.key,
    required this.query,
    required this.feedType,
  });

  @override
  Widget build(BuildContext context) {
    String appBarTitle;
    Stream<List<Post>> postsStream;

    // Determine app bar title and corresponding stream based on feedType
    switch (feedType) {
      case FeedType.brand:
        appBarTitle = 'Brand: $query';
        postsStream = DatabaseService().getPostsByBrand(query);
        break;
      case FeedType.product:
        appBarTitle = 'Product: $query';
        postsStream = DatabaseService().getPostsByProduct(query); // NEW: Get posts by product
        break;
      case FeedType.category:
        appBarTitle = 'Category: $query';
        postsStream = DatabaseService().getPostsByCategory(query);
        break;
      default:
        appBarTitle = 'Feed: $query'; // Fallback
        postsStream = Stream.value([]); // Empty stream for unknown types
        break;
    }

    // Helper to get descriptive text for empty state
    String getFeedTypeString() {
      switch (feedType) {
        case FeedType.brand:
          return 'brand';
        case FeedType.product:
          return 'product'; // NEW: for product
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
                      feedType == FeedType.brand
                          ? Icons.business
                          : (feedType == FeedType.product ? Icons.shopping_bag : Icons.label), // NEW: icon for product
                      size: 80,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'No posts found for "$query".',
                      style: const TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Be the first to post about this ${getFeedTypeString()}!', // Uses helper
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
              return PostCard(post: post); // Display each post using PostCard
            },
          );
        },
      ),
    );
  }
}