// lib/screens/feed/post_card.dart
import 'package:flutter/material.dart';
import 'package:evalumate/models/post.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // For Timestamp formatting
import 'package:evalumate/screens/feed/view_post_screen.dart'; // To navigate to full post detail

class PostCard extends StatelessWidget {
  final Post post;

  const PostCard({
    super.key,
    required this.post,
  });

  // Helper function to format timestamp (can be a utility function elsewhere too)
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

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: InkWell( // Make the entire card tappable
        onTap: () {
          // Navigate to the full ViewPostScreen when the card is tapped
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ViewPostScreen(post: post),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Info Section
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: post.userProfilePicUrl != null && post.userProfilePicUrl!.isNotEmpty
                        ? NetworkImage(post.userProfilePicUrl!)
                        : null,
                    child: post.userProfilePicUrl == null || post.userProfilePicUrl!.isEmpty
                        ? Icon(Icons.person, color: Colors.grey[600])
                        : null,
                  ),
                  const SizedBox(width: 10.0),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.userDisplayName ?? post.userName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
                      ),
                      Text(
                        '@${post.userName}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13.0),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    _formatTimestamp(post.createdAt),
                    style: TextStyle(color: Colors.grey[500], fontSize: 12.0),
                  ),
                ],
              ),
              const SizedBox(height: 12.0),

              // Brand and Product Section
              if (post.brand != null && post.brand!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Text(
                    'Brand: ${post.brand!}',
                    style: TextStyle(
                      fontSize: 14.0,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              if (post.product != null && post.product!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    'Product: ${post.product!}',
                    style: const TextStyle(
                      fontSize: 14.0,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

              // Media Section
              if (post.mediaUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: AspectRatio(
                    aspectRatio: post.aspectRatio,
                    child: post.mediaType == 'image'
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
                      const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey)),
                    )
                        : Container(
                      color: Colors.black,
                      child: const Center(
                        child: Icon(Icons.videocam, color: Colors.white, size: 60),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 12.0),

              // Caption
              if (post.caption != null && post.caption!.isNotEmpty)
                Text(
                  post.caption!,
                  style: const TextStyle(fontSize: 15.0),
                  maxLines: 3, // Limit lines to avoid excessively long cards
                  overflow: TextOverflow.ellipsis,
                ),
              if (post.caption != null && post.caption!.isNotEmpty) const SizedBox(height: 8.0),

              // Rating
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    '${post.rating}%',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),

              // Website Link (optional, only show if present and not empty)
              if (post.websiteLink != null && post.websiteLink!.isNotEmpty)
                InkWell(
                  onTap: () {
                    // TODO: Implement URL launching using url_launcher package
                    // launchUrl(Uri.parse(post.websiteLink!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Website link functionality coming soon!')),
                    );
                  },
                  child: Text(
                    post.websiteLink!,
                    style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline, fontSize: 14.0),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              if (post.websiteLink != null && post.websiteLink!.isNotEmpty) const SizedBox(height: 8.0),

              // Only the Share icon, as likes/comments count are not available
              Align(
                alignment: Alignment.centerRight, // Align to the right
                child: Icon(Icons.share, size: 22, color: Colors.grey[600]), // Share icon
              ),
            ],
          ),
        ),
      ),
    );
  }
}