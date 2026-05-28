// ============================================================
// FILE: lib/screens/home_screen.dart
// ============================================================

import 'package:flutter/material.dart';
import '../services/product_service.dart'; // import our service

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = false;
  String _message = 'Press the button to fetch products.';

  // This is called when the button is tapped
  Future<void> _onButtonPressed() async {
    setState(() {
      _isLoading = true;
      _message = 'Fetching products...';
    });

    try {
      // Call the static method directly — no object needed
      // because we used 'static' in the service
      await ProductService.fetchProductsSafely();

      setState(() {
        _isLoading = false;
        _message = '✅ Done! Check your Debug Console for the product list.';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _message = '❌ Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NutriBlend Products'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.local_drink, size: 80, color: Colors.green.shade600),
            const SizedBox(height: 24),
            Text(
              _message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 32),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              ElevatedButton.icon(
                onPressed: _onButtonPressed,
                icon: const Icon(Icons.download),
                label: const Text('Fetch Products', style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}