// ============================================================
// FILE: lib/models/products_response.dart
// ============================================================
// The API returns more than just a list of products — it also
// returns "meta" data (like total count) and wraps everything
// in a structure. This model captures that full response shape.
//
// The JSON from the API looks like this:
// {
//   "meta": {
//     "total": 12,
//     "page": 1
//   },
//   "data": [
//     { "id": 1, "name": "Mango Smoothie", "formatted_price": "UGX 5,000" },
//     { "id": 2, "name": "Berry Blast",    "formatted_price": "UGX 6,500" },
//     ...
//   ]
// }
// ============================================================

import 'product.dart'; // We need the Product model we defined earlier

class ProductsResponse {
  final int total;          // comes from meta.total
  final List<Product> data; // comes from the "data" array

  const ProductsResponse({
    required this.total,
    required this.data,
  });

  // ---------------------------------------------------------------
  // factory ProductsResponse.fromJson(...)
  // ---------------------------------------------------------------
  // Step-by-step breakdown of what happens here:
  //
  // 1. json['meta']       → grabs the "meta" object from the response
  // 2. ['total']          → grabs the "total" number inside meta
  // 3. json['data']       → grabs the "data" array
  // 4. as List            → tells Dart it's a List
  // 5. .map(...)          → loops over each item in the list
  // 6. Product.fromJson() → turns each raw map into a Product object
  // 7. .toList()          → converts the result back to a List
  // ---------------------------------------------------------------
  factory ProductsResponse.fromJson(Map<String, dynamic> json) {
    // Step 1 & 2: Navigate into "meta" and get "total"
    final meta = json['meta'] as Map<String, dynamic>;
    final total = meta['total'] as int;

    // Step 3-7: Turn the raw JSON array into a List<Product>
    final rawList = json['data'] as List;
    final products = rawList
        .map((item) => Product.fromJson(item as Map<String, dynamic>))
        .toList();

    return ProductsResponse(total: total, data: products);
  }
}