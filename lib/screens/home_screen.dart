import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/product_service.dart';
import 'product_detail_screen.dart';
import 'cart_screen.dart';
import 'products_screen.dart';
import 'wishlist_screen.dart';

const _primary = Color(0xFF2E7D32);
const _bg = Color(0xFFF1F8E9);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = false;
  String? _error;
  List _products = [];
  List _featuredProducts = [];
  List _uniqueCategories = [];
  final TextEditingController _searchController = TextEditingController();
  int? _selectedCategoryId; // Added to track selected category

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Load categories
      final categoryResponse = await ProductService.fetchProducts(perPage: 30);
      final allProducts = categoryResponse['products'];
      
      final Set uniqueIds = {};
      final List categories = [{'id': null, 'name': 'All Products'}];
      
      for (var p in allProducts) {
        final cat = p['category'];
        if (cat != null && !uniqueIds.contains(cat['id'])) {
          uniqueIds.add(cat['id']);
          categories.add(cat);
        }
      }
      categories.sort((a, b) => a['name'] == 'All Products' ? -1 : b['name'] == 'All Products' ? 1 : a['name'].compareTo(b['name']));
      
      // Load featured products (first 4)
      final featuredResponse = await ProductService.fetchProducts(page: 1, perPage: 4);
      
      setState(() {
        _uniqueCategories = categories;
        _featuredProducts = featuredResponse['products'];
        _products = categoryResponse['products'];
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
          _buildAppBar(),
          _buildWelcomeSection(),
          _buildSearchBar(),
          _buildCategories(),
          _buildHeroSection(),
          _buildFeaturedProducts(),
          _buildQuickActions(),
          if (_isLoading) _buildLoading() else if (_error != null) _buildError() else _buildAllProducts(),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    final appProvider = Provider.of<AppProvider>(context);
    return SliverAppBar(
      pinned: true,
      backgroundColor: Colors.white,
      expandedHeight: 80,
      flexibleSpace: Container(
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
                const Text(
                  'Premium Supplements',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                    fontWeight: FontWeight.w500
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Badge(
                  isLabelVisible: appProvider.wishlistCount > 0,
                  label: Text('${appProvider.wishlistCount}'),
                  child: IconButton(
                    icon: const Icon(Icons.favorite_border, color: _primary),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WishlistScreen())),
                  ),
                ),
                Badge(
                  isLabelVisible: appProvider.cartCount > 0,
                  label: Text('${appProvider.cartCount}'),
                  child: IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined, color: _primary),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return SliverToBoxAdapter(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome to NutriBlend',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Discover premium supplements for your fitness journey',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return SliverToBoxAdapter(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search supplements...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () {},
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
          ),
          onSubmitted: (value) {
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => ProductsScreen(searchQuery: value),
            ));
          },
        ),
      ),
    );
  }

  Widget _buildCategories() {
    return SliverToBoxAdapter(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Shop by Category',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _uniqueCategories.length,
                itemBuilder: (ctx, i) {
                  final cat = _uniqueCategories[i];
                  final isSelected = cat['id'] == _selectedCategoryId;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: FilterChip(
                      label: Text(cat['name']),
                      onSelected: (bool selected) {
                        setState(() {
                          _selectedCategoryId = selected ? cat['id'] : null;
                        });
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => ProductsScreen(categoryId: selected ? cat['id'] : null),
                        ));
                      },
                      selected: isSelected,
                      selectedColor: _primary,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
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

  Widget _buildHeroSection() {
    return SliverToBoxAdapter(
      child: Container(
        width: double.infinity,
        height: 200,
        margin: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_primary, Color(0xFF004D40)],
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 20,
              offset: Offset(0, 10),
            )
          ],
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'NEW ARRIVALS',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Premium Supplements\nFor Peak Performance',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedProducts() {
    return SliverToBoxAdapter(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Featured Products',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductsScreen())),
                  child: const Text('View All', style: TextStyle(color: _primary)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _featuredProducts.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  return _ProductCard(
                    product: _featuredProducts[index],
                    isFeatured: true,
                    onAddToCart: () {
                      Provider.of<AppProvider>(context, listen: false).addToCart(_featuredProducts[index]);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Added to Cart!'), backgroundColor: _primary),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return SliverToBoxAdapter(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildActionCard(Icons.local_florist, 'All Products', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductsScreen()))),
            _buildActionCard(Icons.favorite, 'Wishlist', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WishlistScreen()))),
            _buildActionCard(Icons.shopping_cart, 'Cart', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen()))),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(IconData icon, String title, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: _primary, size: 32),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
  }

  Widget _buildError() {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Error loading products'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllProducts() {
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
          (context, i) => _ProductCard(
            product: _products[i],
            onAddToCart: () {
              Provider.of<AppProvider>(context, listen: false).addToCart(_products[i]);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Added to Cart!'), backgroundColor: _primary),
              );
            },
          ),
          childCount: _products.length,
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Map product;
  final VoidCallback onAddToCart;
  final bool isFeatured;

  const _ProductCard({
    required this.product,
    required this.onAddToCart,
    this.isFeatured = false,
  });

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final String image = product['main_image'] ?? '';
    final String name = product['name']?.toString().trim() ?? 'Product';
    final String price = product['formatted_price'] ?? '';
    final bool inStock = product['in_stock'] ?? true;
    final int id = product['id'] ?? 0;
    final bool isFavorite = appProvider.isFavorite(id);

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => ProductDetailScreen(product: product),
      )),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: Container(
                      width: double.infinity,
                      color: Colors.grey[200],
                      child: image.isNotEmpty
                          ? Image.network(image, fit: BoxFit.cover)
                          : const Icon(Icons.image_not_supported),
                    ),
                  ),
                  // Wishlist button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () {
                        appProvider.toggleWishlist(product);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        child: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.red : Colors.grey,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Product info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    price,
                    style: const TextStyle(
                      color: Color(0xFF2E7D32),
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Add to cart button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: inStock ? onAddToCart : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        inStock ? 'Add to Cart' : 'Out of Stock',
                        style: const TextStyle(fontSize: 12),
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
}