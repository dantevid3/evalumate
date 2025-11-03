// // lib/screens/feed/post_card.dart
// import 'package:flutter/material.dart';
// import 'package:evalumate/models/post.dart';
// import 'package:cloud_firestore/cloud_firestore.dart'; // For Timestamp formatting
// import 'package:evalumate/screens/feed/view_post_screen.dart'; // To navigate to full post detail
//
// class PostCard extends StatelessWidget {
//   final Post post;
//
//   const PostCard({
//     super.key,
//     required this.post,
//   });
//
//   // Helper function to format timestamp (can be a utility function elsewhere too)
//   String _formatTimestamp(Timestamp? timestamp) {
//     if (timestamp == null) return 'N/A';
//     final DateTime dateTime = timestamp.toDate();
//     final Duration difference = DateTime.now().difference(dateTime);
//
//     if (difference.inDays > 7) {
//       return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
//     } else if (difference.inDays > 0) {
//       return '${difference.inDays}d ago';
//     } else if (difference.inHours > 0) {
//       return '${difference.inHours}h ago';
//     } else if (difference.inMinutes > 0) {
//       return '${difference.inMinutes}m ago';
//     } else {
//       return 'Just now';
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
//       elevation: 4.0,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
//       child: InkWell( // Make the entire card tappable
//         onTap: () {
//           // Navigate to the full ViewPostScreen when the card is tapped
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (context) => ViewPostScreen(post: post),
//             ),
//           );
//         },
//         child: Padding(
//           padding: const EdgeInsets.all(12.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // User Info Section
//               Row(
//                 children: [
//                   CircleAvatar(
//                     radius: 20,
//                     backgroundColor: Colors.grey[200],
//                     backgroundImage: post.userProfilePicUrl != null && post.userProfilePicUrl!.isNotEmpty
//                         ? NetworkImage(post.userProfilePicUrl!)
//                         : null,
//                     child: post.userProfilePicUrl == null || post.userProfilePicUrl!.isEmpty
//                         ? Icon(Icons.person, color: Colors.grey[600])
//                         : null,
//                   ),
//                   const SizedBox(width: 10.0),
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         post.userDisplayName ?? post.userName,
//                         style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
//                       ),
//                       Text(
//                         '@${post.userName}',
//                         style: TextStyle(color: Colors.grey[600], fontSize: 13.0),
//                       ),
//                     ],
//                   ),
//                   const Spacer(),
//                   Text(
//                     _formatTimestamp(post.createdAt),
//                     style: TextStyle(color: Colors.grey[500], fontSize: 12.0),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 12.0),
//
//               // Brand and Product Section
//               if (post.brand != null && post.brand!.isNotEmpty)
//                 Padding(
//                   padding: const EdgeInsets.only(bottom: 4.0),
//                   child: Text(
//                     'Brand: ${post.brand!}',
//                     style: TextStyle(
//                       fontSize: 14.0,
//                       color: Colors.grey[700],
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                 ),
//               if (post.product != null && post.product!.isNotEmpty)
//                 Padding(
//                   padding: const EdgeInsets.only(bottom: 8.0),
//                   child: Text(
//                     'Product: ${post.product!}',
//                     style: const TextStyle(
//                       fontSize: 14.0,
//                       color: Colors.black87,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                 ),
//
//               // Media Section
//               if (post.mediaUrl.isNotEmpty)
//                 ClipRRect(
//                   borderRadius: BorderRadius.circular(8.0),
//                   child: AspectRatio(
//                     aspectRatio: post.aspectRatio,
//                     child: post.mediaType == 'image'
//                         ? Image.network(
//                       post.mediaUrl,
//                       fit: BoxFit.cover,
//                       loadingBuilder: (context, child, loadingProgress) {
//                         if (loadingProgress == null) return child;
//                         return Center(
//                           child: CircularProgressIndicator(
//                             value: loadingProgress.expectedTotalBytes != null
//                                 ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
//                                 : null,
//                           ),
//                         );
//                       },
//                       errorBuilder: (context, error, stackTrace) =>
//                       const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey)),
//                     )
//                         : Container(
//                       color: Colors.black,
//                       child: const Center(
//                         child: Icon(Icons.videocam, color: Colors.white, size: 60),
//                       ),
//                     ),
//                   ),
//                 ),
//               const SizedBox(height: 12.0),
//
//               // Caption
//               if (post.caption != null && post.caption!.isNotEmpty)
//                 Text(
//                   post.caption!,
//                   style: const TextStyle(fontSize: 15.0),
//                   maxLines: 3, // Limit lines to avoid excessively long cards
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               if (post.caption != null && post.caption!.isNotEmpty) const SizedBox(height: 8.0),
//
//               // Rating
//               Row(
//                 children: [
//                   const Icon(Icons.star, color: Colors.amber, size: 20),
//                   const SizedBox(width: 6),
//                   Text(
//                     '${post.rating}%',
//                     style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 8.0),
//
//               // Website Link (optional, only show if present and not empty)
//               if (post.websiteLink != null && post.websiteLink!.isNotEmpty)
//                 InkWell(
//                   onTap: () {
//                     // TODO: Implement URL launching using url_launcher package
//                     // launchUrl(Uri.parse(post.websiteLink!));
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       const SnackBar(content: Text('Website link functionality coming soon!')),
//                     );
//                   },
//                   child: Text(
//                     post.websiteLink!,
//                     style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline, fontSize: 14.0),
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 ),
//               if (post.websiteLink != null && post.websiteLink!.isNotEmpty) const SizedBox(height: 8.0),
//
//               // Only the Share icon, as likes/comments count are not available
//               Align(
//                 alignment: Alignment.centerRight, // Align to the right
//                 child: Icon(Icons.share, size: 22, color: Colors.grey[600]), // Share icon
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }



// lib/screens/feed/post_card.dart

import 'package:flutter/material.dart';
import 'package:evalumate/models/post.dart';
import 'package:evalumate/models/profile.dart';
import 'package:evalumate/services/database.dart';
import 'package:evalumate/screens/feed/view_post_screen.dart';
import 'package:evalumate/screens/profile/user_profile_screen.dart';
import 'package:evalumate/screens/inapp/brand_product_category_feed_screen.dart';
import 'package:evalumate/utils/feed_type.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PostCard extends StatelessWidget {
  final Post post;

  const PostCard({super.key, required this.post});

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

  Future<void> _navigateToProfile(BuildContext context) async {
    try {
      final userDoc = await DatabaseService().profileCollection.doc(post.uid).get();
      if (userDoc.exists) {
        final profile = Profile.fromFirestore(userDoc);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserProfileScreen(profile: profile),
          ),
        );
      }
    } catch (e) {
      print('Error navigating to profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not load user profile')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Header
          InkWell(
            onTap: () => _navigateToProfile(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: post.userProfilePicUrl != null && post.userProfilePicUrl!.isNotEmpty
                        ? NetworkImage(post.userProfilePicUrl!)
                        : null,
                    child: post.userProfilePicUrl == null || post.userProfilePicUrl!.isEmpty
                        ? Icon(Icons.person, color: Colors.grey[600], size: 20)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.userDisplayName ?? post.userName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          '@${post.userName}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _formatTimestamp(post.createdAt),
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Brand and Product Chips
          if ((post.brand != null && post.brand!.isNotEmpty) ||
              (post.product != null && post.product!.isNotEmpty))
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (post.brand != null && post.brand!.isNotEmpty)
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BrandProductCategoryFeedScreen(
                              query: post.brand!,
                              feedType: FeedType.brand,
                            ),
                          ),
                        );
                      },
                      child: Chip(
                        avatar: Icon(Icons.business, size: 16, color: Colors.blue[700]),
                        label: Text(
                          post.brand!,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                        backgroundColor: Colors.blue[50],
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  if (post.product != null && post.product!.isNotEmpty)
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BrandProductCategoryFeedScreen(
                              query: post.product!,
                              feedType: FeedType.product,
                            ),
                          ),
                        );
                      },
                      child: Chip(
                        avatar: Icon(Icons.shopping_bag, size: 16, color: Colors.green[700]),
                        label: Text(
                          post.product!,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                        backgroundColor: Colors.green[50],
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                ],
              ),
            ),

          if ((post.brand != null && post.brand!.isNotEmpty) ||
              (post.product != null && post.product!.isNotEmpty))
            const SizedBox(height: 12),

          // Image
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ViewPostScreen(post: post),
                ),
              );
            },
            child: AspectRatio(
              aspectRatio: post.aspectRatio,
              child: post.mediaUrl.isNotEmpty
                  ? post.mediaType == 'image'
                  ? Image.network(
                post.mediaUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.grey[100],
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
                    ),
                  );
                },
              )
                  : Container(
                color: Colors.black,
                child: const Center(
                  child: Icon(Icons.play_circle_outline, color: Colors.white, size: 60),
                ),
              )
                  : Container(
                color: Colors.grey[200],
                child: const Center(
                  child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                ),
              ),
            ),
          ),

          // Caption
          if (post.caption != null && post.caption!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Text(
                post.caption!,
                style: const TextStyle(fontSize: 14, height: 1.4),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),


          // Rating (Full-width gradient bar)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getRatingColor(post.rating).withOpacity(0.2),
                  _getRatingColor(post.rating).withOpacity(0.1),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              border: Border(
                top: BorderSide(color: Colors.grey[200]!),
                bottom: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star, color: _getRatingColor(post.rating), size: 22),
                const SizedBox(width: 8),
                Text(
                  '${post.rating}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: _getRatingColor(post.rating),
                  ),
                ),
              ],
            ),
          ),
          // Divider
          Divider(height: 1, color: Colors.grey[200]),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                if (currentUserId != null)
                  StreamBuilder<bool>(
                    stream: DatabaseService().hasLikedPost(post.postId, currentUserId),
                    builder: (context, snapshot) {
                      bool hasLiked = snapshot.data ?? false;
                      return TextButton.icon(
                        onPressed: () {
                          DatabaseService().toggleLikePost(post.postId, currentUserId);
                        },
                        icon: Icon(
                          hasLiked ? Icons.favorite : Icons.favorite_border,
                          color: hasLiked ? Colors.red : Colors.grey[600],
                          size: 20,
                        ),
                        label: Text(
                          '${post.likesCount}',
                          style: TextStyle(
                            color: hasLiked ? Colors.red : Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    },
                  )
                else
                  TextButton.icon(
                    onPressed: null,
                    icon: Icon(Icons.favorite_border, size: 20, color: Colors.grey[600]),
                    label: Text(
                      '${post.likesCount}',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ViewPostScreen(post: post),
                      ),
                    );
                  },
                  icon: Icon(Icons.comment_outlined, size: 20, color: Colors.grey[600]),
                  label: Text(
                    '${post.commentsCount}',
                    style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.share_outlined, size: 20, color: Colors.grey[600]),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Share functionality coming soon!')),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Color _getRatingColor(int rating) {
    if (rating >= 80) {
      return Colors.amber.shade600;
    } else if (rating >= 60) {
      return Colors.amber.shade300;
    } else if (rating >= 40) {
      return Colors.orange.shade200;
    } else if (rating >= 20) {
      return Colors.grey.shade500;
    } else {
      return Colors.grey.shade400;
    }
  }
}