import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:evalumate/services/database.dart'; // Import your DatabaseService
import 'package:firebase_auth/firebase_auth.dart'; // To get current user UID
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePicture extends StatefulWidget {
  final String uid;
  final double size;

  const ProfilePicture({
    super.key,
    required this.uid,
    this.size = 110.0, // Default size if not provided
  });

  @override
  State<ProfilePicture> createState() => _ProfilePictureState();
}

class _ProfilePictureState extends State<ProfilePicture> {
  Future<String?>? _profileImageUrlFuture;

  @override
  void initState() {
    super.initState();
    _profileImageUrlFuture = _getProfileImageUrl();
  }

  Future<String?> _getProfileImageUrl() async {
    try {
      final storageRef = FirebaseStorage.instance.ref();
      final imageRef = storageRef.child('profile_${widget.uid}.jpg');
      return await imageRef.getDownloadURL();
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') {
        print('No profile picture found for user ${widget.uid}');
        return null;
      } else {
        print('Error getting profile picture URL: $e');
        return null;
      }
    } catch (e) {
      print('Unexpected error getting profile picture URL: $e');
      return null;
    }
  }

  Future<void> onProfileTapped() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image == null) return; // User cancelled picking

      final Uint8List imageBytes = await image.readAsBytes();

      final storageRef = FirebaseStorage.instance.ref();
      final imageRef = storageRef.child('profile_${widget.uid}.jpg');
      await imageRef.putData(imageBytes); // Upload new image to Firebase Storage

      // Get the download URL for the newly uploaded image
      final String downloadUrl = await imageRef.getDownloadURL();

      // --- CRUCIAL STEP: Update the user's profile document in Firestore ---
      // This saves the profile picture URL directly in their profile document,
      // making it accessible for denormalization in posts, comments, etc.
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null && currentUser.uid == widget.uid) { // Ensure current user is modifying their own profile
        final DatabaseService dbService = DatabaseService(uid: widget.uid);

        // Fetch current profile data to ensure other fields are preserved
        // Use .first to get a single snapshot, not a continuous stream
        final currentProfile = await dbService.userData.first;

        if (currentProfile != null) {
          await dbService.updateUserData(
            userName: currentProfile.userName,
            phoneNumber: currentProfile.phoneNumber,
            displayName: currentProfile.displayName,
            email: currentProfile.email,
            bio: currentProfile.bio,
            website: currentProfile.website,
            isPrivate: currentProfile.isPrivate,
            numberOfPosts: currentProfile.numberOfPosts,
            numberOfFollowers: currentProfile.numberOfFollowers,
            numberOfFollowing: currentProfile.numberOfFollowing,
            createdAt: currentProfile.createdAt,
            lastActive: FieldValue.serverTimestamp(), // Update last active timestamp
            fcmTokens: currentProfile.fcmTokens,
            isVerified: currentProfile.isVerified,
            settings: currentProfile.settings,
            blockedUsers: currentProfile.blockedUsers,
            userProfilePicUrl: downloadUrl, // <--- SAVE THE NEW URL HERE
          );
        } else {
          // Handle case where profile data might not exist yet (e.g., brand new user)
          print('Warning: User profile data not found when updating profile picture URL.');
          // You might choose to create a minimal profile here if it's missing.
          // Example:
          // await dbService.updateUserData(
          //   userName: 'New User',
          //   phoneNumber: '', // Or a default if applicable
          //   userProfilePicUrl: downloadUrl,
          //   createdAt: FieldValue.serverTimestamp(),
          //   lastActive: FieldValue.serverTimestamp(),
          // );
        }
      }

      setState(() {
        _profileImageUrlFuture = _getProfileImageUrl(); // Refresh the image display
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile picture updated!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile picture: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate the icon size as 75% of the widget.size
    final double iconSize = widget.size * 0.75;

    return GestureDetector(
      onTap: onProfileTapped,
      child: FutureBuilder<String?>(
        future: _profileImageUrlFuture,
        builder: (context, snapshot) {
          BoxDecoration baseDecoration = BoxDecoration(
            color: Colors.grey[200],
            shape: BoxShape.circle,
          );

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              height: widget.size,
              width: widget.size,
              decoration: baseDecoration,
              child: Center( // Center the SizedBox for the indicator
                child: SizedBox( // Use SizedBox to explicitly constrain CircularProgressIndicator size
                  height: iconSize, // Apply calculated size
                  width: iconSize,  // Apply calculated size
                  child: const CircularProgressIndicator(),
                ),
              ),
            );
          } else if (snapshot.hasError) {
            print("FutureBuilder error: ${snapshot.error}");
            return Container(
              height: widget.size,
              width: widget.size,
              decoration: baseDecoration,
              child: Center(
                child: Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: iconSize, // Apply calculated size
                ),
              ),
            );
          } else if (snapshot.hasData && snapshot.data != null) {
            final imageUrl = snapshot.data!;
            return Container(
              height: widget.size,
              width: widget.size,
              decoration: baseDecoration.copyWith(
                image: DecorationImage(
                  fit: BoxFit.cover,
                  image: NetworkImage(imageUrl),
                ),
                border: Border.all(
                  color: Colors.grey[400]!,
                  width: 2.0,
                ),
              ),
            );
          } else {
            return Container(
              height: widget.size,
              width: widget.size,
              decoration: baseDecoration,
              child: Center(
                child: Icon(
                  Icons.person_rounded,
                  color: Colors.black45,
                  size: iconSize, // Apply calculated size
                ),
              ),
            );
          }
        },
      ),
    );
  }
}