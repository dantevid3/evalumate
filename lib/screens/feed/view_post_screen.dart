// lib/screens/feed/view_post_screen.dart

import 'package:flutter/material.dart';
import 'package:evalumate/models/post.dart';
import 'package:evalumate/models/comment.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:evalumate/services/database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:evalumate/models/profile.dart'; // Ensure this import is present!

// Assuming these exist or will be created for brand/product tap functionality
import 'package:evalumate/screens/inapp/brand_product_category_feed_screen.dart';
import 'package:evalumate/utils/feed_type.dart'; // Assuming you have an enum for FeedType

class ViewPostScreen extends StatefulWidget {
  final Post post;

  const ViewPostScreen({super.key, required this.post});

  @override
  State<ViewPostScreen> createState() => _ViewPostScreenState();
}

class _ViewPostScreenState extends State<ViewPostScreen> {
  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
  final TextEditingController _commentController = TextEditingController();

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty || currentUserId == null) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to comment.')),
      );
      return;
    }

    try {
      final Profile? userProfile = await DatabaseService(uid: user.uid).userData.first;

      if (userProfile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not retrieve user profile to comment.')),
        );
        return;
      }

      await DatabaseService().addComment(
        postId: widget.post.postId,
        uid: currentUserId!,
        text: _commentController.text.trim(),
        userName: userProfile.userName,
        userProfilePicUrl: userProfile.userProfilePicUrl,
      );
      _commentController.clear();
    } catch (e) {
      print('Error adding comment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add comment: ${e.toString()}')),
      );
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.post.userDisplayName ?? widget.post.userName),
        backgroundColor: Colors.green[300],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Info Section
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: widget.post.userProfilePicUrl != null && widget.post.userProfilePicUrl!.isNotEmpty
                        ? NetworkImage(widget.post.userProfilePicUrl!)
                        : null,
                    child: widget.post.userProfilePicUrl == null || widget.post.userProfilePicUrl!.isEmpty
                        ? Icon(Icons.person, color: Colors.grey[600])
                        : null,
                  ),
                  const SizedBox(width: 12.0),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.post.userDisplayName ?? widget.post.userName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0),
                      ),
                      Text(
                        '@${widget.post.userName}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14.0),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    _formatTimestamp(widget.post.createdAt),
                    style: TextStyle(color: Colors.grey[500], fontSize: 12.0),
                  ),
                ],
              ),
            ),

            // Media Section
            if (widget.post.mediaUrl.isNotEmpty)
              AspectRatio(
                aspectRatio: widget.post.aspectRatio,
                child: widget.post.mediaType == 'image'
                    ? Image.network(
                  widget.post.mediaUrl,
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
                  const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey)),
                )
                    : Container(
                  color: Colors.black,
                  child: const Center(
                    child: Icon(Icons.videocam, color: Colors.white, size: 80),
                  ),
                ),
              ),
            const SizedBox(height: 12.0),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Caption
                  if (widget.post.caption != null && widget.post.caption!.isNotEmpty)
                    Text(
                      widget.post.caption!,
                      style: const TextStyle(fontSize: 16.0),
                    ),
                  if (widget.post.caption != null && widget.post.caption!.isNotEmpty) const SizedBox(height: 12.0),

                  // Brand and Product display with tap functionality
                  if (widget.post.brand != null && widget.post.brand!.isNotEmpty)
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BrandProductCategoryFeedScreen(
                              query: widget.post.brand!,
                              feedType: FeedType.brand,
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Row(
                          children: [
                            const Icon(Icons.business_center, size: 18, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(
                              'Brand: ${widget.post.brand!}',
                              style: TextStyle(fontSize: 15.0, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (widget.post.product != null && widget.post.product!.isNotEmpty)
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BrandProductCategoryFeedScreen(
                              query: widget.post.product!,
                              feedType: FeedType.product,
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Row(
                          children: [
                            const Icon(Icons.shopping_bag, size: 18, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(
                              'Product: ${widget.post.product!}',
                              style: TextStyle(fontSize: 15.0, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Rating
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'Rating: ${widget.post.rating}%',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12.0),

                  // Website Link
                  if (widget.post.websiteLink != null && widget.post.websiteLink!.isNotEmpty)
                    InkWell(
                      onTap: () {
                        print('Website link tapped: ${widget.post.websiteLink}');
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Website link functionality coming soon!')),
                        );
                      },
                      child: Text(
                        widget.post.websiteLink!,
                        style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline, fontSize: 15.0),
                      ),
                    ),
                  if (widget.post.websiteLink != null && widget.post.websiteLink!.isNotEmpty) const SizedBox(height: 12.0),

                  // Likes and Comments Section (Comments count removed)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (currentUserId != null)
                        StreamBuilder<bool>(
                          stream: DatabaseService().hasLikedPost(widget.post.postId, currentUserId!),
                          builder: (context, snapshot) {
                            bool hasLiked = snapshot.data ?? false;
                            return Row(
                              children: [
                                IconButton(
                                  icon: Icon(
                                    hasLiked ? Icons.favorite : Icons.favorite_border,
                                    color: hasLiked ? Colors.red : Colors.grey[600],
                                    size: 24,
                                  ),
                                  onPressed: () {
                                    DatabaseService().toggleLikePost(widget.post.postId, currentUserId!);
                                  },
                                ),
                                Text('${widget.post.likesCount} Likes'), // Use post.likes.length
                              ],
                            );
                          },
                        )
                      else // If not logged in, just show heart icon and likes count
                        Row(
                          children: [
                            const Icon(Icons.favorite_border, size: 24, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text('${widget.post.likesCount} Likes'), // Use post.likes.length
                          ],
                        ),
                      // Removed: commentsCount display
                      IconButton(
                        icon: const Icon(Icons.share, size: 24, color: Colors.grey),
                        onPressed: () {
                          print('Share tapped for post: ${widget.post.postId}');
                        },
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 8.0),
                  const Text('Comments:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8.0),

                  // Comments List
                  StreamBuilder<List<Comment>>(
                    stream: DatabaseService().getCommentsForPost(widget.post.postId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error loading comments: ${snapshot.error}'));
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(child: Text('No comments yet.'));
                      }
                      final comments = snapshot.data!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: comments.map((comment) {
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: comment.userProfilePicUrl != null && comment.userProfilePicUrl!.isNotEmpty
                                  ? NetworkImage(comment.userProfilePicUrl!)
                                  : null,
                              child: comment.userProfilePicUrl == null || comment.userProfilePicUrl!.isEmpty
                                  ? const Icon(Icons.person)
                                  : null,
                            ),
                            title: Text(comment.userName),
                            subtitle: Text(comment.text),
                          );
                        }).toList(),
                      );
                    },
                  ),
                  // Add Comment Input
                  if (currentUserId != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _commentController,
                              decoration: const InputDecoration(
                                hintText: 'Add a comment...',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.send),
                            onPressed: _addComment,
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16.0),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A';
    final DateTime dateTime = timestamp.toDate();
    final Duration difference = DateTime.now().difference(dateTime);

    if (difference.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}