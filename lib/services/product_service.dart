import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// ignore_for_file: avoid_print

class ProductService {
  static const String _baseUrl =
      'https://admin.rasmuspharmaceuticals.com/api/v1/products';

  // EXERCISE 1: Console Printer
  static Future<void> fetchProductsSafely() async {
    try {
      const String targetUrl = 'https://admin.rasmuspharmaceuticals.com/api/v1/products';
      const String proxyUrl = kIsWeb ? 'https://corsproxy.io/?$targetUrl' : targetUrl;

      final response = await http.get(Uri.parse(proxyUrl)).timeout(const Duration(seconds: 30));

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

  // EXERCISE 2 & 3: Fetch for UI
  static Future<Map<String, dynamic>> fetchProducts({
    int page = 1,
    int? perPage,
    String? search,
    int? categoryId,
  }) async {
    String targetUrl = '$_baseUrl?page=$page';
    if (perPage != null) targetUrl += '&per_page=$perPage';
    if (search != null && search.isNotEmpty) targetUrl += '&search=$search';
    if (categoryId != null) targetUrl += '&category_id=$categoryId';
    
    final String proxyUrl = kIsWeb ? 'https://corsproxy.io/?$targetUrl' : targetUrl;

    // ADDED "BETTER HEADER": User-Agent prevents HTTP 530 (Freeze) errors
    final response = await http.get(
      Uri.parse(proxyUrl),
      headers: const {'User-Agent': 'NutriBlendApp/1.0 (Flutter)'},
    ).timeout(const Duration(seconds: 30));

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