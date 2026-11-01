import 'package:dummyjson_flutter_test/features/products/domain/entities/product.dart';

class ProductModel extends Product {
  const ProductModel({
    required super.id,
    required super.title,
    required super.description,
    required super.category,
    required super.price,
    required super.discountPercentage,
    required super.rating,
    required super.stock,
    required super.brand,
    required super.thumbnail,
    required super.images,
    required super.availabilityStatus,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (id is! num) {
      throw const FormatException('Product is missing an id.');
    }
    final rawImages = json['images'];
    final images = <String>[
      if (rawImages is List)
        for (final image in rawImages)
          if (image != null) image.toString(),
    ];
    return ProductModel(
      id: id.toInt(),
      title: json['title'] as String? ?? 'Untitled',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      discountPercentage: (json['discountPercentage'] as num?)?.toDouble() ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      brand: json['brand'] as String?,
      thumbnail: json['thumbnail'] as String? ?? '',
      images: images,
      availabilityStatus: json['availabilityStatus'] as String? ?? 'Unknown',
    );
  }
}

class ProductPageModel extends ProductPage {
  const ProductPageModel({
    required super.products,
    required super.total,
    required super.skip,
    required super.limit,
  });

  factory ProductPageModel.fromJson(Map<String, dynamic> json) {
    final rawProducts = json['products'];
    final products = <Product>[
      if (rawProducts is List)
        for (final item in rawProducts)
          if (item is Map)
            ProductModel.fromJson(Map<String, dynamic>.from(item)),
    ];
    return ProductPageModel(
      products: products,
      total: (json['total'] as num?)?.toInt() ?? products.length,
      skip: (json['skip'] as num?)?.toInt() ?? 0,
      limit: (json['limit'] as num?)?.toInt() ?? products.length,
    );
  }
}
