import 'dart:async'; // Required for TimeoutException
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

// ignore_for_file: avoid_print
// We use ignore_for_file because Week 5 Exercise 1 specifically asks 
// us to print to the console.

class ProductService {
  static const String _baseUrl =
      'https://admin.rasmuspharmaceuticals.com/api/v1/products';

  // ---------------------------------------------------------------
  // EXERCISE 1: Console Printer
  // ---------------------------------------------------------------
  // Fetches data and prints the result to the debug console.
  static Future<void> fetchProductsSafely() async {
    try {
      final response = await http
          .get(Uri.parse(_baseUrl))
          .timeout(const Duration(seconds: 10));

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

  // ---------------------------------------------------------------
  // EXERCISE 2 & 3: Fetch for UI
  // ---------------------------------------------------------------
  // Returns a Map with 'products', 'total', and 'lastPage'.
  // Supports search, category filtering, and custom page size.
  
  static Future<Map<String, dynamic>> fetchProducts({
    int page = 1,
    int perPage = 10, // Fetch only 10 items at a time
    String search = "",
    int? categoryId, // Filter by category ID if provided
  }) async {
    
    // Build the URL with query parameters using Uri.replace
    // This safely handles '?' and '&' symbols automatically.
    final uri = Uri.parse(_baseUrl).replace(
      queryParameters: {
        'page': page.toString(),
        'per_page': perPage.toString(),
        if (search.isNotEmpty) 'search': search,
        if (categoryId != null) 'category_id': categoryId.toString(),
      },
    );

    final response = await http.get(uri).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final Map<String, dynamic> body = jsonDecode(response.body);

      return {
        'products': body['data'] as List,
        'total': body['meta']['total'] as int,
        'lastPage': body['meta']['last_page'] as int,
      };
    } else {
      throw HttpException('Server error: ${response.statusCode}');
    }
  }
}