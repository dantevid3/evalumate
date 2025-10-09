import 'package:flutter/material.dart';
import 'package:evalumate/services/database.dart';

class ChangeWebsiteScreen extends StatefulWidget {
  final String uid;
  final String? currentWebsite;
  const ChangeWebsiteScreen({super.key, required this.uid, this.currentWebsite});

  @override
  State<ChangeWebsiteScreen> createState() => _ChangeWebsiteScreenState();
}

class _ChangeWebsiteScreenState extends State<ChangeWebsiteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _websiteController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _websiteController.text = widget.currentWebsite ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Website'),
        backgroundColor: Colors.green[300],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _websiteController,
                decoration: const InputDecoration(
                  labelText: 'Website URL',
                  border: OutlineInputBorder(),
                  hintText: 'https://example.com',
                ),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (!value.startsWith('http://') && !value.startsWith('https://')) {
                      return 'Please enter a valid URL starting with http:// or https://';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateWebsite,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[300],
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Update Website'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateWebsite() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        await DatabaseService(uid: widget.uid).updateUserData(
          website: _websiteController.text.trim(),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Website updated successfully!')),
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
  }

  @override
  void dispose() {
    _websiteController.dispose();
    super.dispose();
  }
}