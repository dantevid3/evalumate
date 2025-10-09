import 'package:flutter/material.dart';
import 'package:evalumate/services/database.dart';

class ChangeBioScreen extends StatefulWidget {
  final String uid;
  final String? currentBio;
  const ChangeBioScreen({super.key, required this.uid, this.currentBio});

  @override
  State<ChangeBioScreen> createState() => _ChangeBioScreenState();
}

class _ChangeBioScreenState extends State<ChangeBioScreen> {
  final _bioController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _bioController.text = widget.currentBio ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Bio'),
        backgroundColor: Colors.green[300],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              controller: _bioController,
              maxLines: 4,
              maxLength: 150,
              decoration: const InputDecoration(
                labelText: 'Bio',
                border: OutlineInputBorder(),
                hintText: 'Tell people about yourself...',
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateBio,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[300],
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Update Bio'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateBio() async {
    setState(() => _isLoading = true);

    try {
      await DatabaseService(uid: widget.uid).updateUserData(
        bio: _bioController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bio updated successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }
}