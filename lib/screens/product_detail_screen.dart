import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

const _primary = Color(0xFF2E7D32);

class ProductDetailScreen extends StatelessWidget {
  final Map product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final String image = product['main_image'] ?? '';
    final String name = product['name'] ?? 'No Name';
    final String price = product['formatted_price'] ?? '';
    final String desc = product['short_description'] ?? 'No description available.';
    final String cat = product['category']?['name'] ?? 'General';
    final bool inStock = product['in_stock'] ?? true;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _primary,
        title: const Text('Product Details', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              height: 300,
              child: CachedNetworkImage(
                imageUrl: image,
                fit: BoxFit.cover,
                placeholder: (_, __) => const Center(child: CircularProgressIndicator()),
                errorWidget: (_, __, ___) => Container(color: Colors.grey[200], child: const Icon(Icons.image_not_supported, size: 50)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: _primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                    child: Text(cat.toUpperCase(), style: const TextStyle(color: _primary, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  const SizedBox(height: 16),
                  Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 10),
                  Text(price, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: _primary)),
                  const SizedBox(height: 20),
                  const Divider(thickness: 1, color: Colors.grey),
                  const SizedBox(height: 20),
                  const Text('Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(desc, style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black54)),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Icon(Icons.inventory_2, color: inStock ? _primary : Colors.red),
                      const SizedBox(width: 8),
                      Text(
                        inStock ? 'In Stock' : 'Out of Stock',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: inStock ? _primary : Colors.red),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Added to Cart successfully!', style: TextStyle(color: Colors.white)), 
                            backgroundColor: _primary,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary, 
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        'ADD TO CART', 
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}