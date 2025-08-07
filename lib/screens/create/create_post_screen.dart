// lib/screens/inapp/create_post_screen.dart

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:evalumate/services/database.dart';
import 'package:evalumate/models/profile.dart';
import 'dart:ui' as ui; // REQUIRED for decodeImageFromList

import 'package:cloud_firestore/cloud_firestore.dart'; // Import for Timestamp and FieldValue

// NEW imports for category input and media handling - COMMENTED OUT AS REQUESTED
// import 'package:evalumate/models/post.dart'; // Keep Post model import for now if it's strictly needed for DatabaseService and Post object creation
// import 'package:image_cropper/image_cropper.dart';
// import 'package:mime_type/mime_type.dart';
// import 'package:path/path.dart' as p;
// import 'package:video_player/video_player.dart';
// import 'package:file_picker/file_picker.dart';


// Re-adding essential imports that were part of the commented block but are still necessary
// If Post model is explicitly used for object creation in _uploadPost, it must remain.
// If DatabaseService expects a Post object, this import is essential.
// Assuming Post is an essential data model.
import 'package:evalumate/models/post.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _websiteLinkController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _productController = TextEditingController();

  final TextEditingController _categoriesController = TextEditingController();

  double _rating = 50.0;
  XFile? _selectedMedia;
  String _mediaType = 'image'; // Default to image since we're only picking images now
  double _mediaAspectRatio = 1.0;

  // Removed _videoPlayerController as video functionality is commented out

  bool _isLoading = false;
  Profile? _currentUserProfile;
  User? _currentUser;

  List<String> _allBrands = [];
  List<String> _allProducts = [];
  List<String> _allCategories = [];

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    _fetchCurrentUserProfile();
    _fetchSuggestions();
  }

  @override
  void dispose() {
    _captionController.dispose();
    _websiteLinkController.dispose();
    _brandController.dispose();
    _productController.dispose();
    _categoriesController.dispose();
    // Removed _videoPlayerController dispose call
    super.dispose();
  }

  Future<void> _fetchCurrentUserProfile() async {
    if (_currentUser != null) {
      try {
        final profile = await DatabaseService(uid: _currentUser!.uid).userData.first;
        if (mounted) {
          setState(() {
            _currentUserProfile = profile;
          });
        }
      } catch (e) {
        print('Error fetching user profile: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to load user profile for posting.')),
          );
        }
      }
    }
  }


  Future<void> _fetchSuggestions() async {
    // Fetch all brands
    DatabaseService().getDistinctBrands().listen((brands) {
      if (mounted) {
        setState(() {
          _allBrands = brands;
        });
      }
    });

    // Fetch all products
    DatabaseService().getDistinctProducts().listen((products) {
      if (mounted) {
        setState(() {
          _allProducts = products;
        });
      }
    });

    // Fetch all categories
    DatabaseService().getDistinctCategories().listen((categories) {
      if (mounted) {
        setState(() {
          _allCategories = categories;
        });
      }
    });
  }



  Future<void> _selectMedia() async {
    final ImagePicker picker = ImagePicker();
    XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery); // Only picking images from gallery

    if (pickedFile != null) {
      final bytes = await File(pickedFile.path).readAsBytes();

      final completer = Completer<ui.Image>();
      ui.decodeImageFromList(bytes, (ui.Image img) {
        completer.complete(img);
      });
      final ui.Image decodedImage = await completer.future;

      setState(() {
        _selectedMedia = pickedFile;
        _mediaType = 'image'; // Force to image
        _mediaAspectRatio = decodedImage.width / decodedImage.height;
        // No video player to dispose
      });
    } else {
      // User canceled the picker
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No image selected.')),
        );
      }
    }
  }

  Future<String?> _uploadMediaToStorage(String uid, XFile media) async {
    try {
      final storageRef = FirebaseStorage.instance.ref();
      // Using media.name for file extension, removing p.extension
      final String fileName =
          'posts/${uid}/${DateTime.now().millisecondsSinceEpoch}_${media.name}';
      final UploadTask uploadTask = storageRef.child(fileName).putFile(File(media.path));
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading media: $e');
      return null;
    }
  }

  Future<void> _uploadPost() async {
    if (_selectedMedia == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image')), // Changed text
      );
      return;
    }
    if (_rating.toInt() < 0 || _rating.toInt() > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid rating')),
      );
      return;
    }
    setState(() {
      _isLoading = true;
    });

    try {
      final mediaUrl = await _uploadMediaToStorage(_currentUser!.uid, _selectedMedia!);
      if (mediaUrl == null) {
        throw Exception('Media upload failed. Please try again.');
      }

      final String? brand = _brandController.text.trim().isEmpty ? null : _brandController.text.trim();
      final String? product = _productController.text.trim().isEmpty ? null : _productController.text.trim();

      List<String> categoriesList = _categoriesController.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      await DatabaseService(uid: _currentUser!.uid).createPost(
        uid: _currentUser!.uid,
        mediaUrl: mediaUrl,
        mediaType: _mediaType, // Will always be 'image'
        aspectRatio: _mediaAspectRatio,
        caption: _captionController.text.trim().isEmpty ? null : _captionController.text.trim(),
        rating: _rating.toInt(),
        websiteLink: _websiteLinkController.text.trim().isEmpty ? null : _websiteLinkController.text.trim(),
        userName: _currentUserProfile?.userName ?? 'Anonymous',
        userDisplayName: _currentUserProfile?.displayName,
        userProfilePicUrl: _currentUserProfile?.userProfilePicUrl,
        brand: brand,
        product: product,
        categories: categoriesList,
      );

      setState(() {
        _isLoading = false;
        _selectedMedia = null;
        _mediaType = 'image'; // Reset to image
        _mediaAspectRatio = 1.0;
        // No video player to dispose
        _captionController.clear();
        _websiteLinkController.clear();
        _brandController.clear();
        _productController.clear();
        _categoriesController.clear();
        _rating = 50.0;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post uploaded successfully!')),
        );
      });
    } catch (e) {
      print("Error uploading post: $e");
      setState(() {
        _isLoading = false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload post: $e')),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserProfile == null && _currentUser != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Create Post'),
          backgroundColor: Colors.green[300],
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Post'),
        backgroundColor: Colors.green[300],
        actions: [
          _isLoading
              ? const Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              ),
            ),
          )
              : IconButton(
            icon: const Icon(Icons.upload),
            onPressed: _uploadPost,
          ),
        ],
      ),
      body: _isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Creating your post...',
              style: TextStyle(color: Colors.grey[700]),
            ),
          ],
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                onTap: _selectMedia, // This will now use ImagePicker only
                child: AspectRatio(
                  aspectRatio: _mediaAspectRatio,
                  child: Container(
                    color: Colors.grey.shade200,
                    child: _selectedMedia != null
                        ? Image.file( // Directly show image, no video check needed
                      File(_selectedMedia!.path),
                      fit: BoxFit.cover,
                    )
                        : const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey),
                          Text('Select Image'), // Changed text
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _captionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Caption (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rating: ${_rating.toStringAsFixed(0)}%',
                    style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                  ),
                  Slider(
                    value: _rating,
                    min: 0,
                    max: 100,
                    divisions: 100,
                    label: _rating.round().toString(),
                    onChanged: (double value) {
                      setState(() {
                        _rating = value;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _websiteLinkController,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'Website Link (Optional)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final uri = Uri.tryParse(value);
                    if (uri == null || !uri.isAbsolute || !(uri.scheme == 'http' || uri.scheme == 'https')) {
                      return 'Please enter a valid website link (e.g., https://www.example.com)';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _brandController,
                decoration: const InputDecoration(
                  labelText: 'Brand (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _productController,
                decoration: const InputDecoration(
                  labelText: 'Product/Item (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),

              // Autocomplete for Categories
              Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return const Iterable<String>.empty();
                  }
                  // Get the last part after the last comma for autocompletion
                  final String currentInput = textEditingValue.text;
                  final List<String> parts = currentInput.split(',');
                  final String lastPart = parts.last.trim();

                  if (lastPart.isEmpty) {
                    return const Iterable<String>.empty();
                  }

                  return _allCategories.where((category) {
                    return category.toLowerCase().contains(lastPart.toLowerCase());
                  });
                },
                onSelected: (String selection) {
                  final String currentInput = _categoriesController.text;
                  final int lastCommaIndex = currentInput.lastIndexOf(',');

                  if (lastCommaIndex != -1) {
                    _categoriesController.text =
                    '${currentInput.substring(0, lastCommaIndex + 1)} $selection';
                  } else {
                    _categoriesController.text = selection;
                  }
                  _categoriesController.selection = TextSelection.fromPosition(
                    TextPosition(offset: _categoriesController.text.length),
                  );
                },
                fieldViewBuilder: (BuildContext context,
                    TextEditingController textEditingController,
                    FocusNode focusNode,
                    VoidCallback onFieldSubmitted) {
                  return TextFormField(
                    controller: _categoriesController, // Using _categoriesController directly
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      labelText: 'Categories (e.g., alcohol, wine, cheapbooze)',
                      hintText: 'Separate categories with commas',
                      border: OutlineInputBorder(),
                    ),
                    onFieldSubmitted: (String value) {
                      onFieldSubmitted();
                    },
                  );
                },
              ),


              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}