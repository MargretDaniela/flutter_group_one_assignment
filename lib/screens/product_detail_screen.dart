// lib/screens/product_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

const _primary = Color(0xFF2E7D32);

class ProductDetailScreen extends StatelessWidget {
  final Map product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final String image = product['main_image'] ?? '';
    final String name = product['name'] ?? 'No Name';
    final String price = product['formatted_price'] ?? '';
    final String desc = product['short_description'] ?? 'No description available.';
    final String cat = product['category']?['name'] ?? 'General';
    final bool inStock = product['in_stock'] ?? true;
    final int id = product['id'] ?? 0;
    final bool isFavorite = appProvider.isFavorite(id);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _primary,
        title: const Text('Product Details', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border, color: isFavorite ? Colors.orange : Colors.white),
            onPressed: () {
              appProvider.toggleWishlist(product);
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            SizedBox(
              width: double.infinity,
              height: 300,
              child: image.isNotEmpty
                  ? Image.network(image, fit: BoxFit.cover)
                  : const Icon(Icons.image_not_supported, size: 100),
            ),
            
            // Product details
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: _primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(cat.toUpperCase(), style: const TextStyle(color: _primary, fontWeight: FontWeight.bold)),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Product name
                  Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  
                  const SizedBox(height: 8),
                  
                  // Price
                  Text(price, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: _primary)),
                  
                  const SizedBox(height: 20),
                  
                  // Description
                  const Text('Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(desc, style: const TextStyle(fontSize: 16, height: 1.5)),
                  
                  const SizedBox(height: 20),
                  
                  // Stock status
                  Row(
                    children: [
                      Icon(Icons.inventory_2, color: inStock ? _primary : Colors.red),
                      const SizedBox(width: 8),
                      Text(
                        inStock ? 'In Stock' : 'Out of Stock',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: inStock ? _primary : Colors.red,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Add to cart button
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: inStock ? () {
                        appProvider.addToCart(product);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Added to Cart successfully!'),
                            backgroundColor: _primary,
                          ),
                        );
                      } : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'ADD TO CART',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1),
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