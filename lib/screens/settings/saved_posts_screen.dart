// import 'package:flutter/material.dart';
// import 'package:evalumate/models/post.dart';
// import 'package:evalumate/services/database.dart';
//
//
// class SavedPostsScreen extends StatefulWidget {
//   final String uid;
//   const SavedPostsScreen({Key? key, required this.uid}) : super(key: key);
//
//   @override
//   State<SavedPostsScreen> createState() => _SavedPostsScreenState();
// }
//
// class _SavedPostsScreenState extends State<SavedPostsScreen> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Saved Posts'),
//         backgroundColor: Colors.green[300],
//       ),
//       body: StreamBuilder<List<Post>>(
//         stream: DatabaseService(uid: widget.uid).savedPosts,
//         builder: (context, snapshot) {
//           if (snapshot.hasError) {
//             return const Center(child: Text('Error loading saved posts'));
//           }
//
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }
//
//           final savedPosts = snapshot.data ?? [];
//
//           if (savedPosts.isEmpty) {
//             return const Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(Icons.bookmark_outline, size: 64, color: Colors.grey),
//                   SizedBox(height: 16),
//                   Text(
//                     'No saved posts yet',
//                     style: TextStyle(fontSize: 18, color: Colors.grey),
//                   ),
//                   Text(
//                     'Posts you save will appear here',
//                     style: TextStyle(color: Colors.grey),
//                   ),
//                 ],
//               ),
//             );
//           }
//
//           return ListView.builder(
//             itemCount: savedPosts.length,
//             itemBuilder: (context, index) {
//               final post = savedPosts[index];
//               return Card(
//                 margin: const EdgeInsets.all(8.0),
//                 child: ListTile(
//                   leading: ClipRRect(
//                     borderRadius: BorderRadius.circular(8.0),
//                     child: Image.network(
//                       post.mediaUrl,
//                       width: 50,
//                       height: 50,
//                       fit: BoxFit.cover,
//                       errorBuilder: (context, error, stackTrace) {
//                         return Container(
//                           width: 50,
//                           height: 50,
//                           color: Colors.grey[300],
//                           child: const Icon(Icons.image),
//                         );
//                       },
//                     ),
//                   ),
//                   title: Text(post.caption ?? 'No caption'),
//                   subtitle: Text('${post.rating}% • ${post.userName}'),
//                   trailing: IconButton(
//                     icon: const Icon(Icons.bookmark_remove),
//                     onPressed: () => _unsavePost(post.postId),
//                   ),
//                 ),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
//
//   Future<void> _unsavePost(String postId) async {
//     try {
//       await DatabaseService(uid: widget.uid).unsavePost(postId);
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Post removed from saved')),
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error: ${e.toString()}')),
//         );
//       }
//     }
//   }
// }