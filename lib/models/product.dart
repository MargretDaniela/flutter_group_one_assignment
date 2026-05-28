// ============================================================
// FILE: lib/models/product.dart
// ============================================================
// A "model" is a Dart class that represents one item of data
// from the API. Here we describe what a single Product looks like.
// ============================================================

class Product {
  // These are the fields (pieces of data) each product has.
  // 'final' means once set, they cannot be changed — good practice!
  final int id;
  final String name;
  final String formattedPrice; // e.g. "UGX 5,000"

  // This is the CONSTRUCTOR — it's called when you create a Product.
  // The 'required' keyword means you MUST pass these values in.
  const Product({
    required this.id,
    required this.name,
    required this.formattedPrice,
  });

  // ---------------------------------------------------------------
  // factory Product.fromJson(...)
  // ---------------------------------------------------------------
  // A "factory constructor" is a special constructor that builds
  // a Product from a Map<String, dynamic> — which is exactly what
  // dart:convert gives us when we parse JSON.
  //
  // Example JSON that comes from the API for one product:
  // {
  //   "id": 1,
  //   "name": "Mango Smoothie",
  //   "formatted_price": "UGX 5,000"
  // }
  //
  // json['name'] reads the "name" key from that map.
  // as String  — tells Dart "trust me, this value is a String"
  // ---------------------------------------------------------------
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      name: json['name'] as String,
      formattedPrice: json['formatted_price'] as String,
    );
  }

  // toString() lets us print a Product nicely using print(product)
  @override
  String toString() {
    return 'Product(id: $id, name: $name, price: $formattedPrice)';
  }
}