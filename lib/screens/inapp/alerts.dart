// lib/screens/inapp/alerts.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:evalumate/models/notification.dart';
import 'package:evalumate/services/database.dart';
import 'package:evalumate/screens/profile/user_profile_screen.dart';
import 'package:evalumate/screens/feed/view_post_screen.dart';
import 'package:evalumate/models/profile.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:evalumate/models/post.dart';

class Alerts extends StatefulWidget {
  const Alerts({super.key});

  @override
  State<Alerts> createState() => _AlertsState();
}

class _AlertsState extends State<Alerts> {
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view notifications')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.green[300],
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Mark all as read',
            onPressed: () async {
              await DatabaseService().markAllNotificationsAsRead(_currentUserId);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All notifications marked as read')),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<AppNotification>>(
        stream: DatabaseService().getUserNotifications(_currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          final notifications = snapshot.data!;

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _buildNotificationTile(notification);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationTile(AppNotification notification) {
    IconData icon;
    Color iconColor;
    String message;
    switch (notification.type) {
      case 'follow':
        icon = Icons.person_add;
        iconColor = Colors.blue;
        message = '${notification.fromUserName} started following you';
        break;
      case 'follow_accepted':  // ADD THIS CASE
        icon = Icons.check_circle;
        iconColor = Colors.green;
        message = '${notification.fromUserName} accepted your follow request';
        break;
      case 'like':
        icon = Icons.favorite;
        iconColor = Colors.red;
        message = '${notification.fromUserName} liked your post';
        break;
      case 'comment':
        icon = Icons.comment;
        iconColor = Colors.green;
        message = '${notification.fromUserName} commented: "${notification.commentText}"';
        break;
      case 'follow_request':
        icon = Icons.person_add_outlined;
        iconColor = Colors.orange;
        message = '${notification.fromUserName} requested to follow you';
        break;
      default:
        icon = Icons.notifications;
        iconColor = Colors.grey;
        message = 'New notification';
    }

    return Container(
      color: notification.isRead ? Colors.white : Colors.green[50],
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.1),
          child: notification.fromUserProfilePic != null && notification.fromUserProfilePic!.isNotEmpty
              ? ClipOval(
            child: Image.network(
              notification.fromUserProfilePic!,
              fit: BoxFit.cover,
              width: 40,
              height: 40,
              errorBuilder: (context, error, stackTrace) {
                return Icon(icon, color: iconColor);
              },
            ),
          )
              : Icon(icon, color: iconColor),
        ),
        title: Text(
          message,
          style: TextStyle(
            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          timeago.format(notification.createdAt),
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        trailing: notification.type == 'like' || notification.type == 'comment'
            ? (notification.postImageUrl != null && notification.postImageUrl!.isNotEmpty
            ? ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Image.network(
            notification.postImageUrl!,
            width: 50,
            height: 50,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 50,
                height: 50,
                color: Colors.grey[300],
                child: const Icon(Icons.image_not_supported),
              );
            },
          ),
        )
            : null)
            : notification.type == 'follow_request'
            ? _buildFollowRequestButtons(notification)
            : null,
        onTap: () => _handleNotificationTap(notification),
      ),
    );
  }

  Widget _buildFollowRequestButtons(AppNotification notification) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.check, color: Colors.green),
          onPressed: () async {
            try {
              await DatabaseService().acceptFollowRequest(_currentUserId!, notification.fromUserId);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Accepted follow request from ${notification.fromUserName}')),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: ${e.toString()}')),
              );
            }
          },
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.red),
          onPressed: () async {
            try {
              await DatabaseService().rejectFollowRequest(_currentUserId!, notification.fromUserId);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Rejected follow request from ${notification.fromUserName}')),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: ${e.toString()}')),
              );
            }
          },
        ),
      ],
    );
  }

  Future<void> _handleNotificationTap(AppNotification notification) async {
    // Mark as read
    if (!notification.isRead) {
      await DatabaseService().markNotificationAsRead(notification.id);
    }
    // Navigate based on type
    if (notification.type == 'follow' || notification.type == 'follow_request' || notification.type == 'follow_accepted') {  // ADDED follow_accepted
      // Navigate to user profile
      final userDoc = await DatabaseService().profileCollection.doc(notification.fromUserId).get();
      if (userDoc.exists) {
        final profile = Profile.fromFirestore(userDoc);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserProfileScreen(profile: profile),
          ),
        );
      }
    } else if ((notification.type == 'like' || notification.type == 'comment') && notification.postId != null) {
      // Navigate to post
      final postDoc = await DatabaseService().postsCollection.doc(notification.postId).get();
      if (postDoc.exists) {
        final post = Post.fromFirestore(postDoc);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ViewPostScreen(post: post),
          ),
        );
      }
    }
  }
}