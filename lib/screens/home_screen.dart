// lib/screens/home_screen.dart

// ignore_for_file: curly_braces_in_flow_control_structures, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/product_service.dart';

const _green = Color(0xFF2E7D32);
const _greenLight = Color(0xFFE8F5E9);
const _bg = Color(0xFFF7F9F4);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;
  List _products = [];
  int _currentPage = 1;
  int _lastPage = 1;
  int _total = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; _products = []; _currentPage = 1; });
    try {
      final r = await ProductService.fetchProducts(page: 1);
      setState(() { _products = r['products']; _lastPage = r['lastPage']; _total = r['total']; _isLoading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _loadMore() async {
    if (_currentPage >= _lastPage || _isLoadingMore) return;
    setState(() => _isLoadingMore = true);
    try {
      final r = await ProductService.fetchProducts(page: _currentPage + 1);
      setState(() { _products.addAll(r['products']); _currentPage++; _isLoadingMore = false; });
    } catch (e) {
      setState(() => _isLoadingMore = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red.shade700));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _green))
          : _error != null
              ? _ErrorView(message: _error!, onRetry: _load)
              : _buildList(),
    );
  }

  Widget _buildList() {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ── Hero Header ──────────────────────────────────
        SliverAppBar(
          expandedHeight: 160,
          pinned: true,
          backgroundColor: _green,
          flexibleSpace: FlexibleSpaceBar(
            collapseMode: CollapseMode.parallax,
            background: Container(
              color: _green,
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('PREMIUM SUPPLEMENTS',
                      style: TextStyle(color: Colors.white60, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w700)),
                  SizedBox(height: 4),
                  Text('Fuel Your\nPerformance.',
                      style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, height: 1.1)),
                ],
              ),
            ),
          ),
          title: const Text('NUTRIBLEND',
              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 3)),
          actions: [
            IconButton(icon: const Icon(Icons.refresh, color: Colors.white70), onPressed: _load),
          ],
        ),

        // ── Stats Row ─────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _StatCard(label: 'Total', value: '$_total'),
                const SizedBox(width: 8),
                _StatCard(label: 'Loaded', value: '${_products.length}'),
                const SizedBox(width: 8),
                _StatCard(label: 'Page', value: '$_currentPage / $_lastPage'),
              ],
            ),
          ),
        ),

        // ── Product List ──────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => _ProductCard(product: _products[i]),
              childCount: _products.length,
            ),
          ),
        ),

        // ── Load More ─────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: _currentPage >= _lastPage
                ? Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _greenLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.done_all_rounded, color: _green, size: 18),
                        SizedBox(width: 8),
                        Text('All products loaded!',
                            style: TextStyle(color: _green, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  )
                : ElevatedButton(
                    onPressed: _isLoadingMore ? null : _loadMore,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _green,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoadingMore
                        ? const SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text('Load More · Page $_currentPage of $_lastPage',
                            style: const TextStyle(fontWeight: FontWeight.w800)),
                  ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
      ],
    );
  }
}

// ── Stat Card ────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label, value;
  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _greenLight),
      ),
      child: Column(children: [
        Text(value, style: const TextStyle(color: _green, fontSize: 14, fontWeight: FontWeight.w800)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
      ]),
    ),
  );
}

// ── Product Card ─────────────────────────────────────────────
class _ProductCard extends StatelessWidget {
  final Map product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final String image   = product['main_image'] ?? '';
    final String name    = (product['name'] ?? '').toString().trim();
    final String price   = product['formatted_price'] ?? '';
    final String desc    = product['short_description'] ?? '';
    final String cat     = product['category']?['name'] ?? '';
    final bool inStock   = product['in_stock'] ?? false;
    final bool onSale    = product['on_sale'] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEF2EE)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
            child: Stack(children: [
              image.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: image, width: 100, height: 105, fit: BoxFit.cover,
                      placeholder: (_, __) => Container(width: 100, height: 105,
                          color: _greenLight, child: const Center(child: CircularProgressIndicator(color: _green, strokeWidth: 1.5))),
                      errorWidget: (_, __, ___) => Container(width: 100, height: 105,
                          color: _greenLight, child: const Icon(Icons.image_not_supported, color: Colors.green, size: 28)),
                    )
                  : Container(width: 100, height: 105, color: _greenLight,
                      child: const Icon(Icons.image_not_supported, color: Colors.green, size: 28)),
              if (onSale)
                Positioned(top: 7, left: 7,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.orange.shade700, borderRadius: BorderRadius.circular(4)),
                    child: const Text('SALE', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.8)),
                  )),
            ]),
          ),

          // Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (cat.isNotEmpty)
                  Text(cat.toUpperCase(), style: const TextStyle(color: _green, fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                const SizedBox(height: 4),
                Text(name, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A), height: 1.3)),
                if (desc.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(desc, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10, color: Colors.grey)),
                ],
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(price, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: _green)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: inStock ? _greenLight : const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(inStock ? 'In Stock' : 'Out of Stock',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                            color: inStock ? _green : Colors.red.shade700)),
                  ),
                ]),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Error View ───────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.wifi_off_rounded, color: Colors.red.shade300, size: 52),
        const SizedBox(height: 16),
        const Text('Connection Failed', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
          style: ElevatedButton.styleFrom(backgroundColor: _green, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        ),
      ]),
    ),
  );
}