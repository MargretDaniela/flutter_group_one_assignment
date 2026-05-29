// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/product_service.dart';
import 'product_detail_screen.dart';

const _primary = Color(0xFF2E7D32);
const _bg = Color(0xFFF5F5F0);
const _textDark = Color(0xFF1B5E20);
const _textLight = Color(0xFF9E9E9E);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = false;
  String? _error;
  List _products = [];
  int _currentPage = 1, _lastPage = 1;
  String _search = '';
  int? _selectedCategoryId;
  // Categories loaded independently so all are shown regardless of current filter
  List _categories = [{'id': null, 'name': 'All'}];
  bool _catsLoaded = false;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadPage(1);
  }

  // Load ALL categories from a large unfiltered fetch — done once
  Future<void> _loadCategories() async {
    if (_catsLoaded) return;
    try {
      final res = await ProductService.fetchProducts(perPage: 100);
      final all = res['products'] as List;
      final seen = <int>{};
      final cats = <Map>[{'id': null, 'name': 'All'}];
      for (final p in all) {
        final cat = p['category'];
        if (cat != null && seen.add(cat['id'] as int)) cats.add(Map.from(cat));
      }
      cats.sort((a, b) => a['name'] == 'All'
          ? -1
          : (a['name'] as String).compareTo(b['name'] as String));
      if (mounted) setState(() { _categories = cats; _catsLoaded = true; });
    } catch (_) {}
  }

  Future<void> _loadPage(int page) async {
    if (_isLoading) return;
    setState(() { _isLoading = true; _error = null; });
    try {
      final res = await ProductService.fetchProducts(
        page: page, perPage: 12, search: _search, categoryId: _selectedCategoryId,
      );
      final raw = (res['products'] as List).where((p) {
        final img = (p['main_image'] ?? '').toLowerCase();
        return img.isNotEmpty && !img.contains('logo') && !img.contains('placeholder');
      }).toList();
      setState(() {
        _products = raw;
        _currentPage = page;
        _lastPage = res['lastPage'] ?? 1;
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  void _doSearch(String v) { _search = v; _loadPage(1); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        slivers: [
          _appBar(),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _hero(),
                const SizedBox(height: 14),
                _searchBar(),
                const SizedBox(height: 6),
                _categoryRow(),
                const SizedBox(height: 4),
                if (_products.isNotEmpty) ...[
                  _sectionHeader('Featured'),
                  const SizedBox(height: 4),
                  _featuredScroll(),
                  const SizedBox(height: 8),
                ],
                _sectionHeader('All Products', trailing: Text(
                  _lastPage > 1 ? 'Page $_currentPage of $_lastPage' : '',
                  style: TextStyle(color: _textLight, fontSize: 12),
                )),
                const SizedBox(height: 4),
              ],
            ),
          ),
          if (_isLoading && _products.isEmpty)
            const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: _primary)))
          else if (_error != null)
            SliverFillRemaining(
                child: _ErrorView(message: _error!, onRetry: () => _loadPage(_currentPage)))
          else if (_products.isEmpty)
            const SliverFillRemaining(
                child: Center(child: Text('No products found',
                    style: TextStyle(color: _textLight, fontSize: 15))))
          else ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.68,
                ),
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _ProductCard(product: _products[i]),
                  childCount: _products.length,
                ),
              ),
            ),
            SliverToBoxAdapter(child: _pagination()),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  // ── App bar ───────────────────────────────────────────────────────────────
  Widget _appBar() => SliverAppBar(
    pinned: true,
    backgroundColor: Colors.white,
    elevation: 0,
    titleSpacing: 16,
    title: Row(children: [
      Container(
        width: 32, height: 32,
        decoration: BoxDecoration(color: _primary, borderRadius: BorderRadius.circular(10)),
        child: const Icon(Icons.local_florist, color: Colors.white, size: 18),
      ),
      const SizedBox(width: 10),
      Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        const Text('NutriBlend',
            style: TextStyle(color: _textDark, fontSize: 16, fontWeight: FontWeight.w900)),
        Text('Premium Supplements',
            style: TextStyle(color: _textLight, fontSize: 10)),
      ]),
    ]),
    actions: [
      IconButton(
        icon: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: const Color(0xFFF1F8E9), borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.refresh_rounded, color: _primary, size: 20),
        ),
        onPressed: () { _loadCategories(); _loadPage(1); },
      ),
      const SizedBox(width: 6),
    ],
    bottom: PreferredSize(
      preferredSize: const Size.fromHeight(0.5),
      child: Container(height: 0.5, color: Colors.grey.shade200),
    ),
  );

  // ── Hero — background image with green overlay ────────────────────────────
  Widget _hero() => Container(
    margin: const EdgeInsets.fromLTRB(14, 14, 14, 0),
    height: 290,
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(22),
        color: _primary), // fallback colour
    clipBehavior: Clip.hardEdge,
    child: Stack(children: [
      // Background image
      Positioned.fill(
        child: CachedNetworkImage(
          imageUrl: 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=800&q=80',
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => Container(color: _primary),
        ),
      ),
      // Green gradient overlay (matches the screenshot)
      Positioned.fill(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1B5E20).withValues(alpha: 0.82),
                const Color(0xFF2E7D32).withValues(alpha: 0.70),
              ],
            ),
          ),
        ),
      ),
      // Content
      Padding(
        padding: const EdgeInsets.fromLTRB(26, 32, 26, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Badge pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: Text('NEW ARRIVALS',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.95),
                      fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.8)),
            ),
            // Headline
            const Text('Premium Supplements\nFor Peak Performance',
                style: TextStyle(
                    color: Colors.white, fontSize: 28,
                    fontWeight: FontWeight.w900, height: 1.2)),
            // CTA row
            Row(children: [
              GestureDetector(
                onTap: () { setState(() { _selectedCategoryId = null; }); _loadPage(1); },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
                  decoration: BoxDecoration(
                      color: Colors.white, borderRadius: BorderRadius.circular(30)),
                  child: const Text('Shop Now',
                      style: TextStyle(color: _primary, fontWeight: FontWeight.w800, fontSize: 14)),
                ),
              ),
            ]),
          ],
        ),
      ),
    ]),
  );

  // ── Search bar ────────────────────────────────────────────────────────────
  Widget _searchBar() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14),
    child: Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: [
        Icon(Icons.search_rounded, color: _textLight, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            onSubmitted: _doSearch,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
            decoration: InputDecoration(
              hintText: 'Search supplements...',
              hintStyle: TextStyle(color: _textLight, fontSize: 14),
              border: InputBorder.none, isDense: true,
            ),
          ),
        ),
        if (_search.isNotEmpty)
          GestureDetector(
            onTap: () { _searchController.clear(); _doSearch(''); },
            child: Icon(Icons.close_rounded, color: _textLight, size: 18),
          ),
      ]),
    ),
  );

  // ── Category chips — scrollable, shows ALL categories ────────────────────
  Widget _categoryRow() => SizedBox(
    height: 46,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      itemCount: _categories.length,
      itemBuilder: (_, i) {
        final cat = _categories[i];
        final sel = _selectedCategoryId == cat['id'];
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () { setState(() { _selectedCategoryId = cat['id']; }); _loadPage(1); },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: sel ? _primary : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: sel ? _primary : Colors.grey.shade200, width: sel ? 0 : 1),
                boxShadow: sel ? [BoxShadow(color: _primary.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 3))] : [],
              ),
              child: Text(cat['name'],
                  style: TextStyle(
                    color: sel ? Colors.white : Colors.black87,
                    fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 13,
                  )),
            ),
          ),
        );
      },
    ),
  );

  // ── Section header ────────────────────────────────────────────────────────
  Widget _sectionHeader(String title, {Widget? trailing}) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 12, 0),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center, children: [
      Text(title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.black87)),
      if (trailing != null) trailing,
    ]),
  );

  // ── Featured horizontal scroll ────────────────────────────────────────────
  Widget _featuredScroll() => SizedBox(
    height: 210,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      itemCount: _products.length > 6 ? 6 : _products.length,
      itemBuilder: (_, i) => _FeaturedCard(product: _products[i]),
    ),
  );

  // ── Pagination ────────────────────────────────────────────────────────────
  Widget _pagination() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 24),
    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      _pageBtn(Icons.chevron_left, _currentPage > 1 ? () => _loadPage(_currentPage - 1) : null),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Text('$_currentPage / $_lastPage',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.black87)),
      ),
      _pageBtn(Icons.chevron_right,
          _currentPage < _lastPage ? () => _loadPage(_currentPage + 1) : null),
    ]),
  );

  Widget _pageBtn(IconData icon, VoidCallback? onTap) {
    final active = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: active ? _primary : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: active ? Colors.white : Colors.grey.shade400, size: 22),
      ),
    );
  }
}

// ── Featured card ─────────────────────────────────────────────────────────────
class _FeaturedCard extends StatelessWidget {
  final Map product;
  const _FeaturedCard({required this.product});

  static const _bgs = [
    Color(0xFFE8F5E9), Color(0xFFFFF3E0),
    Color(0xFFE3F2FD), Color(0xFFF3E5F5), Color(0xFFE0F7FA), Color(0xFFFCE4EC),
  ];

  // Card is exactly 210px tall (matches the SizedBox in _featuredScroll)
  // Image: 120px  |  info: 90px  |  total: 210px
  static const double _cardHeight = 210;
  static const double _imgHeight  = 120;
  static const double _infoHeight = _cardHeight - _imgHeight; // 90

  @override
  Widget build(BuildContext context) {
    final image   = product['main_image'] ?? '';
    final name    = product['name']?.toString().trim() ?? 'Product';
    final price   = product['formatted_price'] ?? '';
    final cat     = (product['category']?['name'] ?? '') as String;
    final bool inStock = product['in_stock'] ?? true;
    final bg      = _bgs[(product['id'] ?? 0) % _bgs.length];

    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product))),
      child: Container(
        width: 148,
        height: _cardHeight,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Image — exact height ──────────────────────────────────────
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              child: SizedBox(
                width: double.infinity,
                height: _imgHeight,
                child: ColoredBox(
                  color: bg,
                  child: image.isNotEmpty
                      ? CachedNetworkImage(imageUrl: image, fit: BoxFit.cover,
                          errorWidget: (_, __, ___) =>
                              Center(child: Icon(Icons.image_not_supported,
                                  color: Colors.grey.shade400, size: 28)))
                      : Center(child: Icon(Icons.image_not_supported,
                          color: Colors.grey.shade400, size: 28)),
                ),
              ),
            ),
            // ── Info — exact height, overflow clipped ─────────────────────
            SizedBox(
              height: _infoHeight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Category + name stacked
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (cat.isNotEmpty)
                          Text(cat,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 10, color: _textLight,
                                  fontWeight: FontWeight.w500)),
                        if (cat.isNotEmpty) const SizedBox(height: 2),
                        Text(name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87, height: 1.25)),
                      ],
                    ),
                    // Price + stock badge
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(price,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: _primary,
                                  fontSize: 13, fontWeight: FontWeight.w900)),
                        ),
                        if (!inStock)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('Out',
                                style: TextStyle(fontSize: 9,
                                    color: Colors.red.shade400,
                                    fontWeight: FontWeight.w700)),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Product grid card ──────────────────────────────────────────────────────────
class _ProductCard extends StatelessWidget {
  final Map product;
  const _ProductCard({required this.product});

  static const _bgs = [
    Color(0xFFF1F8E9), Color(0xFFFFF8E1),
    Color(0xFFF3E5F5), Color(0xFFE0F7FA),
  ];

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final image = product['main_image'] ?? '';
    final name = product['name']?.toString().trim() ?? 'Product';
    final price = product['formatted_price'] ?? '';
    final bool inStock = product['in_stock'] ?? true;
    final int id = product['id'] ?? 0;
    final bool isFav = appProvider.isFavorite(id);
    final bg = _bgs[id % _bgs.length];

    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product))),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image — uses flex to fill available vertical space
            Expanded(
              child: Stack(children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                  child: Container(
                    width: double.infinity, color: bg,
                    child: image.isNotEmpty
                        ? CachedNetworkImage(imageUrl: image, fit: BoxFit.cover,
                            errorWidget: (_, __, ___) =>
                                Center(child: Icon(Icons.image_not_supported,
                                    color: Colors.grey.shade400)))
                        : Center(child: Icon(Icons.image_not_supported,
                            color: Colors.grey.shade400)),
                  ),
                ),
                if (!inStock)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.48),
                        alignment: Alignment.center,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                          ),
                          child: const Text('OUT OF STOCK',
                              style: TextStyle(color: Colors.white,
                                  fontWeight: FontWeight.w800, fontSize: 10, letterSpacing: 0.5)),
                        ),
                      ),
                    ),
                  ),
                // Wishlist button
                Positioned(
                  top: 8, right: 8,
                  child: GestureDetector(
                    onTap: () {
                      appProvider.toggleWishlist(product);
                      ScaffoldMessenger.of(context)
                        ..clearSnackBars()
                        ..showSnackBar(SnackBar(
                          content: Text(isFav ? 'Removed from Wishlist' : 'Added to Wishlist'),
                          backgroundColor: _primary, duration: const Duration(seconds: 1),
                        ));
                    },
                    child: Container(
                      width: 30, height: 30,
                      decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 6)]),
                      child: Icon(isFav ? Icons.favorite : Icons.favorite_border,
                          color: isFav ? Colors.red.shade400 : Colors.grey.shade400, size: 16),
                    ),
                  ),
                ),
              ]),
            ),
            // Fixed-height info section — prevents overflow
            Padding(
              padding: const EdgeInsets.fromLTRB(11, 9, 11, 11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                          color: Colors.black87, height: 1.3)),
                  const SizedBox(height: 3),
                  Text(inStock ? '● In Stock' : '● Out of Stock',
                      style: TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w600,
                          color: inStock ? Colors.green.shade600 : Colors.red.shade400)),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      Expanded(
                        child: Text(price,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: _primary,
                                fontSize: 14, fontWeight: FontWeight.w900)),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: inStock ? () {
                          appProvider.addToCart(product);
                          ScaffoldMessenger.of(context)
                            ..clearSnackBars()
                            ..showSnackBar(const SnackBar(
                                content: Text('Added to cart'),
                                backgroundColor: _primary,
                                duration: Duration(seconds: 1)));
                        } : null,
                        child: Container(
                          width: 30, height: 30,
                          decoration: BoxDecoration(
                            color: inStock ? _primary : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.add, color: Colors.white, size: 18),
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
    );
  }
}

// ── Error view ─────────────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20)),
          child: Icon(Icons.wifi_off_rounded, size: 36, color: Colors.grey.shade400),
        ),
        const SizedBox(height: 16),
        const Text('Connection Error',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 8),
        Text(message, textAlign: TextAlign.center,
            style: TextStyle(color: _textLight, fontSize: 13)),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('Try Again'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _primary, foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ]),
    ),
  );
}