import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/product_service.dart';
import 'product_detail_screen.dart';
import 'cart_screen.dart';
import 'wishlist_screen.dart';

const _primary = Color(0xFF2E7D32);   // Deep Forest Green
const _bg = Color(0xFFF1F8E9);        // Pale Green Background
const _textDark = Color(0xFF1B5E20);  // Dark Green Text

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

  Future<void> _loadAllCategories() async {
    try {
      // Fetch 100 items to cover most categories
      final response = await ProductService.fetchProducts(perPage: 100);
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

      // SORT CATEGORIES ALPHABETICALLY (Keep 'All' at the top)
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
        perPage: 10,
        search: _currentSearch,
        categoryId: _selectedCategoryId,
      );
      
      // Filter Logic: Remove placeholder images
      List rawProducts = response['products'];
      List filteredProducts = rawProducts.where((p) {
        String img = (p['main_image'] ?? '').toLowerCase();
        return img.isNotEmpty && !img.contains('logo') && !img.contains('placeholder');
      }).toList();

      setState(() {
        _products = filteredProducts;
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
          _buildHeader(),
          _buildSearchBar(),
          _buildCategoryChips(),
          
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

  Widget _buildHeader() {
    final appProvider = Provider.of<AppProvider>(context);
    return SliverAppBar(
      pinned: true,
      backgroundColor: _primary,
      title: const Text('NutriBlend', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      centerTitle: false,
      actions: [
        IconButton(
          icon: Badge(
            isLabelVisible: appProvider.wishlistCount > 0,
            label: Text('${appProvider.wishlistCount}', style: const TextStyle(color: Colors.white)),
            backgroundColor: Colors.orange.shade700,
            child: const Icon(Icons.favorite_border, color: Colors.white),
          ),
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const WishlistScreen()));
          },
        ),
        IconButton(
          icon: Badge(
            isLabelVisible: appProvider.cartCount > 0,
            label: Text('${appProvider.cartCount}', style: const TextStyle(color: Colors.white)),
            backgroundColor: Colors.orange.shade700,
            child: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
          ),
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen()));
          },
        ),
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          onPressed: () {
            _loadPage(_currentPage);
            _loadAllCategories();
          },
          tooltip: 'Refresh',
        )
      ],
    );
  }

  Widget _buildSearchBar() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(12),
        color: _primary,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25), 
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2))]
          ),
          child: TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            onSubmitted: (value) {
              setState(() { _currentSearch = value; _loadPage(1); });
            },
            decoration: const InputDecoration(
              hintText: 'Search supplements...', 
              border: InputBorder.none,
              prefixIcon: Icon(Icons.search, color: Colors.grey),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SliverToBoxAdapter(
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: _uniqueCategories.length,
          itemBuilder: (ctx, i) {
            final cat = _uniqueCategories[i];
            final isSelected = _selectedCategoryId == cat['id'];
            
            return Padding(
              padding: const EdgeInsets.only(right: 10),
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
                labelStyle: TextStyle(color: isSelected ? Colors.white : _textDark, fontWeight: FontWeight.w600),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProductGrid() {
    return SliverPadding(
      padding: const EdgeInsets.all(8),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.68,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, i) => _ProductCard(product: _products[i]),
          childCount: _products.length,
        ),
      ),
    );
  }

  Widget _buildPaginationControls() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade300),
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

  Widget _buildNavButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    bool isRight = false,
    required bool isActive,
  }) {
    return Material(
      color: isActive ? _primary : Colors.grey[300],
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
}

class _ProductCard extends StatelessWidget {
  final Map product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final String image = product['main_image'] ?? '';
    final String name = product['name']?.toString().trim() ?? 'Product';
    final String price = product['formatted_price'] ?? '';
    final bool inStock = product['in_stock'] ?? true;
    final int id = product['id'] ?? 0;
    final bool isFavorite = appProvider.isFavorite(id);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // IMAGE AREA (Navigates to Details)
          Expanded(
            child: Stack(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ProductDetailScreen(product: product)),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    color: Colors.grey[200],
                    child: CachedNetworkImage(
                      imageUrl: image, 
                      fit: BoxFit.cover, 
                      errorWidget: (_, __, ___) => const Center(child: Icon(Icons.image_not_supported))
                    ),
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
                // WISHLIST BUTTON
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () {
                      appProvider.toggleWishlist(product);
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(!isFavorite ? 'Added to Wishlist' : 'Removed from Wishlist'),
                          backgroundColor: _primary,
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? _primary : Colors.grey,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // INFO & ACTION AREA
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                GestureDetector(
                  onTap: () {
                     Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ProductDetailScreen(product: product)),
                    );
                  },
                  child: Text(
                    name, 
                    maxLines: 2, 
                    overflow: TextOverflow.ellipsis, 
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Bottom Row: Price and Add Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Price
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            price, 
                            style: const TextStyle(
                              color: _primary, 
                              fontSize: 16, 
                              fontWeight: FontWeight.w900
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ADD BUTTON (Fixed Tooltip Structure)
                    Tooltip(
                      message: "Add to Cart",
                      child: Material(
                        color: _primary,
                        borderRadius: BorderRadius.circular(20),
                        child: InkWell(
                          onTap: inStock ? () {
                            appProvider.addToCart(product);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Added to Cart!'),
                                backgroundColor: _primary,
                                duration: Duration(seconds: 1),
                              ),
                            );
                          } : null,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: inStock ? _primary : Colors.grey,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(color: _primary.withValues(alpha: 0.3), blurRadius: 8, spreadRadius: 1)
                              ]
                            ),
                            child: const Icon(
                              Icons.add, 
                              color: Colors.white, 
                              size: 20
                            ),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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