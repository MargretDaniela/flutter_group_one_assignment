// ============================================================
// FILE: lib/services/product_service.dart
// ============================================================

import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ProductService {
  static Future<void> fetchProductsSafely() async {
    try {
      final String targetUrl = 'https://admin.rasmuspharmaceuticals.com/api/v1/products';
      // Use a CORS proxy if running on the Web
      final String proxyUrl = kIsWeb ? 'https://corsproxy.io/?$targetUrl' : targetUrl;

      final response = await http
          .get(Uri.parse(proxyUrl))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);

        // Print total count from meta.total
        final int totalProducts = json['meta']['total'];
        debugPrint('Total products: $totalProducts');

        // Print each product name and formatted_price
        final List products = json['data'];
        for (var product in products) {
          debugPrint('${product['name']} - ${product['formatted_price']}');
        }
      } else {
        throw HttpException('Server error: ${response.statusCode}');
      }
    } on SocketException {
      debugPrint('No internet connection');
    } on TimeoutException {
      debugPrint('Request timed out — try again');
    }
  }
}