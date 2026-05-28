// EXERCISE 3 UPDATE: fetchProducts() now also returns
// last_page from meta so the UI knows when to stop paginating


// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;

class ProductService {
  static const String _baseUrl =
      'https://admin.rasmuspharmaceuticals.com/api/v1/products';

  
  // EXERCISE 1 — kept as-is (prints to console)
  
  static Future<void> fetchProductsSafely() async {
    try {
      final response = await http
          .get(Uri.parse(_baseUrl))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        final int totalProducts = json['meta']['total'];
        print('Total products: $totalProducts');

        final List products = json['data'];
        for (var product in products) {
          print('${product['name']} - ${product['formatted_price']}');
        }
      } else {
        throw HttpException('Server error: ${response.statusCode}');
      }
    } on SocketException {
      print('No internet connection');
    } on TimeoutException {
      print('Request timed out — try again');
    }
  }

  
  // EXERCISE 2 & 3 — returns data so the UI can display it
  
  // Returns a Map with:
  //   'products'  → List of products for this page
  //   'total'     → int, total product count
  //   'lastPage'  → int, the final page number (from meta.last_page)
  
  static Future<Map<String, dynamic>> fetchProducts({int page = 1}) async {
    final response = await http
        .get(Uri.parse('$_baseUrl?page=$page'))
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final Map<String, dynamic> body = jsonDecode(response.body);

      return {
        'products': body['data'] as List,
        'total': body['meta']['total'] as int,
        'lastPage': body['meta']['last_page'] as int, // ← NEW for Exercise 3
      };
    } else {
      throw HttpException('Server error: ${response.statusCode}');
    }
  }
}