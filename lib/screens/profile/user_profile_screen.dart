
import 'package:evalumate/screens/feed/view_post_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:evalumate/models/profile.dart';
import 'package:evalumate/models/post.dart';
import 'package:evalumate/services/database.dart';
import 'package:evalumate/screens/home/profilepicture.dart';

class UserProfileScreen extends StatefulWidget {
  final Profile profile;

  const UserProfileScreen({super.key, required this.profile});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;

  // Filter state
  String? _activeFilterType; // 'brand', 'category', 'product', or null
  String? _filterQuery; // The actual search term
  bool _showSearchBar = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _activateFilter(String filterType) {
    setState(() {
      if (_activeFilterType == filterType && _showSearchBar) {
        // If clicking the same button while search is open, close it
        _showSearchBar = false;
        _searchController.clear();
      } else {
        // Open search bar for this filter type
        _activeFilterType = filterType;
        _showSearchBar = true;
        _searchController.clear();
        _filterQuery = null;
      }
    });
  }

  void _applyFilter() {
    if (_searchController.text.trim().isNotEmpty) {
      setState(() {
        _filterQuery = _searchController.text.trim();
        _showSearchBar = false;
      });
    }
  }

  void _clearFilter() {
    setState(() {
      _activeFilterType = null;
      _filterQuery = null;
      _showSearchBar = false;
      _searchController.clear();
    });
  }

  Stream<List<Post>> _getFilteredPosts() {
    if (_filterQuery == null || _activeFilterType == null) {
      // No filter, show all user posts
      return DatabaseService().getUserPosts(widget.profile.uid);
    }

    // Get all user posts and filter them
    return DatabaseService().getUserPosts(widget.profile.uid).map((posts) {
      return posts.where((post) {
        if (_activeFilterType == 'brand') {
          return post.brand?.toLowerCase() == _filterQuery!.toLowerCase();
        } else if (_activeFilterType == 'category') {
          return post.categories?.any((cat) =>
          cat.toLowerCase() == _filterQuery!.toLowerCase()) ?? false;
        } else if (_activeFilterType == 'product') {
          return post.product?.toLowerCase() == _filterQuery!.toLowerCase();
        }
        return true;
      }).toList();
    });
  }

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
    final bool isCurrentUserProfile = _currentUserId == widget.profile.uid;

    return Scaffold(
      backgroundColor: Colors.green[100],
      appBar: AppBar(
        backgroundColor: Colors.green[300],
        elevation: 0.0,
        title: Text(widget.profile.displayName ?? widget.profile.userName),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Info Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: StreamBuilder<Profile?>(
              stream: DatabaseService(uid: widget.profile.uid).userData,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                }
                if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          ProfilePicture(
                            uid: widget.profile.uid,
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
                        widget.profile.userName,
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ProfilePicture(
                          uid: profile.uid,
                          size: 110,
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _profileStatColumn('Posts', profile.numberOfPosts),
                                  _profileStatColumn('Followers', profile.numberOfFollowers),
                                  _profileStatColumn('Following', profile.numberOfFollowing),
                                ],
                              ),
                              if (!isCurrentUserProfile && _currentUserId != null)
                                const SizedBox(height: 16),
                              if (!isCurrentUserProfile && _currentUserId != null)
                                StreamBuilder<bool>(
                                  stream: DatabaseService().isFollowing(_currentUserId, profile.uid),
                                  builder: (context, followingSnapshot) {
                                    final bool isFollowing = followingSnapshot.data ?? false;

                                    return StreamBuilder<bool>(
                                      stream: DatabaseService().hasFollowRequestPending(_currentUserId, profile.uid),
                                      builder: (context, pendingSnapshot) {
                                        final bool isPending = pendingSnapshot.data ?? false;

                                        String buttonText;
                                        Color buttonColor;

                                        if (isFollowing) {
                                          buttonText = 'Following';
                                          buttonColor = Colors.grey[400]!;
                                        } else if (isPending) {
                                          buttonText = 'Requested';
                                          buttonColor = Colors.orange[400]!;
                                        } else {
                                          buttonText = 'Follow';
                                          buttonColor = Colors.green[600]!;
                                        }

                                        return ElevatedButton(
                                          onPressed: () async {
                                            try {
                                              if (isFollowing) {
                                                // Unfollow
                                                await DatabaseService().unfollowUser(_currentUserId, profile.uid);
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('Unfollowed ${profile.userName}')),
                                                );
                                              } else if (isPending) {
                                                // Cancel request - you could implement this
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('Request already pending')),
                                                );
                                              } else {
                                                // Check if account is private
                                                if (profile.isPrivate == true) {
                                                  // Send follow request
                                                  final currentUserDoc = await DatabaseService().profileCollection.doc(_currentUserId).get();
                                                  final currentUserData = currentUserDoc.data() as Map<String, dynamic>?;

                                                  await DatabaseService().sendFollowRequest(
                                                    _currentUserId,
                                                    profile.uid,
                                                    currentUserData?['userName'] ?? 'User',
                                                    currentUserData?['userProfilePicUrl'],
                                                  );

                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(content: Text('Follow request sent to ${profile.userName}')),
                                                  );
                                                } else {
                                                  // Follow directly
                                                  await DatabaseService().followUser(_currentUserId, profile.uid);
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(content: Text('Following ${profile.userName}')),
                                                  );
                                                }
                                              }
                                            } catch (e) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('Action failed: ${e.toString()}')),
                                              );
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: buttonColor,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                                          ),
                                          child: Text(buttonText),
                                        );
                                      },
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      profile.userName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (profile.bio != null && profile.bio!.isNotEmpty)
                      Text(
                        profile.bio!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    const SizedBox(height: 12),

                    // Filter Buttons or Search Bar
                    if (!_showSearchBar) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _filterButton('Brands', Icons.business, 'brand'),
                          _filterButton('Categories', Icons.category, 'category'),
                          _filterButton('Products', Icons.shopping_bag, 'product'),
                        ],
                      ),
                    ] else ...[
                      // Inline Search Bar
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              autofocus: true,
                              decoration: InputDecoration(
                                hintText: 'Search ${_activeFilterType}...',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    setState(() {
                                      _showSearchBar = false;
                                      _searchController.clear();
                                    });
                                  },
                                ),
                              ),
                              onSubmitted: (_) => _applyFilter(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _applyFilter,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[600],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            child: const Icon(Icons.search),
                          ),
                        ],
                      ),
                    ],

                    // Active filter indicator
                    if (_filterQuery != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green[200],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.filter_list, size: 16, color: Colors.green[800]),
                            const SizedBox(width: 4),
                            Text(
                              '${_activeFilterType![0].toUpperCase()}${_activeFilterType!.substring(1)}: $_filterQuery',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green[800],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: _clearFilter,
                              child: Icon(Icons.close, size: 16, color: Colors.green[800]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),

          // User Posts Grid Section
          // User Posts Grid Section (for the viewed user) with White Background
          Expanded(
            child: Container(
              color: Colors.white,
              child: StreamBuilder<Profile?>(
                stream: DatabaseService(uid: widget.profile.uid).userData,
                builder: (context, profileSnapshot) {
                  // Get the profile data
                  final profile = profileSnapshot.data ?? widget.profile;

                  return StreamBuilder<bool>(
                    // Check if current user is following the profile owner
                    stream: _currentUserId != null && !isCurrentUserProfile
                        ? DatabaseService().isFollowing(_currentUserId, widget.profile.uid)
                        : Stream.value(true), // Show posts if viewing own profile
                    builder: (context, followingSnapshot) {
                      final bool isFollowing = followingSnapshot.data ?? false;
                      final bool canViewPosts = isCurrentUserProfile || !(profile.isPrivate ?? false) || isFollowing;

                      if (!canViewPosts) {
                        // Private account and not following
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.lock, size: 80, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'This Account is Private',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Follow this account to see their posts',
                                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      }

                      // Can view posts - show the grid
                      return StreamBuilder<List<Post>>(
                        stream: _getFilteredPosts(),
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
                            return Center(
                              child: Text(
                                _filterQuery != null
                                    ? 'No posts found for ${_activeFilterType}: $_filterQuery'
                                    : 'No posts created yet by this user.',
                              ),
                            );
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
                                                ? loadingProgress.cumulativeBytesLoaded /
                                                loadingProgress.expectedTotalBytes!
                                                : null,
                                          ),
                                        );
                                      },
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          color: Colors.grey[300],
                                          child: const Icon(Icons.broken_image, color: Colors.grey),
                                        );
                                      },
                                    )
                                        : Container(
                                      color: Colors.black,
                                      child: const Icon(Icons.play_circle_outline, color: Colors.white, size: 40),
                                    )
                                        : Container(
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.image_not_supported, color: Colors.grey),
                                    ),
                                  ),
                                );
                              },
                            );
                          }
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterButton(String label, IconData icon, String filterType) {
    final bool isActive = _activeFilterType == filterType && _filterQuery != null;

    return ElevatedButton.icon(
      onPressed: () => _activateFilter(filterType),
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive ? Colors.green[600] : Colors.green[300],
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}