// ============================================================
// FILE: lib/utils/console_printer.dart
// ============================================================
// This utility class handles ALL the printing to the console.
// Separating print logic keeps our main.dart clean and makes
// it easy to change how we display things in one place.
// ============================================================

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
    print('');
    print('╔══════════════════════════════════════════╗');
    print('║         NUTRIBLEND PRODUCTS API          ║');
    print('╚══════════════════════════════════════════╝');
    print('');

    // ---------------------------------------------------------------
    // Print the total count from meta.total
    // This answers: "how many products exist in the database?"
    // ---------------------------------------------------------------
    print('📦 Total products available: ${response.total}');
    print('─' * 44); // prints a divider line

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

      print('$index. ${product.name}');
      print('   💰 Price: ${product.formattedPrice}');
      print('');
    }

    print('─' * 44);
    print('✅ Done! Printed ${response.data.length} products.');
    print('');
  }

  // ---------------------------------------------------------------
  // printError()
  // ---------------------------------------------------------------
  // Called when something goes wrong — prints a clear error message
  // ---------------------------------------------------------------
  static void printError(Object error) {
    print('');
    print('❌ ERROR: Something went wrong!');
    print('   Details: $error');
    print('');
    print('   Possible reasons:');
    print('   • No internet connection');
    print('   • The API server is down');
    print('   • Wrong URL');
    print('');
  }
}