import 'package:flutter/material.dart';
import 'package:evalumate/services/database.dart';

class PrivacySettingsScreen extends StatefulWidget {
  final String uid;
  const PrivacySettingsScreen({super.key, required this.uid});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  bool _isPrivate = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  Future<void> _loadCurrentSettings() async {
    try {
      final profile = await DatabaseService(uid: widget.uid).userData.first;
      if (profile != null) {
        setState(() {
          _isPrivate = profile.isPrivate;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Settings'),
        backgroundColor: Colors.green[300],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('Private Account'),
              subtitle: const Text('Only approved followers can see your posts'),
              value: _isPrivate,
              onChanged: (value) async {
                setState(() => _isPrivate = value);
                await _updatePrivacySetting(value);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.block),
              title: const Text('Blocked Users'),
              subtitle: const Text('Manage blocked accounts'),
              onTap: () {
                // Navigate to blocked users screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Blocked users feature coming soon!')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updatePrivacySetting(bool isPrivate) async {
    try {
      await DatabaseService(uid: widget.uid).updateUserData(
        isPrivate: isPrivate,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isPrivate
                ? 'Account is now private'
                : 'Account is now public'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
        // Revert the switch
        setState(() => _isPrivate = !isPrivate);
      }
    }
  }
}