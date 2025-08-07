// lib/screens/wrapper.dart

import 'package:evalumate/models/currentuser.dart';
import 'package:evalumate/models/profile.dart'; // Import your Profile model
import 'package:evalumate/screens/authenticate/authenticate.dart';
import 'package:evalumate/screens/authenticate/profile_setup_screen.dart'; // Import ProfileSetupScreen
import 'package:evalumate/screens/browse.dart'; // MultiPageToggler or your main app
import 'package:evalumate/services/database.dart'; // Import DatabaseService
import 'package:evalumate/shared/loading.dart'; // Import Loading screen
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Wrapper extends StatelessWidget {
  const Wrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<CurrentUser?>(context);

    // Return Authenticate if user is not logged in
    if (user == null) {
      return const Authenticate();
    } else {
      // If user is logged in, check if their profile exists
      return StreamBuilder<Profile?>(
        stream: DatabaseService(uid: user.uid).userData, // Listen to user's profile data
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Loading(); // Show loading screen while checking profile
          }
          if (snapshot.hasError) {
            print("Error fetching profile: ${snapshot.error}");
            // Handle error, maybe show a generic error screen or Authenticate
            return const Authenticate();
          }

          final Profile? userProfile = snapshot.data;

          // If profile data is null, it means the profile is not yet set up
          if (userProfile == null) {
            return ProfileSetupScreen(uid: user.uid); // Direct to profile setup
          } else {
            // Profile exists, direct to the main app (MultiPageToggler)
            return MultiPageToggler();
          }
        },
      );
    }
  }
}