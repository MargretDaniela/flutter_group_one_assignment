// ============================================================
// FILE: lib/services/product_service.dart
// ============================================================

import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;

class ProductService {
  static Future<void> fetchProductsSafely() async {
    try {
      final response = await http
          .get(Uri.parse(
            'https://admin.rasmuspharmaceuticals.com/api/v1/products',
          ))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);

        // Print total count from meta.total
        final int totalProducts = json['meta']['total'];
        print('Total products: $totalProducts');

        // Print each product name and formatted_price
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
}