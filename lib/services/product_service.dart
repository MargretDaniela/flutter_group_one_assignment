import 'dart:async'; // Required for TimeoutException
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
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
      const String targetUrl = 'https://admin.rasmuspharmaceuticals.com/api/v1/products';
      // Use a CORS proxy if running on the Web
      final String proxyUrl = kIsWeb ? 'https://corsproxy.io/?$targetUrl' : targetUrl;

      final response = await http
          .get(Uri.parse(proxyUrl))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        final int totalProducts = json['meta']['total'];
        debugPrint('Total products: $totalProducts');

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

  // ---------------------------------------------------------------
  // EXERCISE 2 & 3: Fetch for UI
  // ---------------------------------------------------------------
  // Returns a Map with 'products', 'total', and 'lastPage'.
  // Supports search, category filtering, and custom page size.
  
  // EXERCISE 2 & 3 — returns data so the UI can display it
  
  // Returns a Map with:
  //   'products'  → List of products for this page
  //   'total'     → int, total product count
  //   'lastPage'  → int, the final page number (from meta.last_page)
  
  static Future<Map<String, dynamic>> fetchProducts({int page = 1}) async {
    final String targetUrl = '$_baseUrl?page=$page';
    final String proxyUrl = kIsWeb ? 'https://corsproxy.io/?$targetUrl' : targetUrl;

    final response = await http
        .get(Uri.parse(proxyUrl))
        .timeout(const Duration(seconds: 30));

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