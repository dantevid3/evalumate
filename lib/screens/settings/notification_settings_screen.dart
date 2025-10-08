import 'package:flutter/material.dart';

class NotificationSettingsScreen extends StatefulWidget {
  final String uid;
  const NotificationSettingsScreen({Key? key, required this.uid}) : super(key: key);

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _likesNotifications = true;
  bool _commentsNotifications = true;
  bool _followersNotifications = true;
  bool _postsNotifications = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        backgroundColor: Colors.green[300],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('Likes'),
              subtitle: const Text('Get notified when someone likes your posts'),
              value: _likesNotifications,
              onChanged: (value) {
                setState(() => _likesNotifications = value);
                _saveNotificationSettings();
              },
            ),
            SwitchListTile(
              title: const Text('Comments'),
              subtitle: const Text('Get notified when someone comments on your posts'),
              value: _commentsNotifications,
              onChanged: (value) {
                setState(() => _commentsNotifications = value);
                _saveNotificationSettings();
              },
            ),
            SwitchListTile(
              title: const Text('New Followers'),
              subtitle: const Text('Get notified when someone follows you'),
              value: _followersNotifications,
              onChanged: (value) {
                setState(() => _followersNotifications = value);
                _saveNotificationSettings();
              },
            ),
            SwitchListTile(
              title: const Text('Posts from Following'),
              subtitle: const Text('Get notified when people you follow post'),
              value: _postsNotifications,
              onChanged: (value) {
                setState(() => _postsNotifications = value);
                _saveNotificationSettings();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _saveNotificationSettings() {
    // Save to SharedPreferences or your database
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notification settings updated')),
    );
  }
}