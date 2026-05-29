import 'package:flutter/material.dart';

class AppProvider with ChangeNotifier {
  // Cart: Product ID -> CartItem data
  final Map<int, Map<String, dynamic>> _cartItems = {};
  
  // Wishlist: Product IDs or Product Maps
  final Map<int, Map<String, dynamic>> _wishlistItems = {};

  // Navigation State
  int _currentIndex = 0;

  // GETTERS
  int get currentIndex => _currentIndex;
  Map<int, Map<String, dynamic>> get cartItems => _cartItems;
  Map<int, Map<String, dynamic>> get wishlistItems => _wishlistItems;

  int get cartCount => _cartItems.values.fold(0, (sum, item) => sum + (item['quantity'] as int));
  int get wishlistCount => _wishlistItems.length;

  void changeIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  double get cartTotal {
    double total = 0.0;
    _cartItems.forEach((key, item) {
      final product = item['product'];
      final fPrice = product['formatted_price']?.toString() ?? '0';
      final cleanPrice = fPrice.replaceAll(RegExp(r'[^0-9.]'), '');
      double price = double.tryParse(cleanPrice) ?? 0.0;
      total += price * (item['quantity'] as int);
    });
    return total;
  }

  // CART LOGIC
  void addToCart(Map product) {
    int id = product['id'];
    if (_cartItems.containsKey(id)) {
      _cartItems[id]!['quantity'] += 1;
    } else {
      _cartItems[id] = {
        'product': Map<String, dynamic>.from(product),
        'quantity': 1,
      };
    }
    notifyListeners();
  }

  void removeFromCart(int productId) {
    _cartItems.remove(productId);
    notifyListeners();
  }

  void updateCartQuantity(int productId, int quantity) {
    if (quantity <= 0) {
      removeFromCart(productId);
    } else if (_cartItems.containsKey(productId)) {
      _cartItems[productId]!['quantity'] = quantity;
      notifyListeners();
    }
  }

  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }

  // WISHLIST LOGIC
  void toggleWishlist(Map product) {
    int id = product['id'];
    if (_wishlistItems.containsKey(id)) {
      _wishlistItems.remove(id);
    } else {
      _wishlistItems[id] = Map<String, dynamic>.from(product);
    }
    notifyListeners();
  }

  bool isFavorite(int productId) {
    return _wishlistItems.containsKey(productId);
  }
}
