import 'package:flutter/material.dart';
import 'package:evalumate/services/database.dart';
import 'package:evalumate/shared/loading.dart';
import 'package:evalumate/shared/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:evalumate/screens/wrapper.dart';

class ProfileSetupScreen extends StatefulWidget {
  final String uid; // The UID of the newly registered user

  const ProfileSetupScreen({super.key, required this.uid});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  bool loading = false;

  // Text field controllers
  String userName = '';
  String displayName = '';
  String phoneNumber = '';
  String bio = '';
  String error = '';

  @override
  Widget build(BuildContext context) {
    return loading
        ? const Loading()
        : Scaffold(
      backgroundColor: Colors.green[100],
      appBar: AppBar(
        backgroundColor: Colors.green[300],
        elevation: 0.0,
        title: const Text('Set Up Your Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 50.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              const SizedBox(height: 20),
              const Text(
                'Tell us a bit about yourself!',
                style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              TextFormField(
                decoration: textInputDecoration.copyWith(hintText: 'Username (unique)'),
                validator: (val) => val!.isEmpty ? 'Enter a username (unique)' : null,
                onChanged: (val) {
                  setState(() => userName = val.trim());
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                decoration: textInputDecoration.copyWith(hintText: 'Display Name'),
                onChanged: (val) {
                  setState(() => displayName = val.trim());
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                decoration: textInputDecoration.copyWith(hintText: 'Phone Number (unique)'),
                keyboardType: TextInputType.phone,
                validator: (val) => val!.isEmpty ? 'Enter a phone number' : null,
                onChanged: (val) {
                  setState(() => phoneNumber = val.trim());
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                decoration: textInputDecoration.copyWith(hintText: 'Bio (optional)'),
                maxLines: 3,
                onChanged: (val) {
                  setState(() => bio = val.trim());
                },
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[400],
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    setState(() {
                      loading = true;
                      error = '';
                    });

                    try {
                      final databaseService = DatabaseService(uid: widget.uid);

                      // 1. Check if phone number is taken
                      bool phoneNumberExists = await databaseService.isPhoneNumberTaken(phoneNumber);
                      if (phoneNumberExists) {
                        if (!mounted) return;
                        setState(() {
                          loading = false;
                          error = 'This phone number is already associated with another account.';
                        });
                        return; // Stop execution
                      }

                      // 2. Check if username is taken
                      if (userName.isNotEmpty) {
                        bool userNameExists = await databaseService.isUserNameTaken(userName);
                        if (userNameExists) {
                          if (!mounted) return;
                          setState(() {
                            loading = false;
                            error = 'This username is already taken. Please choose another.';
                          });
                          return; // Stop execution
                        }
                      }

                      // 3. Update user data
                      await databaseService.updateUserData(
                        userName: userName,
                        displayName: displayName.isNotEmpty ? displayName : null,
                        phoneNumber: phoneNumber,
                        bio: bio.isNotEmpty ? bio : null,
                        createdAt: FieldValue.serverTimestamp(),
                        numberOfPosts: 0,
                        numberOfFollowers: 0,
                        numberOfFollowing: 0,
                      );

                      if (!mounted) return;

                      // Navigate to the Wrapper screen
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const Wrapper()),
                            (Route<dynamic> route) => false,
                      );
                    } catch (e) {
                      print("Error setting up profile: $e");
                      if (!mounted) return;
                      setState(() {
                        loading = false;
                        error = 'Could not set up profile. An unexpected error occurred.';
                      });
                    }
                  }
                },
                child: const Text(
                  'Complete Profile',
                ),
              ),
              const SizedBox(height: 12),
              Text(
                error,
                style: const TextStyle(color: Colors.red, fontSize: 14),
              )
            ],
          ),
        ),
      ),
    );
  }
}