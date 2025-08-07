import 'package:evalumate/screens/search/search_screen.dart';
import 'package:evalumate/screens/feed/feed_screen.dart';
import 'package:evalumate/screens/create/create_post_screen.dart';
import 'package:evalumate/screens/inapp/alerts.dart';
import 'package:evalumate/screens/home/home.dart';
import 'package:flutter/material.dart';

enum PageType {
  home,          // Typically a main feed
  search,        // For exploring/searching
  create,        // For creating new content
  notifications, // For alerts/notifications
  profile,       // For the user's own profile
}

class MultiPageToggler extends StatefulWidget {
  const MultiPageToggler({super.key});

  @override
  State<MultiPageToggler> createState() => _MultiPageTogglerState();
}

class _MultiPageTogglerState extends State<MultiPageToggler> {
  PageType _currentPage = PageType.home; // Default page when the app starts

  // Function to switch the currently displayed page
  void _switchPage(PageType page) {
    setState(() => _currentPage = page);
  }

  // Helper method to build the widget for the currently selected page
  Widget _buildCurrentPage() {
    switch (_currentPage) {
      case PageType.home:
        return const FeedScreen(); // Your main feed of posts
      case PageType.search:
        return const SearchScreen(); // Your explore/search screen
      case PageType.create:
        return const CreatePostScreen(); // Your new post creation screen
      case PageType.notifications:
      // Note: 'Recent' might not be a typical name for a notifications page.
      // If 'Recent' shows recent activities/posts, it fits the feed/explore
      // pattern more. If it's for alerts, consider renaming the class.
        return const Alerts();
      case PageType.profile:
      // Note: 'Home' is usually the main app start page.
      // If 'Home' contains the user's profile picture and stats, then
      // mapping 'profile' to 'Home' is correct for showing the user's profile.
        return Home(); // Your user's profile page
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The body dynamically changes based on the selected bottom navigation item
      body: _buildCurrentPage(),

      // --- Bottom Navigation Bar ---
      bottomNavigationBar: Container(
        // Adds a subtle shadow above the navigation bar for visual separation
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, -2), // Shadow above the bar
            ),
          ],
        ),
        child: BottomNavigationBar(
          // Sets the active tab based on the enum's index
          currentIndex: _currentPage.index,
          // When a tab is tapped, update the current page based on its index
          onTap: (index) => _switchPage(PageType.values[index]),
          backgroundColor: Colors.green[300], // Explicitly sets the background color
          selectedItemColor: Colors.grey[800], // Color for the selected icon and label
          unselectedItemColor: Colors.grey[600], // Color for unselected icons and labels
          type: BottomNavigationBarType.fixed, // Ensures all items are visible and colors work
          showSelectedLabels: true,   // Always show label for selected item
          showUnselectedLabels: true, // Always show labels for unselected items
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search),
              label: 'Search',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_box), // A common icon for "create" or "add new"
              label: 'Create',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications),
              label: 'Alerts',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}