// ============================================================
// FILE: lib/utils/console_printer.dart
// ============================================================
// This utility class handles ALL the printing to the console.
// Separating print logic keeps our main.dart clean and makes
// it easy to change how we display things in one place.
// ============================================================

import 'package:flutter/foundation.dart';
import '../models/products_response.dart';

class ConsolePrinter {
  // ---------------------------------------------------------------
  // printProducts()
  // ---------------------------------------------------------------
  // Takes a ProductsResponse and prints everything neatly.
  // 'static' means you call it directly: ConsolePrinter.printProducts(...)
  // rather than creating an instance first.
  // ---------------------------------------------------------------
  static void printProducts(ProductsResponse response) {
    // Print a header so the console output looks organised
    debugPrint('');
    debugPrint('╔══════════════════════════════════════════╗');
    debugPrint('║         NUTRIBLEND PRODUCTS API          ║');
    debugPrint('╚══════════════════════════════════════════╝');
    debugPrint('');

    // ---------------------------------------------------------------
    // Print the total count from meta.total
    // This answers: "how many products exist in the database?"
    // ---------------------------------------------------------------
    debugPrint('📦 Total products available: ${response.total}');
    debugPrint('─' * 44); // prints a divider line

    // ---------------------------------------------------------------
    // Loop through each product and print its name + formatted_price
    //
    // response.data is a List<Product>
    // .asMap()        → gives us {0: product, 1: product, ...}
    // .entries        → gives us each MapEntry(index, product)
    // for (final entry in ...) → loops through each one
    // entry.key   → the index number (0, 1, 2...)
    // entry.value → the actual Product object
    // ---------------------------------------------------------------
    for (final entry in response.data.asMap().entries) {
      final index = entry.key + 1;        // +1 so we start at 1, not 0
      final product = entry.value;

      debugPrint('$index. ${product.name}');
      debugPrint('   💰 Price: ${product.formattedPrice}');
      debugPrint('');
    }

    debugPrint('─' * 44);
    debugPrint('✅ Done! Printed ${response.data.length} products.');
    debugPrint('');
  }

  // ---------------------------------------------------------------
  // printError()
  // ---------------------------------------------------------------
  // Called when something goes wrong — prints a clear error message
  // ---------------------------------------------------------------
  static void printError(Object error) {
    debugPrint('');
    debugPrint('❌ ERROR: Something went wrong!');
    debugPrint('   Details: $error');
    debugPrint('');
    debugPrint('   Possible reasons:');
    debugPrint('   • No internet connection');
    debugPrint('   • The API server is down');
    debugPrint('   • Wrong URL');
    debugPrint('');
  }
}