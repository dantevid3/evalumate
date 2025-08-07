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

// Keeping Post model import as it's essential for post creation logic.
// All other specified imports have been removed.
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
  final TextEditingController _categoriesController = TextEditingController(); // Controller for categories

  double _rating = 50.0;
  XFile? _selectedMedia;
  String _mediaType = '';
  double _mediaAspectRatio = 1.0;

  bool _isLoading = false;
  Profile? _currentUserProfile;
  User? _currentUser;

  List<String> _allBrands = [];
  List<String> _allProducts = [];
  List<String> _allCategories = []; // List to store all distinct categories

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    _fetchCurrentUserProfile();
    _fetchSuggestions(); // Fetch all unique brands, products, and categories
  }

  @override
  void dispose() {
    _captionController.dispose();
    _websiteLinkController.dispose();
    _brandController.dispose();
    _productController.dispose();
    _categoriesController.dispose();
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

  Future<void> _pickMedia() async {
    final ImagePicker picker = ImagePicker();
    final result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: const Text('Select Media'),
          children: <Widget>[
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, 'image');
              },
              child: const Text('Pick Image'),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, 'video');
              },
              child: const Text('Pick Video'),
            ),
          ],
        );
      },
    );

    if (result == 'image') {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _selectedMedia = image; // No image cropping due to removed import
          _mediaType = 'image';
          _calculateImageAspectRatio(_selectedMedia!.path);
        });
      }
    } else if (result == 'video') {
      final XFile? video = await picker.pickVideo(source: ImageSource.gallery);
      if (video != null) {
        setState(() {
          _selectedMedia = video;
          _mediaType = 'video';
          _mediaAspectRatio = 1.0; // Default aspect ratio for video
        });
      }
    }
  }

  Future<void> _calculateImageAspectRatio(String imagePath) async {
    final bytes = await File(imagePath).readAsBytes();
    final image = await decodeImageFromList(bytes);
    setState(() {
      _mediaAspectRatio = image.width / image.height;
    });
  }

  Future<String> _uploadFileToFirebase(XFile file, String mediaType) async {
    // Extract file extension without 'path' package
    String fileExtension = file.path.split('.').last;
    // Determine mime type without 'mime_type' package
    String mimeType = mediaType == 'image' ? 'image/jpeg' : 'video/mp4';

    Reference storageRef = FirebaseStorage.instance
        .ref()
        .child('$mediaType/${DateTime.now().millisecondsSinceEpoch}.$fileExtension');

    UploadTask uploadTask = storageRef.putFile(File(file.path), SettableMetadata(contentType: mimeType));
    TaskSnapshot snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  Future<void> _uploadPost() async {
    if (_formKey.currentState!.validate() && _selectedMedia != null && _currentUser != null && _currentUserProfile != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        String mediaUrl = await _uploadFileToFirebase(_selectedMedia!, _mediaType);

        // Correctly parse categories from the TextEditingController
        List<String> categoriesList = _categoriesController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();

        await DatabaseService(uid: _currentUser!.uid).createPost(
          uid: _currentUser!.uid,
          mediaUrl: mediaUrl,
          mediaType: _mediaType,
          aspectRatio: _mediaAspectRatio,
          caption: _captionController.text.trim().isNotEmpty ? _captionController.text.trim() : null,
          rating: _rating.round(),
          websiteLink: _websiteLinkController.text.trim().isNotEmpty ? _websiteLinkController.text.trim() : null,
          userName: _currentUserProfile!.userName,
          userDisplayName: _currentUserProfile!.displayName,
          userProfilePicUrl: _currentUserProfile!.userProfilePicUrl,
          brand: _brandController.text.trim().isNotEmpty ? _brandController.text.trim() : null,
          product: _productController.text.trim().isNotEmpty ? _productController.text.trim() : null,
          categories: categoriesList, // Pass the parsed list
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post created successfully!')),
        );
        Navigator.pop(context); // Go back to the previous screen (e.g., feed)
      } catch (e) {
        print('Error creating post: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create post: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      // Show validation error or media selection prompt
      if (_selectedMedia == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an image or video.')),
        );
      }
      _formKey.currentState!.validate(); // Re-validate to show errors for text fields
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Post'),
        backgroundColor: Colors.green[300],
        elevation: 0,
        actions: [
          _isLoading
              ? const Padding(
            padding: EdgeInsets.all(8.0),
            child: CircularProgressIndicator(color: Colors.white),
          )
              : IconButton(
            icon: const Icon(Icons.check),
            onPressed: _uploadPost,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                onTap: _pickMedia,
                child: Container(
                  height: 200,
                  color: Colors.grey[200],
                  child: _selectedMedia == null
                      ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_a_photo,
                          size: 50,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap to select media',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                      : (_mediaType == 'image'
                      ? Image.file(
                    File(_selectedMedia!.path),
                    fit: BoxFit.contain,
                  )
                      : const Center(
                    child: Icon(
                      Icons.video_collection,
                      size: 50,
                      color: Colors.grey,
                    ),
                  ) // Placeholder for video display
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _captionController,
                decoration: InputDecoration(
                  labelText: 'Caption (Optional)',
                  hintText: 'What\'s your take on this?',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.green[400]!),
                  ),
                  prefixIcon: const Icon(Icons.text_fields),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // Rating Slider
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rating: ${_rating.round()}%',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Slider(
                    value: _rating,
                    min: 0,
                    max: 100,
                    divisions: 100,
                    label: _rating.round().toString(),
                    onChanged: (value) {
                      setState(() {
                        _rating = value;
                      });
                    },
                    activeColor: Colors.green[400],
                    inactiveColor: Colors.grey[300],
                  ),
                ],
              ),
              const SizedBox(height: 24),

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

                  return _allBrands.where((brand) {
                    return brand.toLowerCase().contains(lastPart.toLowerCase());
                  });
                },
                onSelected: (String selection) {
                  final String currentInput = _brandController.text;
                  final int lastCommaIndex = currentInput.lastIndexOf(',');

                  if (lastCommaIndex != -1) {
                    _brandController.text =
                    '${currentInput.substring(0, lastCommaIndex + 1)} $selection';
                  } else {
                    _brandController.text = selection;
                  }
                  _brandController.selection = TextSelection.fromPosition(
                    TextPosition(offset: _brandController.text.length),
                  );
                },
                fieldViewBuilder: (BuildContext context,
                    TextEditingController textEditingController,
                    FocusNode focusNode,
                    VoidCallback onFieldSubmitted) {
                  // Keep this line as it synchronizes the internal controller with _brandController
                  // if _brandController is not directly assigned to TextFormField
                  if (_brandController.text != textEditingController.text) {
                    _brandController.text = textEditingController.text;
                  }
                  return TextFormField(
                    controller: _brandController, // Using _brandController directly
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      labelText: 'Brand (Optional)',
                      hintText: 'e.g., Coca-Cola, Nike',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.green[400]!),
                      ),
                      prefixIcon: const Icon(Icons.business),
                    ),
                    onFieldSubmitted: (String value) {
                      onFieldSubmitted();
                    },
                  );
                },
              ),
              const SizedBox(height: 24),

              Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return const Iterable<String>.empty();
                  }
                  final String currentInput = textEditingValue.text;
                  final List<String> parts = currentInput.split(',');
                  final String lastPart = parts.last.trim();

                  if (lastPart.isEmpty) {
                    return const Iterable<String>.empty();
                  }

                  return _allProducts.where((product) {
                    return product.toLowerCase().contains(lastPart.toLowerCase());
                  });
                },
                onSelected: (String selection) {
                  final String currentInput = _productController.text;
                  final int lastCommaIndex = currentInput.lastIndexOf(',');

                  if (lastCommaIndex != -1) {
                    _productController.text =
                    '${currentInput.substring(0, lastCommaIndex + 1)} $selection';
                  } else {
                    _productController.text = selection;
                  }
                  _productController.selection = TextSelection.fromPosition(
                    TextPosition(offset: _productController.text.length),
                  );
                },
                fieldViewBuilder: (BuildContext context,
                    TextEditingController textEditingController,
                    FocusNode focusNode,
                    VoidCallback onFieldSubmitted) {
                  // Keep this line as it synchronizes the internal controller with _productController
                  // if _productController is not directly assigned to TextFormField
                  if (_productController.text != textEditingController.text) {
                    _productController.text = textEditingController.text;
                  }
                  return TextFormField(
                    controller: _productController, // Using _productController directly
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      labelText: 'Product (Optional)',
                      hintText: 'e.g., iPhone 15, Diet Coke',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.green[400]!),
                      ),
                      prefixIcon: const Icon(Icons.shopping_bag),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

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

              TextFormField(
                controller: _websiteLinkController,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  labelText: 'Website Link (Optional)',
                  hintText: 'e.g., https://www.yourtaste.com',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.green[400]!),
                  ),
                  prefixIcon: const Icon(Icons.link),
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
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}