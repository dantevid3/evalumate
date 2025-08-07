// lib/screens/inapp/search_screen.dart

import 'package:flutter/material.dart';
import 'package:evalumate/services/database.dart';
import 'package:evalumate/models/profile.dart';
import 'package:evalumate/screens/profile/user_profile_screen.dart';
import 'package:evalumate/screens/inapp/brand_product_category_feed_screen.dart';
import 'package:evalumate/utils/feed_type.dart';
import 'package:evalumate/models/post.dart'; // Import Post model for the StreamBuilder
import 'package:evalumate/screens/feed/post_card.dart';


class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

enum SearchType { users, categories, brands, products }

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  SearchType _searchType = SearchType.users;

  List<String> _allBrands = [];
  List<String> _allCategories = [];
  List<String> _allProducts = []; // NEW: For product suggestions

  List<String> _filteredBrands = [];
  List<String> _filteredCategories = [];
  List<String> _filteredProducts = []; // NEW: For filtered product suggestions

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _fetchSuggestions();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim();
      _filterSuggestions();
    });
  }

  Future<void> _fetchSuggestions() async {
    DatabaseService().getDistinctBrands().listen((brands) {
      if (mounted) {
        setState(() {
          _allBrands = brands;
          _filterSuggestions();
        });
      }
    });

    DatabaseService().getDistinctCategories().listen((categories) {
      if (mounted) {
        setState(() {
          _allCategories = categories;
          _filterSuggestions();
        });
      }
    });

    // NEW: Fetch all products for auto-suggestion
    DatabaseService().getDistinctProducts().listen((products) {
      if (mounted) {
        setState(() {
          _allProducts = products;
          _filterSuggestions();
        });
      }
    });
  }

  void _filterSuggestions() {
    if (_searchType == SearchType.brands) {
      _filteredBrands = _allBrands
          .where((brand) => brand.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    } else if (_searchType == SearchType.categories) {
      _filteredCategories = _allCategories
          .where((category) => category.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    } else if (_searchType == SearchType.products) { // NEW: Filter products
      _filteredProducts = _allProducts
          .where((product) => product.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        backgroundColor: Colors.green[300],
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search ${_searchType == SearchType.users ? 'users' : _searchType == SearchType.categories ? 'categories' : _searchType == SearchType.brands ? 'brands' : 'products'}...', // Updated hint text
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                        : null,
                  ),
                  onChanged: (value) {
                    // Listener already handles setState(_onSearchChanged);
                  },
                  onSubmitted: (value) { // NEW: Add onSubmitted to trigger search for posts
                    if (value.isNotEmpty) {
                      _navigateToFeedScreen(value, _searchType);
                    }
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    FilterChip(
                      label: const Text('Users'),
                      selected: _searchType == SearchType.users,
                      onSelected: (selected) {
                        setState(() {
                          _searchType = SearchType.users;
                          _searchController.clear();
                        });
                      },
                      selectedColor: Colors.green[100],
                      checkmarkColor: Colors.green[800],
                    ),
                    FilterChip(
                      label: const Text('Brands'),
                      selected: _searchType == SearchType.brands,
                      onSelected: (selected) {
                        setState(() {
                          _searchType = SearchType.brands;
                          _searchController.clear();
                        });
                      },
                      selectedColor: Colors.green[100],
                      checkmarkColor: Colors.green[800],
                    ),
                    FilterChip(
                      label: const Text('Categories'),
                      selected: _searchType == SearchType.categories,
                      onSelected: (selected) {
                        setState(() {
                          _searchType = SearchType.categories;
                          _searchController.clear();
                        });
                      },
                      selectedColor: Colors.green[100],
                      checkmarkColor: Colors.green[800],
                    ),
                    FilterChip( // NEW: Product FilterChip
                      label: const Text('Products'),
                      selected: _searchType == SearchType.products,
                      onSelected: (selected) {
                        setState(() {
                          _searchType = SearchType.products;
                          _searchController.clear();
                        });
                      },
                      selectedColor: Colors.green[100],
                      checkmarkColor: Colors.green[800],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: _buildSearchResults(),
    );
  }

  // NEW: Helper function to navigate to the feed screen
  void _navigateToFeedScreen(String query, SearchType searchType) {
    FeedType feedType;
    if (searchType == SearchType.brands) {
      feedType = FeedType.brand;
    } else if (searchType == SearchType.categories) {
      feedType = FeedType.category;
    } else if (searchType == SearchType.products) {
      feedType = FeedType.product;
    } else {
      return; // Should not happen for these search types
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BrandProductCategoryFeedScreen(
          query: query,
          feedType: feedType,
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchQuery.isEmpty) {
      if (_searchType == SearchType.brands) {
        return _buildSuggestionList(_allBrands, FeedType.brand);
      } else if (_searchType == SearchType.categories) {
        return _buildSuggestionList(_allCategories, FeedType.category);
      } else if (_searchType == SearchType.products) { // NEW: Show all products
        return _buildSuggestionList(_allProducts, FeedType.product);
      } else {
        return Center(
          child: Text(
            'Start typing to search users, brands, products, or categories.', // Updated hint
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
            textAlign: TextAlign.center,
          ),
        );
      }
    }

    if (_searchType == SearchType.users) {
      return StreamBuilder<List<Profile>>(
        stream: DatabaseService().searchProfilesByUserName(_searchQuery),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            print("Search Screen Error: ${snapshot.error}");
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No profiles found.'));
          } else {
            final List<Profile> searchResults = snapshot.data!;
            return ListView.builder(
              itemCount: searchResults.length,
              itemBuilder: (context, index) {
                final Profile profile = searchResults[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                  elevation: 2,
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: profile.userProfilePicUrl != null && profile.userProfilePicUrl!.isNotEmpty
                          ? NetworkImage(profile.userProfilePicUrl!)
                          : null,
                      child: profile.userProfilePicUrl == null || profile.userProfilePicUrl!.isEmpty
                          ? Icon(Icons.person, color: Colors.grey[600])
                          : null,
                    ),
                    title: Text(profile.displayName ?? profile.userName),
                    subtitle: Text('@${profile.userName}'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UserProfileScreen(profile: profile),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          }
        },
      );
    }
    // NEW: Directly display posts when a brand, category, or product search is active
    else if (_searchType == SearchType.brands) {
      return StreamBuilder<List<Post>>(
        stream: DatabaseService().getPostsByBrand(_searchQuery),
        builder: _buildPostStreamBuilder,
      );
    } else if (_searchType == SearchType.categories) {
      return StreamBuilder<List<Post>>(
        stream: DatabaseService().getPostsByCategory(_searchQuery),
        builder: _buildPostStreamBuilder,
      );
    } else if (_searchType == SearchType.products) {
      return StreamBuilder<List<Post>>(
        stream: DatabaseService().getPostsByProduct(_searchQuery),
        builder: _buildPostStreamBuilder,
      );
    }
    // This case should ideally not be reached if all search types are handled,
    // but serves as a fallback.
    return const Center(child: Text('No search results.'));
  }

  // NEW: A common builder for post streams to reduce redundancy
  Widget _buildPostStreamBuilder(BuildContext context, AsyncSnapshot<List<Post>> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    } else if (snapshot.hasError) {
      print("Search Screen Post Stream Error: ${snapshot.error}");
      return Center(
        child: Text(
          'Error: ${snapshot.error}',
          textAlign: TextAlign.center,
        ),
      );
    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
      return Center(
        child: Text(
          'No posts found for "${_searchQuery}" in this ${_searchType == SearchType.brands ? 'brand' : _searchType == SearchType.categories ? 'category' : 'product'}.',
          style: TextStyle(color: Colors.grey[600], fontSize: 16),
          textAlign: TextAlign.center,
        ),
      );
    } else {
      final List<Post> posts = snapshot.data!;
      return ListView.builder(
        itemCount: posts.length,
        itemBuilder: (context, index) {
          final Post post = posts[index];
          return PostCard(post: post);
        },
      );
    }
  }


  // Helper widget to build the list of brand/product/category suggestions
  Widget _buildSuggestionList(List<String> suggestions, FeedType type) {
    if (suggestions.isEmpty && _searchQuery.isNotEmpty) {
      return Center(
        child: Text(
          'No ${_searchType == SearchType.brands ? 'brands' : _searchType == SearchType.categories ? 'categories' : 'products'} found matching "${_searchQuery}".',
          style: TextStyle(color: Colors.grey[600], fontSize: 16),
          textAlign: TextAlign.center,
        ),
      );
    }
    if (suggestions.isEmpty && _searchQuery.isEmpty) {
      return Center(
        child: Text(
          'No existing ${_searchType == SearchType.brands ? 'brands' : _searchType == SearchType.categories ? 'categories' : 'products'} to suggest. Start adding posts with them!',
          style: TextStyle(color: Colors.grey[600], fontSize: 16),
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final item = suggestions[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
          elevation: 2,
          child: ListTile(
            leading: Icon(
              type == FeedType.brand
                  ? Icons.business
                  : (type == FeedType.category ? Icons.category : Icons.shopping_bag), // Updated icon
            ),
            title: Text(item),
            onTap: () {
              // Navigate to the BrandProductCategoryFeedScreen when a suggestion is tapped
              _navigateToFeedScreen(item, _searchType);
            },
          ),
        );
      },
    );
  }
}