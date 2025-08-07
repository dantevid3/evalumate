// lib/screens/feed/edit_post_screen.dart
import 'package:flutter/material.dart';
import 'package:evalumate/models/post.dart';
import 'package:evalumate/models/comment.dart'; // Assuming you have a Comment model
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:evalumate/services/database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:evalumate/models/profile.dart'; // Import your Profile model

class EditPostScreen extends StatefulWidget { // Renamed from EditPostScreen
  final Post post;

  const EditPostScreen({super.key, required this.post});

  @override
  State<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
  final TextEditingController _commentController = TextEditingController();

  // Controllers for editing post details
  late TextEditingController _captionController;
  late TextEditingController _ratingController;
  late TextEditingController _websiteLinkController;
  late TextEditingController _brandController;
  late TextEditingController _productController;

  bool _isEditing = false;
  late double _currentRating; // Use a double to match the slider/input

  @override
  void initState() {
    super.initState();
    _captionController = TextEditingController(text: widget.post.caption);
    _ratingController = TextEditingController(text: widget.post.rating.toString());
    _websiteLinkController = TextEditingController(text: widget.post.websiteLink);
    _brandController = TextEditingController(text: widget.post.brand);
    _productController = TextEditingController(text: widget.post.product);
    _currentRating = widget.post.rating.toDouble();
  }

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

  Future<void> _updatePost() async {
    try {
      int? newRating = int.tryParse(_ratingController.text);
      if (newRating == null || newRating < 0 || newRating > 100) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rating must be an integer between 0 and 100.')),
        );
        return;
      }

      await DatabaseService().updatePost(
        postId: widget.post.postId,
        caption: _captionController.text.trim(),
        rating: newRating,
        websiteLink: _websiteLinkController.text.trim(),
        brand: _brandController.text.trim(),
        product: _productController.text.trim(),
      );
      setState(() {
        _isEditing = false; // Exit editing mode after saving
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post updated successfully!')),
      );
    } catch (e) {
      print('Error updating post: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update post: ${e.toString()}')),
      );
    }
  }

  Future<void> _deletePost() async {
    bool confirmDelete = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text('Are you sure you want to delete this post? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    ) ?? false;

    if (confirmDelete) {
      try {
        await DatabaseService().deletePost(widget.post.postId, widget.post.uid);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post deleted successfully!')),
        );
        Navigator.of(context).pop(); // Go back after deleting
      } catch (e) {
        print('Error deleting post: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete post: ${e.toString()}')),
        );
      }
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _captionController.dispose();
    _ratingController.dispose();
    _websiteLinkController.dispose();
    _brandController.dispose();
    _productController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Check if the current user is the owner of the post
    final bool isPostOwner = currentUserId == widget.post.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.post.userDisplayName ?? widget.post.userName),
        backgroundColor: Colors.green[300],
        actions: [
          if (isPostOwner) // Only show edit/delete if current user owns the post
            IconButton(
              icon: Icon(_isEditing ? Icons.save : Icons.edit),
              onPressed: () {
                if (_isEditing) {
                  _updatePost();
                } else {
                  setState(() {
                    _isEditing = true;
                  });
                }
              },
            ),
          if (isPostOwner)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deletePost,
            ),
        ],
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
                  const Text('Caption:', style: TextStyle(fontWeight: FontWeight.bold)),
                  _isEditing
                      ? TextField(
                    controller: _captionController,
                    decoration: const InputDecoration(
                      hintText: 'Enter caption',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                    ),
                    maxLines: null, // Allow multiple lines
                  )
                      : (widget.post.caption != null && widget.post.caption!.isNotEmpty)
                      ? Text(widget.post.caption!, style: const TextStyle(fontSize: 16.0))
                      : const Text('No caption.'),
                  const SizedBox(height: 12.0),

                  // Rating
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 22),
                      const SizedBox(width: 8),
                      const Text('Rating:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      _isEditing
                          ? Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: Slider(
                                value: _currentRating,
                                min: 0,
                                max: 100,
                                divisions: 100,
                                label: _currentRating.round().toString(),
                                onChanged: (double value) {
                                  setState(() {
                                    _currentRating = value;
                                    _ratingController.text = value.round().toString();
                                  });
                                },
                              ),
                            ),
                            SizedBox(
                              width: 50,
                              child: TextField(
                                controller: _ratingController,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 5, vertical: 0),
                                ),
                                onChanged: (text) {
                                  final value = int.tryParse(text);
                                  if (value != null && value >= 0 && value <= 100) {
                                    setState(() {
                                      _currentRating = value.toDouble();
                                    });
                                  }
                                },
                              ),
                            ),
                            const Text('%'),
                          ],
                        ),
                      )
                          : Text(
                        '${widget.post.rating}%',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12.0),

                  // Website Link
                  const Text('Website Link:', style: TextStyle(fontWeight: FontWeight.bold)),
                  _isEditing
                      ? TextField(
                    controller: _websiteLinkController,
                    decoration: const InputDecoration(
                      hintText: 'Enter website link (optional)',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                    ),
                    keyboardType: TextInputType.url,
                  )
                      : (widget.post.websiteLink != null && widget.post.websiteLink!.isNotEmpty)
                      ? InkWell(
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
                  )
                      : const Text('No website link.'),
                  const SizedBox(height: 12.0),

                  // Brand
                  const Text('Brand:', style: TextStyle(fontWeight: FontWeight.bold)),
                  _isEditing
                      ? TextField(
                    controller: _brandController,
                    decoration: const InputDecoration(
                      hintText: 'Enter brand (optional)',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                    ),
                  )
                      : (widget.post.brand != null && widget.post.brand!.isNotEmpty)
                      ? Text(widget.post.brand!, style: const TextStyle(fontSize: 16.0))
                      : const Text('No brand specified.'),
                  const SizedBox(height: 12.0),

                  // Product
                  const Text('Product:', style: TextStyle(fontWeight: FontWeight.bold)),
                  _isEditing
                      ? TextField(
                    controller: _productController,
                    decoration: const InputDecoration(
                      hintText: 'Enter product (optional)',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                    ),
                  )
                      : (widget.post.product != null && widget.post.product!.isNotEmpty)
                      ? Text(widget.post.product!, style: const TextStyle(fontSize: 16.0))
                      : const Text('No product specified.'),
                  const SizedBox(height: 12.0),

                  // Likes and Share
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
                                Text('${widget.post.likesCount} Likes'),
                              ],
                            );
                          },
                        )
                      else
                        Row(
                          children: [
                            const Icon(Icons.favorite_border, size: 24, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text('${widget.post.likesCount} Likes'),
                          ],
                        ),
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
                            // You might want to add comment timestamp here as well
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
                              textCapitalization: TextCapitalization.sentences,
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