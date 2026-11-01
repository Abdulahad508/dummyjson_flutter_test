import 'package:flutter_test/flutter_test.dart';
import 'package:dummyjson_flutter_test/features/products/data/models/product_model.dart';

void main() {
  const productJson = {
    'id': 1,
    'title': 'Essence Mascara Lash Princess',
    'description': 'A mascara.',
    'category': 'beauty',
    'price': 9.99,
    'discountPercentage': 10.48,
    'rating': 2.56,
    'stock': 99,
    'brand': 'Essence',
    'thumbnail': 'https://cdn.dummyjson.com/thumb.webp',
    'images': ['https://cdn.dummyjson.com/1.webp'],
    'availabilityStatus': 'In Stock',
  };

  test('parses a product and a page', () {
    final page = ProductPageModel.fromJson({
      'products': [productJson],
      'total': 194,
      'skip': 0,
      'limit': 10,
    });

    expect(page.total, 194);
    expect(page.products.single.title, 'Essence Mascara Lash Princess');
    expect(page.products.single.price, 9.99);
    expect(page.products.single.images, ['https://cdn.dummyjson.com/1.webp']);
  });

  test('allows a missing brand and an integer price', () {
    final product = ProductModel.fromJson({
      ...productJson,
      'brand': null,
      'price': 10,
      'images': null,
    });

    expect(product.brand, isNull);
    expect(product.price, 10);
    expect(product.gallery, ['https://cdn.dummyjson.com/thumb.webp']);
  });
}
