// lib/screens/home_screen.dart
// Modern e-commerce homepage with hero section, search, and product grid
// Inspired by Dribbble design with clean, professional layout

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/product_service.dart';
import 'product_detail_screen.dart';
import 'cart_screen.dart';
import 'wishlist_screen.dart';

// Color scheme for consistent branding
const _primary = Color(0xFF2E7D32);   // Green primary
const _primaryDark = Color(0xFF004D40); // Dark green
const _bg = Color(0xFFF1F8E9);        // Light green background
const _textDark = Color(0xFF1B5E20);   // Dark green text
const _textLight = Color(0xFF616161); // Grey text

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = false;
  String? _error;
  List _products = [];
  int _currentPage = 1;
  int _lastPage = 1;
  
  final TextEditingController _searchController = TextEditingController();
  String _currentSearch = "";
  int? _selectedCategoryId; 
  List _uniqueCategories = []; 

  @override
  void initState() {
    super.initState();
    _loadPage(1);
    _loadAllCategories();
  }

  // Load categories from all products
  Future<void> _loadAllCategories() async {
    try {
      final response = await ProductService.fetchProducts(perPage: 30);
      final allProducts = response['products'];
      
      final Set uniqueIds = {};
      final List categories = [
        {'id': null, 'name': 'All Products'}
      ];

      for (var p in allProducts) {
        final cat = p['category'];
        if (cat != null && !uniqueIds.contains(cat['id'])) {
          uniqueIds.add(cat['id']);
          categories.add(cat);
        }
      }

      categories.sort((a, b) {
        if (a['name'] == 'All Products') return -1;
        if (b['name'] == 'All Products') return 1;
        return a['name'].compareTo(b['name']);
      });

      setState(() {
        _uniqueCategories = categories;
      });
    } catch (e) {
      debugPrint("Error loading categories: $e");
    }
  }

  // Load products with pagination
  Future<void> _loadPage(int page) async {
    if (page < 1 || page > _lastPage) return;

    setState(() {
      _isLoading = true;
      _currentPage = page;
      _error = null;
      _products = []; 
    });

    try {
      final response = await ProductService.fetchProducts(
        page: page,
        perPage: 15, 
        search: _currentSearch,
        categoryId: _selectedCategoryId,
      );
      
      List rawProducts = response['products'];
      List filteredProducts = rawProducts.where((p) {
        String img = (p['main_image'] ?? '').toLowerCase();
        return img.isNotEmpty && !img.contains('logo') && !img.contains('placeholder');
      }).toList();

      setState(() {
        _products = filteredProducts.take(10).toList();
        _lastPage = response['lastPage'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        slivers: [
          // Main app bar with branding
          _buildMainAppBar(),
          
          // Welcome section
          _buildWelcomeSection(),
          
          // Search section
          _buildSearchSection(),
          
          // Category chips
          _buildCategoryChips(),
          
          // Hero section
          _buildHeroSection(),
          
          // Featured products section
          _buildFeaturedProducts(),
          
          // Loading/Error/Empty states
          if (_isLoading && _products.isEmpty)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: _primary)))
          else if (_error != null)
            SliverFillRemaining(child: _ErrorView(message: _error!, onRetry: () => _loadPage(_currentPage)))
          else if (_products.isEmpty && !_isLoading)
             const SliverFillRemaining(child: Center(child: Text("No products found", style: TextStyle(fontSize: 16))))
          else
            _buildProductGrid(),
            
          _buildPaginationControls(),
        ],
      ),
    );
  }

  // Main app bar with branding
  Widget _buildMainAppBar() {
    final appProvider = Provider.of<AppProvider>(context);
    return SliverAppBar(
      pinned: true,
      backgroundColor: Colors.white,
      expandedHeight: 80,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, _bg],
          ),
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'NUTRIBLEND',
                  style: TextStyle(
                    color: _primary, 
                    fontSize: 14, 
                    letterSpacing: 3, 
                    fontWeight: FontWeight.w900
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Premium Supplements',
                  style: TextStyle(
                    color: _textLight,
                    fontSize: 10,
                    fontWeight: FontWeight.w500
                  ),
                ),
              ],
            ),
            Row(
              children: [
                // Wishlist icon with badge
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const WishlistScreen()),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 16),
                    child: Badge(
                      isLabelVisible: appProvider.wishlistCount > 0,
                      label: Text('${appProvider.wishlistCount}', style: const TextStyle(color: Colors.white, fontSize: 10)),
                      backgroundColor: _primary,
                      smallSize: 16,
                      child: const Icon(Icons.favorite_border, color: _primary, size: 22),
                    ),
                  ),
                ),
                // Cart icon with badge
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CartScreen()),
                    );
                  },
                  child: Badge(
                    isLabelVisible: appProvider.cartCount > 0,
                    label: Text('${appProvider.cartCount}', style: const TextStyle(color: Colors.white, fontSize: 10)),
                    backgroundColor: _primary,
                    smallSize: 16,
                    child: const Icon(Icons.shopping_cart_outlined, color: _primary, size: 22),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: _primary),
          onPressed: () {
            _loadPage(_currentPage);
            _loadAllCategories();
          },
          tooltip: 'Refresh',
        )
      ],
    );
  }

  // Welcome section
  Widget _buildWelcomeSection() {
    return SliverToBoxAdapter(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome to NutriBlend',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: _textDark,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Discover the finest supplements to fuel your performance',
              style: TextStyle(
                fontSize: 16,
                color: _textLight,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Search section
  Widget _buildSearchSection() {
    return SliverToBoxAdapter(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          children: [
            // Search bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: _textLight, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (value) {
                        setState(() { 
                          _currentSearch = value; 
                          _loadPage(1); 
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search supplements...', 
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: _textLight),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.filter_list, color: Colors.white, size: 20),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Quick search suggestions
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildSuggestionChip('Protein'),
                _buildSuggestionChip('Vitamins'),
                _buildSuggestionChip('Pre-workout'),
                _buildSuggestionChip('Recovery'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Category chips
  Widget _buildCategoryChips() {
    return SliverToBoxAdapter(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Shop by Category',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _textDark,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.zero,
                itemCount: _uniqueCategories.length,
                itemBuilder: (ctx, i) {
                  final cat = _uniqueCategories[i];
                  final isSelected = _selectedCategoryId == cat['id'];
                  
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: ChoiceChip(
                      label: Text(cat['name']),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategoryId = selected ? cat['id'] : null;
                          _loadPage(1);
                        });
                      },
                      selectedColor: _primary,
                      backgroundColor: Colors.white,
                      side: BorderSide(color: isSelected ? _primary : Colors.grey.shade300),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : _textDark, 
                        fontWeight: FontWeight.w600
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Hero section
  Widget _buildHeroSection() {
    return SliverToBoxAdapter(
      child: Container(
        width: double.infinity,
        height: 280,
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_primary, _primaryDark],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: Stack(
          children: [
            // Background image
            Positioned.fill(
              child: Opacity(
                opacity: 0.2,
                child: CachedNetworkImage(
                  imageUrl: 'https://images.unsplash.com/photo-1551698618-1dfe5d97d256?w=800',
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(color: Colors.white.withValues(alpha: 0.1)),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'NEW ARRIVALS',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Premium Supplements\nFor Peak Performance',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _selectedCategoryId = null;
                        _loadPage(1);
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: _primary,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Shop Now',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Featured products section
  Widget _buildFeaturedProducts() {
    return SliverToBoxAdapter(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Featured Products',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _textDark,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    'View All',
                    style: TextStyle(
                      color: _primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Featured products horizontal list
            SizedBox(
              height: 200,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.zero,
                itemCount: _products.length > 4 ? 4 : _products.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  final product = _products[index];
                  return _FeaturedProductCard(product: product);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Product grid
  Widget _buildProductGrid() {
    return SliverPadding(
      padding: const EdgeInsets.all(24),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.75,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, i) => _ProductCard(product: _products[i]),
          childCount: _products.length,
        ),
      ),
    );
  }

  // Pagination controls
  Widget _buildPaginationControls() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildNavButton(
              icon: Icons.chevron_left,
              label: 'Prev',
              onPressed: _currentPage > 1 ? () => _loadPage(_currentPage - 1) : null,
              isActive: _currentPage > 1,
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Text(
                '$_currentPage / $_lastPage',
                style: const TextStyle(fontWeight: FontWeight.bold, color: _textDark),
              ),
            ),
            _buildNavButton(
              icon: Icons.chevron_right,
              label: 'Next',
              onPressed: _currentPage < _lastPage ? () => _loadPage(_currentPage + 1) : null,
              isRight: true,
              isActive: _currentPage < _lastPage,
            ),
          ],
        ),
      ),
    );
  }

  // Navigation button component
  Widget _buildNavButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    bool isRight = false,
    required bool isActive,
  }) {
    return Material(
      color: isActive ? _primary : Colors.grey[300]!,
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            children: [
              if (!isRight) Icon(icon, color: Colors.white, size: 20),
              if (!isRight) const SizedBox(width: 8),
              Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              if (isRight) const SizedBox(width: 8),
              if (isRight) Icon(icon, color: Colors.white, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Quick search chip
  Widget _buildSuggestionChip(String text) {
    return ActionChip(
      label: Text(text),
      onPressed: () {
        setState(() {
          _searchController.text = text;
          _currentSearch = text;
          _loadPage(1);
        });
      },
      backgroundColor: Colors.white,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      elevation: 2,
      labelStyle: TextStyle(color: _textDark, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}

// Featured product card
class _FeaturedProductCard extends StatelessWidget {
  final Map product;
  const _FeaturedProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final String image = product['main_image'] ?? '';
    final String name = product['name']?.toString().trim() ?? 'Product';
    final String price = product['formatted_price'] ?? '';
    final bool inStock = product['in_stock'] ?? true;

    return Container(
      width: 160,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Container(
              width: double.infinity,
              height: 120,
              color: Colors.grey[100],
              child: image.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: image,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => const Center(child: Icon(Icons.image_not_supported)),
                    )
                  : const Center(child: Icon(Icons.image_not_supported)),
            ),
          ),
          // Product info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    price,
                    style: const TextStyle(
                      color: _primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (!inStock)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Out of Stock',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Product card component
class _ProductCard extends StatefulWidget {
  final Map product;
  const _ProductCard({required this.product});

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  bool _isHovered = false;
  bool _isHeartHovered = false;

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final String image = widget.product['main_image'] ?? '';
    final String name = widget.product['name']?.toString().trim() ?? 'Product';
    final String price = widget.product['formatted_price'] ?? '';
    final bool inStock = widget.product['in_stock'] ?? true;
    final int id = widget.product['id'] ?? 0;
    final bool isFavorite = appProvider.isFavorite(id);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ProductDetailScreen(product: widget.product)),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: _isHovered ? 16 : 8, 
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: _isHovered ? _primary.withValues(alpha: 0.2) : Colors.transparent,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                      child: Container(
                        width: double.infinity,
                        color: Colors.grey[100],
                        child: image.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: image, 
                                fit: BoxFit.cover, 
                                errorWidget: (_, __, ___) => const Center(child: Icon(Icons.image_not_supported))
                              )
                            : const Center(child: Icon(Icons.image_not_supported)),
                      ),
                    ),
                    if (!inStock)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.7), 
                          alignment: Alignment.center,
                          child: const Text('OUT OF STOCK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                        ),
                      ),
                    
                    // Wishlist button
                    Positioned(
                      top: 8,
                      right: 8,
                      child: MouseRegion(
                        onEnter: (_) => setState(() => _isHeartHovered = true),
                        onExit: (_) => setState(() => _isHeartHovered = false),
                        child: GestureDetector(
                          onTap: () {
                            appProvider.toggleWishlist(widget.product);
                            ScaffoldMessenger.of(context).clearSnackBars();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(!isFavorite ? 'Added to Wishlist' : 'Removed from Wishlist'),
                                backgroundColor: _primary,
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: _isHeartHovered ? 0.2 : 0.1), 
                                  blurRadius: _isHeartHovered ? 8 : 4, 
                                  offset: const Offset(0, 2),
                                )
                              ],
                            ),
                            child: Icon(
                              isFavorite ? Icons.favorite : Icons.favorite_border,
                              color: _isHeartHovered ? Colors.red.shade400 : (isFavorite ? _primary : Colors.grey),
                              size: _isHeartHovered ? 22 : 20, 
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Product details
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name, 
                      maxLines: 2, 
                      overflow: TextOverflow.ellipsis, 
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _textDark, height: 1.2),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Text(
                      price, 
                      style: const TextStyle(
                        color: _primary, 
                        fontSize: 16, 
                        fontWeight: FontWeight.w900
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            inStock ? 'In Stock' : 'Out of Stock',
                            style: TextStyle(
                              color: inStock ? Colors.green : Colors.red,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _primary,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: _primary.withValues(alpha: 0.3), 
                                blurRadius: 6, 
                                spreadRadius: 1
                              )
                            ]
                          ),
                          child: const Icon(
                            Icons.add, 
                            color: Colors.white, 
                            size: 20
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Error view component
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Connection Error', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onRetry, 
              style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white), 
              child: const Text('Retry')
            ),
          ],
        ),
      ),
    );
  }
}